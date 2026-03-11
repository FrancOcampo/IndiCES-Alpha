box::use(
  shiny[shinyApp, req, reactive],
  bslib[page_sidebar, sidebar, navset_card_tab, nav_panel, bs_theme],
  ./modules/data_loader[load_indicadores, load_datos, filter_datos],
  ./modules/selector_ui[selectorUI, selectorServer],
  ./modules/chart_ui[chartUI, chartServer],
  ./modules/info_ui[infoUI, infoServer],
)

# Carga los datos una sola vez al arrancar
indicadores <- load_indicadores()
datos       <- load_datos()

ui <- page_sidebar(
  title = "IndiCES — Indicadores Económicos CES Santa Fe",
  theme = bs_theme(version = 5, primary = "#1a6bb5"),

  sidebar = sidebar(
    width  = 300,
    selectorUI("selector"),
  ),

  navset_card_tab(
    full_screen = TRUE,
    nav_panel("Gráfico",      chartUI("chart")),
    nav_panel("Información",  infoUI("info")),
  ),
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
  infoServer("info",  indicador_rv)
}

shinyApp(ui, server)
