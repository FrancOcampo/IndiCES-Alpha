box::use(
  readxl[read_excel],
  dplyr[tibble, bind_rows, filter, bind_cols, case_when],
  purrr[map],
  utils[download.file],
  rvest[read_html, html_element, html_text2],
  xml2[xml_contents],
  jsonlite[fromJSON],
)

# CONFIGURACION ####

BASE_URL    <- "https://ces-bcsf.github.io/CicSFE_GitHub/indicadores"
GITHUB_API  <- "https://api.github.com/repos/ces-bcsf/CicSFE_GitHub/contents/indicadores"
OUTPUT_DIR  <- "data/processed"


# FUNCIONES ####

#' Obtiene los codigos de todos los indicadores disponibles desde la API de GitHub.
#' Filtra los archivos `_out.xlsx` y excluye los prefijados con `HP_` (no son series).
#' Retorna un vector de strings con los codigos (ej: "ARG-IL5", "SFE-RMP")
fetch_codigos <- function() {
  archivos <- fromJSON(GITHUB_API)
  nombres  <- archivos$name
  xlsx     <- nombres[grepl("_out\\.xlsx$", nombres) & !grepl("^HP", nombres)]
  sub("_out\\.xlsx$", "", xlsx)
}

#' Construye la URL del Excel para el indicador dado
build_excel_url <- function(codigo) {
  paste0(BASE_URL, "/", codigo, "_out.xlsx")
}

#' Construye la URL del HTML de vistas para el indicador dado
build_html_url <- function(codigo) {
  paste0(BASE_URL, "/", codigo, "_views.html")
}

#' Descarga el Excel desde `url` a un archivo temporal y retorna su path.
#' El llamador es responsable de limpiar el temp con `on.exit(unlink(temp))`.
download_excel <- function(url) {
  temp <- tempfile(fileext = ".xlsx")
  download.file(url, temp, mode = "wb", quiet = TRUE)
  temp
}

#' Extrae los metadatos del indicador desde la hoja `Portada` del Excel.
#' Lee la columna 3, filas 2/3/4/5/6 (nombre, unidad_medida, fuente, clasificacion, id).
#' Retorna un tibble de 1 fila: id, nombre, unidad_medida, fuente, clasificacion_sectorial
extract_metadata <- function(path) {
  portada <- read_excel(path, sheet = "Portada", col_names = FALSE)

  tibble(
    id                      = as.character(portada[[3]][6]),
    nombre                  = as.character(portada[[3]][2]),
    unidad_medida           = as.character(portada[[3]][3]),
    fuente                  = as.character(portada[[3]][4]),
    clasificacion_sectorial = as.character(portada[[3]][5]),
  )
}

#' Descarga y parsea el HTML de vistas del indicador.
#' Llamar una sola vez por indicador y pasar el objeto resultante a las funciones `extract_*`.
fetch_html <- function(codigo) {
  read_html(build_html_url(codigo))
}

#' Extrae el texto del div.info-box que sigue al h2 "Resumen de coyuntura"
#' Recibe el objeto html ya parseado. Retorna un string o NA si no se encuentra.
extract_resumen <- function(html) {
  nodo <- html_element(
    html,
    xpath = "//h2[normalize-space(.)='Resumen de coyuntura']/following-sibling::div[contains(@class,'info-box')][1]"
  )

  paste(as.character(xml_contents(nodo)), collapse = "")
}

#' Extrae la descripción del indicador desde el HTML ya parseado
#' Busca el <h3> cuyo <b> dice "Descripción" y retorna el texto después del |
extract_descripcion <- function(html) {
  nodo  <- html_element(html, xpath = "//h3[b[normalize-space(.)='Descripción']]")
  texto <- html_text2(nodo)
  trimws(sub("^[^|]+\\|", "", texto))
}

#' Extrae el codigo del indicador desde el HTML ya parseado
#' Busca el <h3> cuyo <b> dice "Código" y retorna el texto después del |
extract_codigo_str <- function(html) {
  nodo  <- html_element(html, xpath = "//h3[b[normalize-space(.)='Código']]")
  texto <- html_text2(nodo)
  trimws(sub("^[^|]+\\|", "", texto))
}

#' Extrae la unidad de medida del indicador desde el HTML ya parseado
#' Busca el <h3> cuyo <b> dice "Unidad de medida" y retorna el texto después del |
extract_um_str <- function(html) {
  nodo  <- html_element(html, xpath = "//h3[b[normalize-space(.)='Unidad de medida']]")
  texto <- html_text2(nodo)
  trimws(sub("^[^|]+\\|", "", texto))
}

#' Extrae la fuente primaria del indicador desde el HTML ya parseado
#' Busca el <h3> cuyo <b> dice "Fuente primaria" y retorna el texto después del |
extract_fuente_primaria_str <- function(html) {
  nodo  <- html_element(html, xpath = "//h3[b[normalize-space(.)='Fuente primaria']]")
  texto <- html_text2(nodo)
  trimws(sub("^[^|]+\\|", "", texto))
}

#' Convierte fechas en formato "YYYY.MM" o "YYYYT#" a Date
#' "1994.01" -> 1994-01-01, "2007T1" -> 2007-01-01, "2007T2" -> 2007-04-01
parse_fecha <- function(x) {
  trimestral <- grepl("T", x)
  fecha <- rep(as.Date(NA), length(x))

  if (any(!trimestral)) {
    fecha[!trimestral] <- as.Date(paste0(x[!trimestral], ".01"), format = "%Y.%m.%d")
  }

  if (any(trimestral)) {
    partes <- strsplit(x[trimestral], "T")
    anio   <- sapply(partes, `[`, 1)
    trim   <- as.integer(sapply(partes, `[`, 2))
    mes    <- sprintf("%02d", (trim - 1) * 3 + 1)
    fecha[trimestral] <- as.Date(paste(anio, mes, "01", sep = "-"))
  }

  fecha
}

#' Extrae la serie de datos desde la hoja Data, sin NAs
#' Retorna un tibble con columnas: id_indicador, fecha, valor
extract_serie <- function(path, id_indicador) {
  data <- read_excel(path, sheet = "Data")

  tibble(
    id_indicador = id_indicador,
    fecha        = parse_fecha(data[[1]]),
    valor        = data[[13]], # columna M = g_final
    valor_original = data[[2]] # columna B = g_original
  ) |>
    filter(!is.na(valor), !is.na(fecha))
}

#' Infiere la frecuencia de una serie a partir de la mediana de dias entre fechas
#' Retorna un string: "semanal", "mensual", "trimestral", "semestral" o "anual"
infer_frecuencia <- function(fechas) {
  med <- median(diff(as.numeric(sort(fechas))))

  case_when(
    med <= 10  ~ "semanal",
    med <= 45  ~ "mensual",
    med <= 100 ~ "trimestral",
    med <= 200 ~ "semestral",
    .default   = "anual"
  )
}

#' Procesa un indicador completo (metadata + serie)
#' Retorna una lista con $metadata y $serie
process_indicator <- function(codigo) {
  temp <- download_excel(build_excel_url(codigo))
  on.exit(unlink(temp))

  html     <- fetch_html(codigo)  # descarga el HTML una sola vez
  metadata <- extract_metadata(temp)
  serie    <- extract_serie(temp, metadata$id)

  metadata <- bind_cols(metadata, tibble(
    fecha_ultimo_dato   = serie$fecha[[nrow(serie)]],
    frecuencia          = infer_frecuencia(serie$fecha),
    descripcion_str     = extract_descripcion(html),
    codigo_str          = extract_codigo_str(html),
    um_str              = extract_um_str(html),
    fuente_primaria_str = extract_fuente_primaria_str(html),
    resumen_coyuntura   = extract_resumen(html),
  ))

  list(
    metadata = metadata,
    serie    = serie
  )
}

#' Persiste los dos tibbles a data/processed/ como archivos RDS
#' Crea el directorio si no existe
write_output <- function(series) {
  if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
  saveRDS(series$indicadores, file.path(OUTPUT_DIR, "indicadores.rds"))
  saveRDS(series$datos,       file.path(OUTPUT_DIR, "datos.rds"))
}

#' Procesa todos los indicadores del vector de codigos dado
#' Retorna una lista con $indicadores (tibble) y $datos (tibble)
load_all_indicators <- function(codigos) {
  resultados <- map(codigos, process_indicator)

  list(
    indicadores = bind_rows(map(resultados, "metadata")),
    datos       = bind_rows(map(resultados, "serie"))
  )
}


# EJECUCION ####

codigos <- fetch_codigos()

series <- load_all_indicators(codigos)

write_output(series)
