box::use(
  readxl[read_excel],
  utils[download.file],
  base[tempfile, unlink, tryCatch],
  dplyr[select, mutate, bind_rows, as_tibble],
  purrr[map_dfr],
  cli[cli_alert_success, cli_alert_danger, cli_alert_info, cli_progress_bar],
  fs[file_delete]
)

#' @title FILTRAR ARCHIVO EXCEL TEMP
#' @description TOMA EL ARCHIVO DE MEMORIA SI EXISTE Y EXTRAE LOS DATOS DE INTERES
#' @param temp_loc TABLA DE DATOS, TIPO DF.
#' @return Tibble con las columnas seleccionadas.
filter_data <- function(temp_loc){
  readxl::read_excel(temp_loc, sheet = "Portada", col_names = FALSE) 
    
  nombre <- as.character(meta_raw[[3]][2])
  print(nombre)
  #https://ces-bcsf.github.io/web_ces/indicadores/ARG-IL5_out.xlsx  
  return(nombre)
}


#' @title PROCESAR ARCHIVO INDIVIDUAL
#' @description DESCARGA, LEE, FILTRA COLUMNAS Y BORRA EL ARCHIVO TEMPORAL
#' @param url STRING. URL DEL ARCHIVO
#' @return TIBBLE CON LAS COLUMNAS SELECCIONADAS Y LOS METADATOS NECESARIOS
process_single_excel <- function(url){
  #CREAR EL ARCHIVO TEMPORAL EN MEMORIA
  temp_loc <- tempfile(fileext = ".xlsx")
  
  #DESCARGA
  tryCatch({
    download.file(url, temp_loc, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    return(NULL)
  }
  )
  
  #LEER Y FILTRAR
  data_clean <- tryCatch({
    filter_data(temp_loc)  
  }, error = function(e){
    return(NULL)
  }, finally = {
    #LIMPIEZA DEL ARCHIVO LEIDO SI EXISTE
    if (fs::file_exists(temp_loc)) fs::file_delete(temp_loc)
  }
  )
  
  return(data_clean)
}

temp_path <- "https://ces-bcsf.github.io/web_ces/indicadores/ARG-IL5_out.xlsx"

process_single_excel(temp_path)

