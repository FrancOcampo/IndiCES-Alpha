box::use(
  shiny[
    NS, tagList, selectizeInput, tags, moduleServer, reactive,
    updateSelectizeInput, renderText, textOutput, observe, req,
  ],
  stats[setNames],
)

#' UI del selector de indicadores
selectorUI <- function(id) {
  ns <- NS(id)
  tagList(
    selectizeInput(
      ns("indicador"),
      label    = "Indicador",
      choices  = NULL,
      options  = list(placeholder = "Seleccioná un indicador...")
    ),
  )
}

#' Server del selector de indicadores
#' Recibe el tibble de indicadores y retorna un reactive con el id seleccionado
selectorServer <- function(id, indicadores) {
  moduleServer(id, function(input, output, session) {
    choices <- setNames(indicadores$id, indicadores$nombre)
    updateSelectizeInput(session, "indicador", choices = choices, server = TRUE)

    seleccionado <- reactive({
      req(input$indicador)
      indicadores[indicadores$id == input$indicador, ]
    })

    reactive(input$indicador)
  })
}
