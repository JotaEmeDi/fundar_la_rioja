# =============================================================================
# DASHBOARD — Monitor Socioeconómico La Rioja (Fundar / CFI)
# -----------------------------------------------------------------------------
# App Shiny para explorar los indicadores. Reusa el núcleo compartido
# (R/data.R + R/plots.R), que a su vez reusa el tema del informe. Correr con:
#   shiny::runApp("dashboard")
# Deploy a shinyapps.io: ver dashboard/deploy.md
# =============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(plotly)
  library(readr)
  library(dplyr)
})

source("R/data.R")
source("R/plots.R")

# -----------------------------------------------------------------------------
# Tema visual de la app: acompaña la paleta de los gráficos (Fundar Monitor).
# -----------------------------------------------------------------------------
tema_app <- bs_theme(
  version      = 5,
  bg           = "#FFFFFF",
  fg           = FUNDAR_TEXTO,
  primary      = "#2D6E6E",     # teal La Rioja
  secondary    = FUNDAR_VERDE,
  font_scale   = 0.82,          # fuentes globales más chicas (más aire para los gráficos)
  base_font    = font_google("Inter"),
  heading_font = font_google("Inter")
) |>
  bs_add_rules(sprintf("
    body { background: #FFFFFF; }
    .card { border-radius: 10px; }
    .indicador-desc { color: %s; font-size: 0.8rem; }
    .card-header { font-size: 0.95rem; font-weight: 600; padding: 0.4rem 0.75rem; }

    /* KPIs compactos: cuadros bajos y tipografía chica para no comerle
       espacio al gráfico */
    .value-box { border-radius: 10px; }
    .value-box .value-box-area { padding: 0.35rem 0.7rem; }
    .value-box .value-box-title { font-size: 0.72rem; margin-bottom: 0.05rem; opacity: 0.85; }
    .value-box .value-box-value { font-size: 1.1rem; line-height: 1.05; }
    .value-box .value-box-showcase { padding: 0 0.4rem; }
    .value-box .value-box-showcase svg { width: 1.4rem; height: 1.4rem; }
  ", FUNDAR_GRIS))

# Opciones del selector de indicador, agrupadas por tópico.
opciones_indicador <- lapply(TOPICOS, function(tp) {
  ids <- Filter(function(id) INDICADORES[[id]]$topico == tp, names(INDICADORES))
  setNames(as.list(ids), vapply(ids, function(id) INDICADORES[[id]]$titulo, character(1)))
})
names(opciones_indicador) <- TOPICOS

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------
ui <- page_sidebar(
  title = "Monitor Socioeconómico La Rioja",
  theme = tema_app,
  window_title = "Monitor La Rioja — Fundar",

  sidebar = sidebar(
    width = 280,
    selectInput("indicador", "Indicador",
                choices = opciones_indicador, selected = "desocupacion"),

    checkboxGroupInput("regiones", "Regiones",
                       choices  = REGIONES, selected = REGIONES),

    # Selector de sub-dimensión: sólo visible para los indicadores NBI.
    conditionalPanel(
      condition = "input.indicador == 'nbi_hogares' || input.indicador == 'nbi_poblacion'",
      selectInput("dimension", "Dimensión NBI",
                  choices = c("Total" = "TOT", "Hacinamiento" = "HAC",
                              "Vivienda inconveniente" = "VIV",
                              "Condiciones sanitarias" = "SAN",
                              "Escolaridad" = "ESC",
                              "Capacidad de subsistencia" = "SUB"),
                  selected = "TOT")
    ),

    uiOutput("slider_fecha"),

    input_switch("interactivo", "Gráfico interactivo", value = FALSE),

    hr(),
    downloadButton("descargar_png", "Descargar PNG", class = "btn-sm"),
    downloadButton("descargar_csv", "Descargar datos (CSV)", class = "btn-sm"),
    hr(),
    tags$small(class = "indicador-desc",
               "Fuente y método varían por indicador (ver detalle bajo el gráfico).")
  ),

  layout_columns(
    fill = FALSE,
    col_widths = c(4, 4, 4),
    value_box(
      title = "Último valor — La Rioja",
      value = textOutput("kpi_valor"),
      showcase = bsicons::bs_icon("graph-up"),
      theme = value_box_theme(bg = "#2D6E6E", fg = "#FFFFFF"),
      height = "88px"
    ),
    value_box(
      title = "Variación vs. período previo",
      value = textOutput("kpi_delta"),
      showcase = bsicons::bs_icon("arrow-left-right"),
      theme = value_box_theme(bg = FUNDAR_BEIGE, fg = FUNDAR_TEXTO),
      height = "88px"
    ),
    value_box(
      title = "Período más reciente",
      value = textOutput("kpi_fecha"),
      showcase = bsicons::bs_icon("calendar3"),
      theme = value_box_theme(bg = FUNDAR_BEIGE, fg = FUNDAR_TEXTO),
      height = "88px"
    )
  ),

  card(
    full_screen = TRUE,
    fill = TRUE,
    card_header(textOutput("titulo_card")),
    uiOutput("grafico_ui")
  ),

  card(
    card_body(
      tags$p(class = "indicador-desc", textOutput("descripcion"))
    )
  )
)

# -----------------------------------------------------------------------------
# SERVER
# -----------------------------------------------------------------------------
server <- function(input, output, session) {

  meta_actual <- reactive(INDICADORES[[input$indicador]])

  # La dimensión sólo aplica a NBI; para el resto se fuerza "TOT".
  dim_actual <- reactive({
    m <- meta_actual()
    if (!is.null(m$dimensiones)) input$dimension else "TOT"
  })

  # Slider de fechas reconstruido según el rango real del indicador elegido.
  output$slider_fecha <- renderUI({
    rng <- rango_fechas_indicador(input$indicador, dim_actual())
    sliderInput("rango", "Rango temporal",
                min = rng[1], max = rng[2],
                value = rng, timeFormat = "%Y")
  })

  datos_filtrados <- reactive({
    df <- cargar_indicador(input$indicador, dim_actual())
    if (!is.null(input$regiones)) df <- dplyr::filter(df, la_rioja_region %in% input$regiones)
    if (!is.null(input$rango)) {
      df <- dplyr::filter(df, fecha >= input$rango[1], fecha <= input$rango[2])
    }
    df
  })

  grafico <- reactive({
    plot_indicador(
      id           = input$indicador,
      regiones     = input$regiones,
      rango_fechas = input$rango,
      dimension    = dim_actual(),
      interactivo  = isTRUE(input$interactivo),
      base_size    = 10   # tipografía interna del gráfico más chica en pantalla
    )
  })

  # Render híbrido: plotly cuando el switch está activo, ggplot fiel si no.
  output$grafico_ui <- renderUI({
    if (isTRUE(input$interactivo)) plotlyOutput("grafico_plotly", height = "600px")
    else plotOutput("grafico_ggplot", height = "600px")
  })
  output$grafico_ggplot <- renderPlot({ grafico() }, res = 96)
  output$grafico_plotly <- renderPlotly({ grafico() })

  # KPIs (siempre sobre La Rioja).
  kpi <- reactive(kpi_indicador(input$indicador, dim_actual()))
  output$kpi_valor <- renderText({
    v <- kpi()$valor
    if (is.na(v)) "s/d" else .fmt_valor(v, meta_actual()$shape)
  })
  output$kpi_delta <- renderText({
    d <- kpi()$delta
    if (is.na(d)) "s/d"
    else sprintf("%s%s", if (d >= 0) "+" else "",
                 format(round(d, 1), nsmall = 1, decimal.mark = ","))
  })
  output$kpi_fecha <- renderText({
    f <- kpi()$fecha_lab
    if (is.na(f)) "s/d" else f
  })

  output$titulo_card  <- renderText(meta_actual()$titulo)
  output$descripcion  <- renderText(meta_actual()$desc)

  # Descargas.
  output$descargar_png <- downloadHandler(
    filename = function() paste0(input$indicador, ".png"),
    content  = function(file) {
      p <- plot_indicador(input$indicador, input$regiones, input$rango,
                          dim_actual(), interactivo = FALSE)
      ggplot2::ggsave(file, plot = p, width = 12, height = 7, dpi = 150, bg = "white")
    }
  )
  output$descargar_csv <- downloadHandler(
    filename = function() paste0(input$indicador, ".csv"),
    content  = function(file) readr::write_csv(datos_filtrados(), file)
  )
}

shinyApp(ui, server)
