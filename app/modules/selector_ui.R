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
    tags$p(
      tags$small(tags$b("Frecuencia: "), textOutput(ns("frecuencia"), inline = TRUE)),
    ),
    tags$p(
      tags$small(tags$b("Último dato: "), textOutput(ns("ultimo_dato"), inline = TRUE)),
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

    output$frecuencia <- renderText({
      seleccionado()$frecuencia[[1]]
    })

    output$ultimo_dato <- renderText({
      format(seleccionado()$fecha_ultimo_dato[[1]], "%B %Y")
    })

    reactive(input$indicador)
  })
}
