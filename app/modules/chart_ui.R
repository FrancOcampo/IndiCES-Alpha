box::use(
  shiny[NS, moduleServer, req, validate, need],
  plotly[plot_ly, layout, plotlyOutput, renderPlotly, config],
)

#' UI del grafico de serie temporal
chartUI <- function(id) {
  ns <- NS(id)
  plotlyOutput(ns("grafico"), height = "420px")
}

#' Server del grafico de serie temporal
#' Recibe un reactive con el tibble filtrado (fecha, valor) y la fila del indicador
chartServer <- function(id, datos_rv, indicador_rv) {
  moduleServer(id, function(input, output, session) {
    output$grafico <- renderPlotly({
      validate(need(!is.null(datos_rv()) && !is.null(indicador_rv()), "Seleccioná un indicador para ver el gráfico."))
      datos     <- datos_rv()
      indicador <- indicador_rv()
      validate(need(nrow(datos) > 0, "No hay datos disponibles para este indicador."))

      plot_ly(datos, x = ~fecha, y = ~valor, type = "scatter", mode = "lines",
        line    = list(color = "#000", width = 2),
        hovertemplate = paste0("<b>%{x|%b %Y}</b><br>", indicador$unidad_medida, ": %{y}<extra></extra>")
      ) |>
        layout(
          title  = list(text = indicador$nombre, font = list(size = 14)),
          xaxis  = list(title = "", showgrid = TRUE),
          yaxis  = list(title = indicador$unidad_medida, showgrid = TRUE, gridcolor = "#e9ecef"),
          paper_bgcolor = "white",
          plot_bgcolor  = "white",
          margin = list(t = 50)
        ) |>
        config(displayModeBar = FALSE)
    })
  })
}
