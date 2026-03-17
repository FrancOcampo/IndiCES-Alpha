box::use(
  shiny[NS, moduleServer, tagList, tags, uiOutput, renderUI, req],
)

#' FUNCION QUE CONVIERTE UN STRING EN SENTENCE CASE
str_to_sentence_case <- function(str){
  base::paste0(base::toupper(base::substr(str, 1, 1)), base::substr(str, 2, base::nchar(str)))
}

fecha_a_espaniol <- function(fecha){
  
  meses <- c(
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
  )
  
  paste(str_to_sentence_case(meses[as.integer(format(fecha, "%m"))]), format(fecha, "%Y"))
  
}

#' UI de las tarjetas de metadata principal (nombre, ultimo dato, frecuencia)
metadataPrincipalUI <- function(id) {
  ns <- NS(id)
  uiOutput(ns("cards"))
}

#' Server de metadata principal
metadataPrincipalServer <- function(id, indicador_rv) {
  moduleServer(id, function(input, output, session) {
    output$cards <- renderUI({
      ind <- indicador_rv()
      req(!is.null(ind), nrow(ind) > 0)
      
      
      frecuencia_selected <- str_to_sentence_case(ind$frecuencia[[1]])
      
      tags$div(
        class = "meta-cards",
        tags$div(
          class = "meta-card",
          tags$div(class = "meta-card-label", "Indicador"),
          tags$div(class = "meta-card-value", ind$nombre[[1]]),
        ),
        tags$div(
          class = "meta-card",
          tags$div(class = "meta-card-label", "\u00DAltimo dato"),
          tags$div(class = "meta-card-value",
                   fecha_a_espaniol(ind$fecha_ultimo_dato[[1]])),
        ),
        tags$div(
          class = "meta-card",
          tags$div(class = "meta-card-label", "Frecuencia"),
          tags$div(class = "meta-card-value", frecuencia_selected),
        ),
      )
    })
  })
}

#' UI del panel de detalle (metadata secundaria)
detalleUI <- function(id) {
  ns <- NS(id)
  uiOutput(ns("panel"))
}

#' Server del panel de detalle
detalleServer <- function(id, indicador_rv) {
  moduleServer(id, function(input, output, session) {
    output$panel <- renderUI({
      ind <- indicador_rv()
      req(!is.null(ind), nrow(ind) > 0)

      tags$dl(
        tags$dt("Descripción"),
        tags$dd(ind$descripcion_str[[1]]),
        tags$dt("Código"),
        tags$dd(ind$codigo_str[[1]]),
        tags$dt("Unidad de medida"),
        tags$dd(ind$um_str[[1]]),
        tags$dt("Fuente primaria"),
        tags$dd(ind$fuente_primaria_str[[1]]),
      )
      # tags$dl(
      #   tags$dt("Fuente"),
      #   tags$dd(ind$fuente[[1]]),
      #   tags$dt("Unidad de medida"),
      #   tags$dd(ind$unidad_medida[[1]]),
      #   tags$dt("Frecuencia"),
      #   tags$dd(ind$frecuencia[[1]]),
      #   tags$dt("\u00DAltimo dato disponible"),
      #   tags$dd(format(ind$fecha_ultimo_dato[[1]], "%B %Y")),
      # )
    })
  })
}

#' UI del texto explicativo (resumen de coyuntura)
explicativoUI <- function(id) {
  ns <- NS(id)
  uiOutput(ns("texto"))
}

#' Server del texto explicativo
explicativoServer <- function(id, indicador_rv) {
  moduleServer(id, function(input, output, session) {
    output$texto <- renderUI({
      ind <- indicador_rv()
      req(!is.null(ind), nrow(ind) > 0)

      resumen <- ind$resumen_coyuntura[[1]]
      if (is.na(resumen) || resumen == "") {
        return(tags$p(class = "text-muted",
                      "No hay resumen de coyuntura disponible para este indicador."))
      }

      tagList(
        tags$h3("Resumen de coyuntura"),
        tags$p(resumen),
      )
    })
  })
}
