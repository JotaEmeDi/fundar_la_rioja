# =============================================================================
# NÚCLEO DE GRAFICADO DEL DASHBOARD
# -----------------------------------------------------------------------------
# Una sola función, plot_indicador(), que dibuja cualquier indicador reusando
# el tema del informe (style/fundar_monitor_theme.R). La app Shiny y el export
# estático la llaman con los mismos argumentos, así que la fidelidad de estilo
# es idéntica en ambos. Con interactivo = TRUE devuelve un widget plotly
# (la mitad "interactiva" del enfoque híbrido); con FALSE, el ggplot fiel.
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})
# plotly se carga de forma perezosa (sólo cuando interactivo = TRUE), así el
# camino fiel (ggplot) y el export de PNG no dependen de plotly.

# data.R define INDICADORES, cargar_indicador(), REGIONES, STYLE_DIR, etc.
# Debe sourcearse ANTES que este archivo (así lo hacen app.R e index.qmd).
if (!exists("INDICADORES") || !exists("STYLE_DIR")) {
  stop("Sourceá primero dashboard/R/data.R antes de dashboard/R/plots.R")
}
source(file.path(STYLE_DIR, "fundar_monitor_theme.R"))

# -----------------------------------------------------------------------------
# Color por región ESTABLE
# -----------------------------------------------------------------------------
# scale_color_fundar_multi() asigna colores por orden de aparición, así que al
# filtrar regiones el color de cada serie se correría. Un vector NOMBRADO por
# región (derivado de la misma paleta FUNDAR_MULTI del tema) fija el color de
# La Rioja aunque se deseleccionen las otras series.
REGION_COLORS <- c(
  "1. Resto país" = unname(FUNDAR_MULTI["serie_1"]),  # verde menta claro
  "2. NOA-Resto"  = unname(FUNDAR_MULTI["serie_2"]),  # amarillo oliva
  "3. La Rioja"   = unname(FUNDAR_MULTI["serie_3"])   # teal — énfasis
)
# Nombres marcados UTF-8 para que el match por región sea estable en cualquier
# locale (ver nota en data.R). REGIONES viene de data.R ya marcado.
names(REGION_COLORS) <- REGIONES

# Formato de valor para tooltips / etiquetas según el tipo de indicador.
.fmt_valor <- function(v, shape) {
  if (shape == "A") {
    paste0(format(round(v, 1), nsmall = 1, decimal.mark = ","), "%")
  } else {
    format(round(v), big.mark = ".", decimal.mark = ",", scientific = FALSE)
  }
}

# -----------------------------------------------------------------------------
# plot_indicador()
# -----------------------------------------------------------------------------
# id           : clave de INDICADORES
# regiones     : subconjunto de REGIONES a mostrar (NULL = todas)
# rango_fechas : c(desde, hasta) como Date (NULL = todo el rango)
# dimension    : sólo NBI ("TOT","HAC","VIV","SAN","ESC","SUB")
# interactivo  : TRUE -> plotly; FALSE -> ggplot fiel
plot_indicador <- function(id, regiones = NULL, rango_fechas = NULL,
                           dimension = "TOT", interactivo = FALSE) {
  meta <- INDICADORES[[id]]
  if (is.null(meta)) stop("Indicador desconocido: ", id)

  df <- cargar_indicador(id, dimension = dimension)

  if (!is.null(regiones) && length(regiones) > 0) {
    df <- dplyr::filter(df, la_rioja_region %in% regiones)
  }
  if (!is.null(rango_fechas)) {
    df <- dplyr::filter(df, fecha >= rango_fechas[1], fecha <= rango_fechas[2])
  }

  # Subtítulo dinámico: nombre de la sub-dimensión NBI cuando aplica.
  subt <- if (!is.null(meta$dimensiones)) unname(meta$dim_labels[[dimension]]) else NULL

  df <- dplyr::mutate(df,
    .tip = paste0(la_rioja_region, "<br>", fecha_lab, "<br>",
                  .fmt_valor(valor, meta$shape))
  )

  p <- ggplot(df, aes(x = fecha, y = valor,
                      color = la_rioja_region, group = la_rioja_region,
                      text = .tip)) +
    geom_line(linewidth = 0.7) +
    scale_color_manual(values = REGION_COLORS, name = NULL) +
    theme_monitor() +
    labs(title    = meta$titulo,
         subtitle = subt,
         x        = meta$eje_x,
         y        = meta$y_lab,
         caption  = fuente_fundar(meta$caption))

  if (meta$shape == "B") {
    # Serie provincial: facetas por región + puntos clave (máx/mín/último),
    # igual que src/05_*.R y src/07_*.R.
    key <- puntos_etiqueta(df, fecha, valor, la_rioja_region)
    p <- p +
      geom_point(data = key, size = 1.8, show.legend = FALSE) +
      facet_wrap(~ la_rioja_region, scales = "free_y") +
      scale_x_date(date_labels = "%Y", date_breaks = "3 years")

    # Las etiquetas de texto sólo en el modo fiel (en plotly el hover ya informa).
    if (!interactivo) {
      key <- dplyr::mutate(key, .lab = .fmt_valor(valor, "B"))
      p <- p +
        geom_text(data = key,
                  aes(label = .lab, hjust = .hjust, vjust = .vjust),
                  size = 2.4, fontface = "bold", show.legend = FALSE) +
        scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
        coord_cartesian(clip = "off")
    }
  } else {
    p <- p + scale_x_date(date_labels = "%Y", date_breaks = "2 years")
    if (!is.null(meta$ylim)) p <- p + coord_cartesian(ylim = meta$ylim)
  }

  if (interactivo) {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      stop("El modo interactivo requiere el paquete 'plotly' (install.packages('plotly')).")
    }
    gp <- plotly::ggplotly(p, tooltip = "text")
    # Leyenda horizontal arriba, como en el tema.
    gp <- plotly::layout(gp,
      legend = list(orientation = "h", x = 0, y = 1.08, title = list(text = "")),
      margin = list(t = 60)
    )
    return(gp)
  }

  p
}
