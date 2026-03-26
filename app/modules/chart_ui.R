box::use(
  shiny[NS, moduleServer, req, validate, need],
  plotly[plot_ly, add_trace, layout, plotlyOutput, renderPlotly, config],
)

#' UI del grafico de serie temporal
chartUI <- function(id) {
  ns <- shiny::NS(id)
  plotly::plotlyOutput(ns("grafico"), height = "420px")
}

#' Server del grafico de serie temporal
#' Recibe un reactive con el tibble filtrado (fecha, valor) y la fila del indicador
chartServer <- function(id, datos_rv, indicador_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    output$grafico <- plotly::renderPlotly({
      shiny::validate(shiny::need(!is.null(datos_rv()) && !is.null(indicador_rv()), "Seleccioná un indicador para ver el gráfico."))
      datos     <- datos_rv()
      indicador <- indicador_rv()
      shiny::validate(shiny::need(base::nrow(datos) > 0, "No hay datos disponibles para este indicador."))

      hovertemplate <- base::paste0("<b>%{x|%b %Y}</b><br>", indicador$unidad_medida, ": %{y}<extra></extra>")

      plotly::plot_ly(datos, x = ~fecha) |>
        plotly::add_trace(
          y             = ~valor_original,
          name          = "Datos originales",
          type          = "scatter", mode = "lines",
          line          = list(color = "#adb5bd", width = 1.5),
          hovertemplate = hovertemplate
        ) |>
        plotly::add_trace(
          y             = ~valor,
          name          = "Datos filtrados",
          type          = "scatter", mode = "lines",
          line          = list(color = "#000", width = 1.5),
          hovertemplate = hovertemplate
        ) |>
        plotly::layout(
          title      = list(text = indicador$nombre, font = list(size = 14)),
          xaxis      = list(title = "", showgrid = TRUE),
          yaxis      = list(title = indicador$unidad_medida, showgrid = TRUE, gridcolor = "#e9ecef"),
          legend     = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.15),
          showlegend = TRUE,
          paper_bgcolor = "white",
          plot_bgcolor  = "white",
          margin = list(t = 50)
        ) |>
        plotly::config(displayModeBar = FALSE)
      # TOMAR EJEMPLO DE ACA PARA HACER LA RECESION EN SANTA FE
      # plot_ly(datos, x = ~fecha) |>
      #   add_trace(
      #     y         = ~indicador,
      #     name      = "Indicador",
      #     type      = "scatter", mode = "lines",
      #     line      = list(color = "#000", width = 1.5)
      #   ) |>
      #   add_trace(
      #     y         = ~recesion,           # tus 0s y 1s
      #     name      = "Recesiones SF",
      #     type      = "scatter", mode = "none",
      #     fill      = "tozeroy",
      #     fillcolor = "rgba(0, 0, 0, 0.15)",
      #     yaxis     = "y2"
      #   ) |>
      #   layout(
      #     yaxis  = list(title = "tu unidad"),
      #     yaxis2 = list(
      #       overlaying  = "y",
      #       side        = "right",
      #       range       = c(0, 1),
      #       showticklabels = FALSE,
      #       showgrid    = FALSE
      #     )
      #   )
    })
  })
}
