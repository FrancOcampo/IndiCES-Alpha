box::use(
  shiny[NS, moduleServer, downloadButton, downloadHandler, tagList, div, req],
  plotly[plot_ly, layout, add_lines, plotlyOutput, renderPlotly, config],
)

#' UI del gráfico de serie temporal
chartUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotlyOutput(ns("grafico"), height = "420px"),
    div(
      style = "margin-top: 12px;",
      downloadButton(ns("descargar"), "Descargar CSV", class = "btn-sm btn-outline-secondary"),
    ),
  )
}

#' Server del gráfico de serie temporal
#' Recibe un reactive con el tibble filtrado (fecha, valor) y la fila del indicador
chartServer <- function(id, datos_rv, indicador_rv) {
  moduleServer(id, function(input, output, session) {
    output$grafico <- renderPlotly({
      req(datos_rv(), indicador_rv())
      datos     <- datos_rv()
      indicador <- indicador_rv()
      req(nrow(datos) > 0)

      message("--- DEBUG chart ---")
      message("class(datos): ", paste(class(datos), collapse = ", "))
      message("nrow(datos): ", nrow(datos))
      message("names(datos): ", paste(names(datos), collapse = ", "))
      message("class(datos$fecha): ", paste(class(datos$fecha), collapse = ", "))
      message("class(datos$valor): ", paste(class(datos$valor), collapse = ", "))
      message("head(datos$fecha): ", paste(utils::head(datos$fecha, 3), collapse = ", "))
      message("head(datos$valor): ", paste(utils::head(datos$valor, 3), collapse = ", "))
      message("--- END DEBUG ---")

      plot_ly(datos, x = ~fecha, y = ~valor, type = "scatter", mode = "lines+markers",
        line    = list(color = "#1a6bb5", width = 2),
        marker  = list(color = "#1a6bb5", size = 5),
        hovertemplate = paste0("<b>%{x|%b %Y}</b><br>", indicador$unidad_medida, ": %{y}<extra></extra>")
      ) |>
        layout(
          title  = list(text = indicador$nombre, font = list(size = 14)),
          xaxis  = list(title = "", showgrid = FALSE),
          yaxis  = list(title = indicador$unidad_medida, showgrid = TRUE, gridcolor = "#e9ecef"),
          paper_bgcolor = "white",
          plot_bgcolor  = "white",
          margin = list(t = 50)
        ) |>
        config(displayModeBar = FALSE)
    })

    output$descargar <- downloadHandler(
      filename = function() paste0(indicador_rv()$id, "_datos.csv"),
      content  = function(file) utils::write.csv(datos_rv(), file, row.names = FALSE),
    )
  })
}
