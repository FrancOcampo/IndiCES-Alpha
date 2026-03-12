box::use(
  shiny[shinyApp, htmlTemplate, req, reactive],
  ./modules/data_loader[load_indicadores, load_datos, filter_datos],
  ./modules/selector_ui[selectorUI, selectorServer],
  ./modules/chart_ui[chartUI, chartServer],
  ./modules/metadata_ui[metadataPrincipalUI, metadataPrincipalServer,
                         detalleUI, detalleServer,
                         explicativoUI, explicativoServer],
  ./modules/acciones_ui[accionesUI, accionesServer],
)

# Carga los datos una sola vez al arrancar
indicadores <- load_indicadores()
datos       <- load_datos()

ui <- htmlTemplate(
  "www/index.html",
  selector           = selectorUI("selector"),
  metadata_principal = metadataPrincipalUI("meta"),
  grafico            = chartUI("chart"),
  acciones           = accionesUI("acciones"),
  detalle            = detalleUI("detalle"),
  explicativo        = explicativoUI("explicativo"),
)

server <- function(input, output, session) {
  id_rv <- selectorServer("selector", indicadores)

  indicador_rv <- reactive({
    req(id_rv())
    indicadores[indicadores$id == id_rv(), ]
  })

  datos_rv <- reactive({
    req(id_rv())
    filter_datos(datos, id_rv())
  })

  chartServer("chart", datos_rv, indicador_rv)
  metadataPrincipalServer("meta", indicador_rv)
  accionesServer("acciones", indicador_rv, datos_rv)
  detalleServer("detalle", indicador_rv)
  explicativoServer("explicativo", indicador_rv)
}

shinyApp(ui, server)
