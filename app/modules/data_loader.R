box::use(
  here[here],
  dplyr[filter],
)

#' Carga el tibble de indicadores desde el RDS
#' Retorna un tibble con una fila por indicador
load_indicadores <- function() {
  readRDS(here("data/processed/indicadores.rds"))
}

#' Carga el tibble completo de datos desde el RDS
#' Retorna un tibble con una fila por observación
load_datos <- function() {
  readRDS(here("data/processed/datos.rds"))
}

#' Filtra las observaciones de un indicador dado su id
#' Retorna un tibble con columnas: id_indicador, fecha, valor
filter_datos <- function(datos, id) {
  filter(datos, id_indicador == id)
}
