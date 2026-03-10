box::use(
  readxl[read_excel],
  dplyr[tibble, bind_rows, filter, bind_cols, case_when],
  purrr[map],
  utils[download.file],
  rvest[read_html, html_element, html_text2],
  jsonlite[fromJSON],
)

# ==============================================================================
# CONFIGURACION
# ==============================================================================

BASE_URL    <- "https://ces-bcsf.github.io/CicSFE_GitHub/indicadores"
GITHUB_API  <- "https://api.github.com/repos/ces-bcsf/CicSFE_GitHub/contents/indicadores"

# ==============================================================================
# FUNCIONES
# ==============================================================================

#' Obtiene dinamicamente los codigos de todos los indicadores desde la API de GitHub
#' Retorna un vector de strings con los codigos (ej: "ARG-IL5", "SFE-RMP")
fetch_codigos <- function() {
  archivos <- fromJSON(GITHUB_API)
  nombres  <- archivos$name
  xlsx     <- nombres[grepl("_out\\.xlsx$", nombres) & !grepl("^HP", nombres)]
  sub("_out\\.xlsx$", "", xlsx)
}

#' Construye la URL del Excel dado el codigo del indicador
build_excel_url <- function(codigo) {
  paste0(BASE_URL, "/", codigo, "_out.xlsx")
}

#' Construye la URL del HTML dado el codigo del indicador
build_html_url <- function(codigo) {
  paste0(BASE_URL, "/", codigo, "_views.html")
}

#' Descarga el Excel a un archivo temporal y retorna su path
download_excel <- function(url) {
  temp <- tempfile(fileext = ".xlsx")
  download.file(url, temp, mode = "wb", quiet = TRUE)
  temp
}

#' Extrae los metadatos desde la hoja Portada
#' Retorna un tibble de 1 fila: id, nombre, unidad_medida, fuente
extract_metadata <- function(path) {
  portada <- read_excel(path, sheet = "Portada", col_names = FALSE)

  tibble(
    id            = as.character(portada[[3]][6]),
    nombre        = as.character(portada[[3]][2]),
    unidad_medida = as.character(portada[[3]][3]),
    fuente        = as.character(portada[[3]][4]),
  )
}

#' Extrae el texto del div.info-box que sigue al h2 "Resumen de coyuntura"
#' Retorna un string con el resumen, o NA si no se encuentra
extract_resumen <- function(codigo) {
  html <- read_html(build_html_url(codigo))

  nodo <- html_element(
    html,
    xpath = "//h2[normalize-space(.)='Resumen de coyuntura']/following-sibling::div[contains(@class,'info-box')][1]"
  )

  html_text2(nodo)
}

#' Extrae la serie de datos desde la hoja Data, sin NAs
#' Retorna un tibble con columnas: id_indicador, fecha, valor
extract_serie <- function(path, id_indicador) {
  data <- read_excel(path, sheet = "Data")

  tibble(
    id_indicador = id_indicador,
    fecha        = data[[1]],
    valor        = data[[13]],  # columna M = g_final
  ) |>
    filter(!is.na(valor))
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

  metadata <- extract_metadata(temp)
  serie    <- extract_serie(temp, metadata$id)

  metadata <- bind_cols(metadata, tibble(
    fecha_ultimo_dato = max(serie$fecha),
    frecuencia        = infer_frecuencia(serie$fecha),
    resumen_coyuntura = extract_resumen(codigo),
  ))

  list(
    metadata = metadata,
    serie    = serie
  )
}

#' Persiste los dos tibbles a data/processed/ como archivos RDS
#' Crea el directorio si no existe
write_output <- function(series) {
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  saveRDS(series$indicadores, "data/processed/indicadores.rds")
  saveRDS(series$datos,       "data/processed/datos.rds")
}

#' Carga todos los indicadores del vector INDICADORES
#' Retorna una lista con $indicadores (tibble) y $datos (tibble)
load_all_indicators <- function(codigos) {
  resultados <- map(codigos, process_indicator)

  list(
    indicadores = bind_rows(map(resultados, "metadata")),
    datos       = bind_rows(map(resultados, "serie"))
  )
}

# ==============================================================================
# EJECUCION
# ==============================================================================

codigos <- fetch_codigos()

series <- load_all_indicators(codigos)

write_output(series)
