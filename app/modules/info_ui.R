box::use(
  shiny[NS, moduleServer, tagList, tags, renderUI, uiOutput, req],
)

#' UI del panel de información del indicador
infoUI <- function(id) {
  ns <- NS(id)
  uiOutput(ns("panel"))
}

#' Server del panel de información del indicador
#' Recibe un reactive con la fila del indicador seleccionado
infoServer <- function(id, indicador_rv) {
  moduleServer(id, function(input, output, session) {
    output$panel <- renderUI({
      ind <- indicador_rv()
      req(!is.null(ind))

      resumen <- if (!is.na(ind$resumen_coyuntura[[1]])) {
        tags$div(
          tags$h6("Resumen de coyuntura"),
          tags$p(ind$resumen_coyuntura[[1]], style = "text-align: justify;"),
        )
      }

      tagList(
        tags$dl(
          tags$dt("Fuente"),         tags$dd(ind$fuente[[1]]),
          tags$dt("Unidad"),         tags$dd(ind$unidad_medida[[1]]),
          tags$dt("Frecuencia"),     tags$dd(ind$frecuencia[[1]]),
          tags$dt("Último dato"),    tags$dd(format(ind$fecha_ultimo_dato[[1]], "%B %Y")),
        ),
        tags$hr(),
        resumen,
      )
    })
  })
}
