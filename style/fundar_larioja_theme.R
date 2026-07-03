# =============================================================================
# TEMPLATE DE ESTILO — Monitor Socioeconómico La Rioja
# Fundar — grupo factor~data
# =============================================================================
# Uso: source("fundar_larioja_theme.R") al inicio de cada script o chunk

library(ggplot2)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. PALETA DE COLORES
# -----------------------------------------------------------------------------

# Colores base por región (con alpha incorporado en HEX: #RRGGBBAA)
COLORES_REGION <- c(
  "1. Resto país" = "#BBBBBB80",  # Gris,    alpha 0.50
  "2. NOA-Resto"  = "#2166AC4D",  # Azul,    alpha 0.30
  "3. La Rioja"   = "#E8521AFF"   # Naranja, alpha 1.00 (énfasis)
)

# Escala de color regional lista para usar en cualquier gráfico
scale_color_larioja <- function(name = "Región", ...) {
  scale_color_manual(name = name, values = COLORES_REGION, ...)
}

scale_fill_larioja <- function(name = "Región", ...) {
  scale_fill_manual(name = name, values = COLORES_REGION, ...)
}

# Paleta secuencial para mapas y variables continuas (azul → naranja)
PALETA_CONTINUA <- c("#2166AC", "#F7F7F7", "#E8521A")

scale_color_larioja_continua <- function(name = "", ...) {
  scale_color_gradientn(colors = PALETA_CONTINUA, name = name, ...)
}

scale_fill_larioja_continua <- function(name = "", ...) {
  scale_fill_gradientn(colors = PALETA_CONTINUA, name = name, ...)
}

# -----------------------------------------------------------------------------
# 2. TEMA BASE
# -----------------------------------------------------------------------------

theme_la_rioja <- function(base_size = 11, legend_position = "right") {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      # Grilla
      panel.grid.major   = element_line(color = "#E5E5E5", linewidth = 0.4),
      panel.grid.minor   = element_blank(),
      panel.background   = element_rect(fill = "white", color = NA),
      plot.background    = element_rect(fill = "white", color = NA),

      # Ejes
      axis.text          = element_text(size = base_size * 0.8, color = "#444444"),
      axis.text.x        = element_text(angle = 45, hjust = 1, size = 7),
      axis.title         = element_text(size = base_size * 0.9, color = "#222222"),
      axis.title.x       = element_text(margin = margin(t = 20)),
      axis.title.y = element_text(margin = margin(r = 8), angle = 90),
      axis.ticks         = element_line(color = "#CCCCCC", linewidth = 0.3),

      # Leyenda
      legend.position    = legend_position,
      legend.title       = element_text(size = base_size * 0.85, face = "bold"),
      legend.text        = element_text(size = base_size * 0.8),
      legend.key.size    = unit(0.9, "lines"),
      legend.background  = element_blank(),

      # Títulos
      plot.title         = element_text(size = base_size * 1.2, face = "bold",
                                        color = "#111111", margin = margin(b = 6)),
      plot.subtitle      = element_text(size = base_size * 0.95, color = "#555555",
                                        margin = margin(b = 10)),
      plot.caption       = element_text(size = base_size * 0.7, color = "#888888",
                                        hjust = 0, margin = margin(t = 8)),
      plot.margin        = margin(12, 16, 8, 12)
    )
}

# Variante para mapas (sin ejes ni grilla)
theme_la_rioja_mapa <- function(base_size = 11, legend_position = "right") {
  theme_la_rioja(base_size = base_size, legend_position = legend_position) %+replace%
    theme(
      axis.text          = element_blank(),
      axis.title         = element_blank(),
      axis.ticks         = element_blank(),
      panel.grid.major   = element_blank(),
      panel.grid.minor   = element_blank()
    )
}

# Activar el tema como default en la sesión
theme_set(theme_la_rioja())

# -----------------------------------------------------------------------------
# 3. PARÁMETROS GEOMÉTRICOS RECOMENDADOS
# -----------------------------------------------------------------------------

GEOM_PARAMS <- list(
  punto = list(size = 1.8, stroke = 0.3),
  barra = list(width = 0.7),
  mapa  = list(color = "white", linewidth = 0.2)
)

# Grosores de línea por región (usados en scale_linewidth_larioja)
LINEWIDTHS_REGION <- c(
  "1. Resto país" = 0.5,
  "2. NOA-Resto"  = 0.8,
  "3. La Rioja"   = 1.2
)

scale_linewidth_larioja <- function(...) {
  scale_linewidth_manual(values = LINEWIDTHS_REGION, guide = "none", ...)
}

# -----------------------------------------------------------------------------
# 4. ORDEN DE DIBUJO
# -----------------------------------------------------------------------------
# Los prefijos numéricos en la clasificación ("1. Resto país", "2. NOA-Resto",
# "3. La Rioja") garantizan que ggplot dibuje La Rioja última y por ende
# encima del resto. No se requiere ninguna transformación adicional.

# -----------------------------------------------------------------------------
# 5. HELPER: construcción rápida de gráfico de líneas regional
# -----------------------------------------------------------------------------
# Un solo geom_line(), sin filtros ni reordenamientos.
#
# Ejemplo de uso directo (sin el helper):
#
# df %>%
#   ggplot(aes(x = fecha, y = tasa_desoc,
#              group = AGLOMERADO,
#              color = la_rioja_region,
#              linewidth = la_rioja_region)) +
#   geom_line() +
#   scale_color_larioja() +
#   scale_linewidth_larioja() +
#   labs(x = "Año-Trimestre", y = "Tasa de desocupación", caption = "Fuente: EPH-INDEC")

grafico_lineas_regional <- function(data,
                                    var_x,
                                    var_y,
                                    var_grupo,
                                    var_region,
                                    titulo    = NULL,
                                    subtitulo = NULL,
                                    eje_x     = "Año-Trimestre",
                                    eje_y     = NULL,
                                    caption   = "Fuente: EPH-INDEC") {

  var_x      <- ensym(var_x)
  var_y      <- ensym(var_y)
  var_grupo  <- ensym(var_grupo)
  var_region <- ensym(var_region)

  ggplot(data, aes(x = !!var_x, y = !!var_y,
                   group = !!var_grupo,
                   color = !!var_region,
                   linewidth = !!var_region)) +
    geom_line() +
    scale_color_larioja() +
    scale_linewidth_larioja() +
    labs(
      title    = titulo,
      subtitle = subtitulo,
      x        = eje_x,
      y        = eje_y,
      caption  = caption
    )
}

# -----------------------------------------------------------------------------
# 6. USO EN RMARKDOWN
# -----------------------------------------------------------------------------
# En el chunk de setup del .Rmd:
#
# ```{r setup, include=FALSE}
# knitr::opts_chunk$set(
#   echo    = FALSE,
#   warning = FALSE,
#   message = FALSE,
#   fig.width  = 10,
#   fig.height = 5.5,
#   dpi        = 150
# )
# source("fundar_larioja_theme.R")
# ```

message("✔ Template FundAr / La Rioja cargado.")
