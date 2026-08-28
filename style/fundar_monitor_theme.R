# =============================================================================
# TEMA FUNDAR — Monitor Mensual de Empresas
# Replica el estilo visual del Monitor Mensual de Empresas de Fundar
# Referencia: fund.ar/publicacion/monitor-mensual-de-empresas/
# =============================================================================
# Uso: source("style/fundar_monitor_theme.R") al inicio de cada script o chunk

library(ggplot2)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. PALETA DE COLORES
# -----------------------------------------------------------------------------

# Colores institucionales Fundar
FUNDAR_VERDE    <- "#52C8A0"   # Verde menta — color principal / positivo
FUNDAR_ROSA     <- "#F4877A"   # Rosa salmón — negativo / caídas
FUNDAR_BEIGE    <- "#EDE8E0"   # Fondo de área de gráfico
FUNDAR_OSCURO   <- "#1C1C1C"   # Fondo oscuro (slides de KPIs)
FUNDAR_GRIS     <- "#888888"   # Texto secundario / subtítulos
FUNDAR_GRILLA   <- "#D5D0C8"   # Líneas de grilla horizontales
FUNDAR_TEXTO    <- "#1C1C1C"   # Texto principal

# Paleta para series múltiples (gráficos de comparación entre períodos)
FUNDAR_MULTI <- c(
  "serie_1" = "#A8DCC8",   # Verde menta claro  → 1. Resto país
  "serie_2" = "#C8C87A",   # Amarillo oliva     → 2. NOA-Resto
  "serie_3" = "#2D6E6E",   # Verde azulado oscuro → 3. La Rioja (énfasis)
  "serie_4" = "#F4877A",   # Rosa salmón
  "serie_5" = "#9B8BC4"    # Violeta
)

# Paleta por SECTOR (indicador de salarios EPH público/privado). Reusa dos colores
# base de la paleta regional: Privado = color de "Resto país" (verde menta claro),
# Público = color de "NOA-Resto" (amarillo oliva).
FUNDAR_SECTOR <- c(
  "Privado" = unname(FUNDAR_MULTI["serie_1"]),
  "Público" = unname(FUNDAR_MULTI["serie_2"])
)

# Escala de color positivo/negativo (para barras divergentes)
scale_fill_fundar_div <- function(
    pos_label = "Positivo",
    neg_label = "Negativo",
    name = NULL, ...) {
  scale_fill_manual(
    name   = name,
    values = c("pos" = FUNDAR_VERDE, "neg" = FUNDAR_ROSA),
    labels = c("pos" = pos_label,   "neg" = neg_label),
    ...
  )
}

# Escala de color para series múltiples
scale_color_fundar_multi <- function(name = NULL, ...) {
  scale_color_manual(name = name, values = unname(FUNDAR_MULTI), ...)
}

scale_fill_fundar_multi <- function(name = NULL, ...) {
  scale_fill_manual(name = name, values = unname(FUNDAR_MULTI), ...)
}

# Escala de color para una sola serie (verde institucional)
scale_color_fundar <- function(name = NULL, ...) {
  scale_color_manual(name = name, values = FUNDAR_VERDE, ...)
}

# -----------------------------------------------------------------------------
# 2. TEMA BASE
# -----------------------------------------------------------------------------

theme_monitor <- function(base_size = 12,
                         legend_position = "top",
                         fondo_beige = TRUE) {

  bg_color <- if (fondo_beige) FUNDAR_BEIGE else "white"

  theme_minimal(base_size = base_size) %+replace%
    theme(
      # Área del gráfico
      panel.background   = element_rect(fill = bg_color, color = NA),
      plot.background    = element_rect(fill = "white",  color = NA),

      # Grilla: solo horizontal, muy suave
      panel.grid.major.y = element_line(color = FUNDAR_GRILLA, linewidth = 0.4),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),

      # Ejes
      axis.text          = element_text(size  = base_size * 0.75,
                                        color = "#555555"),
      axis.text.x        = element_text(margin = margin(t = 4), angle = 45, hjust = 1),
      axis.text.y        = element_text(margin = margin(r = 4)),
      axis.title         = element_text(size  = base_size * 0.85,
                                        color = FUNDAR_TEXTO),
      axis.title.x       = element_text(margin = margin(t = 20)),
      axis.title.y       = element_text(margin = margin(r = 10), angle = 90),
      axis.ticks         = element_blank(),
      axis.line          = element_blank(),

      # Leyenda — horizontal arriba, sin caja
      legend.position    = legend_position,
      legend.direction   = "horizontal",
      legend.title       = element_blank(),
      legend.text        = element_text(size = base_size * 0.8, color = FUNDAR_TEXTO),
      legend.key.size    = unit(0.8, "lines"),
      legend.background  = element_blank(),
      legend.key         = element_blank(),
      legend.margin      = margin(b = 6),

      # Títulos
      plot.title         = element_text(
        size   = base_size * 1.5,
        face   = "bold",
        color  = FUNDAR_TEXTO,
        hjust  = 0,
        margin = margin(b = 4)
      ),
      plot.subtitle      = element_text(
        size   = base_size * 0.95,
        color  = FUNDAR_GRIS,
        hjust  = 0,
        margin = margin(b = 12)
      ),
      plot.caption       = element_text(
        size   = base_size * 0.95,
        color  = FUNDAR_GRIS,
        hjust  = 0,
        margin = margin(t = 10)
      ),
      plot.caption.position = "plot",
      plot.margin        = margin(16, 20, 20, 16),
      plot.title.position   = "plot"
    )
}

# Variante con fondo oscuro (para slides de KPIs / portada)
theme_monitor_oscuro <- function(base_size = 12, legend_position = "top") {
  theme_monitor(base_size = base_size,
               legend_position = legend_position,
               fondo_beige = FALSE) %+replace%
    theme(
      panel.background = element_rect(fill = FUNDAR_OSCURO, color = NA),
      plot.background  = element_rect(fill = FUNDAR_OSCURO, color = NA),
      panel.grid.major.y = element_line(color = "#333333", linewidth = 0.4),
      axis.text        = element_text(color = "#CCCCCC", size = base_size * 0.75),
      axis.title       = element_text(color = "#CCCCCC"),
      plot.title       = element_text(color = "white",  face = "bold",
                                      size  = base_size * 1.5, hjust = 0,
                                      margin = margin(b = 4)),
      plot.subtitle    = element_text(color = "#AAAAAA", hjust = 0,
                                      size  = base_size * 0.95,
                                      margin = margin(b = 12)),
      plot.caption     = element_text(color = "#888888"),
      legend.text      = element_text(color = "#CCCCCC")
    )
}

# Variante para gráficos de barras horizontales (sin grilla vertical,
# grilla vertical suave en su lugar para leer valores)
theme_monitor_barras_h <- function(base_size = 12) {
  theme_monitor(base_size = base_size) %+replace%
    theme(
      panel.grid.major.x = element_line(color = FUNDAR_GRILLA, linewidth = 0.4),
      panel.grid.major.y = element_blank(),
      axis.text.y        = element_text(size  = base_size * 0.72,
                                        color = FUNDAR_TEXTO,
                                        hjust = 1)
    )
}

# Activar el tema como default en la sesión
theme_set(theme_monitor())

# -----------------------------------------------------------------------------
# 3. HELPER: etiqueta de fuente en formato Fundar
# -----------------------------------------------------------------------------
# Fundar usa "Fuente:" en negrita seguido del texto en regular.
# En ggplot2 esto se logra con caption y richtext (ggtext) o simplemente
# con el texto plano como se muestra abajo.
#
# Uso: labs(caption = fuente_fundar("Fundar, con base en datos de SRT."))

fuente_fundar <- function(texto) {
  paste0("Fuente: ", texto)
}

# -----------------------------------------------------------------------------
# 3b. HELPER: puntos de etiqueta (máximo, mínimo y último por grupo)
# -----------------------------------------------------------------------------
# Devuelve un dataframe con las filas correspondientes al máximo, mínimo
# y último valor de var_y dentro de cada grupo (var_grupo).
# Diseñado para pasarse a geom_text() / geom_label().
#
# Uso:
#   pts <- puntos_etiqueta(df, fecha, tasa_desoc, AGLOMERADO)
#   ... + geom_text(data = pts, aes(label = round(tasa_desoc, 1)), size = 2.5)

puntos_etiqueta <- function(data, var_x, var_y, var_grupo) {
  var_x     <- ensym(var_x)
  var_y     <- ensym(var_y)
  var_grupo <- ensym(var_grupo)

  data %>%
    filter(!is.na(!!var_y)) %>%
    group_by(!!var_grupo) %>%
    mutate(
      .es_ultimo = !!var_x == max(!!var_x, na.rm = TRUE),
      .es_max    = !!var_y == max(!!var_y, na.rm = TRUE),
      .es_min    = !!var_y == min(!!var_y, na.rm = TRUE)
    ) %>%
    filter(.es_ultimo | .es_max | .es_min) %>%
    mutate(
      .hjust = if_else(.es_ultimo, 1.2, 0.5),
      .vjust = if_else(.es_ultimo, 0.5, -0.8)
    ) %>%
    ungroup() %>%
    select(-.es_ultimo, -.es_max, -.es_min) %>%
    distinct()
}

# -----------------------------------------------------------------------------
# 4. HELPER: gráfico de línea simple estilo Monitor
# -----------------------------------------------------------------------------
# Replica el estilo de la página "¿Cuántas empresas hay en Argentina?"
# Una sola serie en verde menta, con punto de énfasis en el último valor.
#
# Ejemplo de uso:
#
# df %>%
#   grafico_linea_monitor(
#     var_x     = fecha,
#     var_y     = n_empresas,
#     titulo    = "¿Cuántas empresas hay en Argentina?",
#     eje_y     = NULL,
#     caption   = fuente_fundar("Fundar, con base en datos de SRT.")
#   )

grafico_linea_monitor <- function(data,
                                  var_x,
                                  var_y,
                                  titulo    = NULL,
                                  subtitulo = NULL,
                                  eje_x     = NULL,
                                  eje_y     = NULL,
                                  caption   = NULL) {
  var_x <- ensym(var_x)
  var_y <- ensym(var_y)

  ultimo <- data %>% slice_tail(n = 1)

  ggplot(data, aes(x = !!var_x, y = !!var_y)) +
    geom_line(color = FUNDAR_VERDE, linewidth = 0.9) +
    geom_point(data = ultimo,
               aes(x = !!var_x, y = !!var_y),
               color = FUNDAR_VERDE, size = 3, shape = 16) +
    labs(title    = titulo,
         subtitle = subtitulo,
         x        = eje_x,
         y        = eje_y,
         caption  = caption)
}

# -----------------------------------------------------------------------------
# 5. HELPER: barras horizontales divergentes estilo Monitor
# -----------------------------------------------------------------------------
# Replica los gráficos de variación por sector/provincia.
# Espera una columna `valor` numérica y una columna `etiqueta` de texto.
# Colorea automáticamente verde (positivo) / rosa (negativo).
#
# Ejemplo de uso:
#
# df %>%
#   mutate(signo = if_else(valor >= 0, "pos", "neg")) %>%
#   grafico_barras_div(
#     var_y   = sector,
#     var_x   = valor,
#     var_sig = signo,
#     titulo  = "Variación porcentual por sector"
#   )

grafico_barras_div <- function(data,
                               var_y,
                               var_x,
                               var_sig,
                               titulo    = NULL,
                               subtitulo = NULL,
                               caption   = NULL) {
  var_y   <- ensym(var_y)
  var_x   <- ensym(var_x)
  var_sig <- ensym(var_sig)

  ggplot(data, aes(x = !!var_x,
                   y = reorder(!!var_y, !!var_x),
                   fill = !!var_sig)) +
    geom_col(width = 0.7, show.legend = FALSE) +
    geom_vline(xintercept = 0, color = FUNDAR_TEXTO, linewidth = 0.4) +
    scale_fill_manual(values = c("pos" = FUNDAR_VERDE, "neg" = FUNDAR_ROSA)) +
    geom_text(aes(label  = scales::percent(!!var_x / 100, accuracy = 0.01),
                  hjust  = if_else(!!var_x >= 0, -0.1, 1.1)),
              size  = 3,
              color = FUNDAR_TEXTO) +
    labs(title    = titulo,
         subtitle = subtitulo,
         x        = NULL,
         y        = NULL,
         caption  = caption) +
    theme_monitor_barras_h()
}

message("✔ Tema Fundar Monitor cargado.")
