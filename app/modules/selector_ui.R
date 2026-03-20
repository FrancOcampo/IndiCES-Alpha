box::use(
  shiny[
    NS, tagList, selectizeInput, tags, moduleServer, reactive,
    updateSelectizeInput, renderText, textOutput, observe, req,
  ],
  stats[setNames],
)

#' UI del selector de indicadores
#' Incluye un selector de clasificación sectorial que filtra el selector de indicadores
selectorUI <- function(id) {
  ns <- NS(id)
  tagList(
    selectizeInput(
      ns("sector"),
      label   = "Clasificación por eje",
      choices = NULL,
      options = list(placeholder = "Seleccioná un eje...")
    ),
    tags$div(
      style = "margin-top: 0.75rem;",
      selectizeInput(
        ns("indicador"),
        label   = "Codigo | Indicador",
        choices = NULL,
        options = list(placeholder = "Seleccioná un indicador...")
      ),
    )
  )
}

#' Server del selector de indicadores
#' Recibe el tibble de indicadores y retorna un reactive con el id seleccionado
selectorServer <- function(id, indicadores) {
  moduleServer(id, function(input, output, session) {
    sectores_sorted <- sort(unique(indicadores$clasificacion_sectorial))
    otros  <- sectores_sorted[grepl("^Otros", sectores_sorted)]
    resto  <- sectores_sorted[!grepl("^Otros", sectores_sorted)]
    sectores <- c("Todas", resto, otros)
    updateSelectizeInput(session, "sector", choices = sectores, selected = "Producto y actividad económica")

    observe({
      req(input$sector)
      filtrados <- if (input$sector == "Todas") {
        indicadores
      } else {
        indicadores[indicadores$clasificacion_sectorial == input$sector, ]
      }
      choices <- setNames(filtrados$id, paste0(filtrados$id, " | ", filtrados$nombre))
      updateSelectizeInput(session, "indicador", choices = choices)
    })

    reactive(input$indicador)
  })
}
