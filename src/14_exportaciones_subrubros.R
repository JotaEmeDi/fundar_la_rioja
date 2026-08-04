## 14. Exportaciones por subrubro (OPEX): treemap 2025 y heatmap La Rioja.

library(tidyverse)
library(treemapify)
library(ggrepel)
source("./style/fundar_monitor_theme.R")

df <- read_csv(
  "./data/inputs_md/14_exportaciones_subrubros_region.csv",
  show_col_types = FALSE
)

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

ANIO_TREEMAP <- 2025L
ANIOS_HEAT <- 2015:2025

## Etiquetas cortas para que el treemap sea legible.
acortar_subrubro <- function(x) {
  x %>%
    str_replace("^Preparados de hortalizas, legumbres y frutas$", "Preparados hort./frutas") %>%
    str_replace("^Papel, cartón, impresos y publicaciones$", "Papel y cartón") %>%
    str_replace("^Bebidas, líquidos alcohólicos y vinagre$", "Bebidas") %>%
    str_replace("^Productos químicos y conexos$", "Químicos") %>%
    str_replace("^Semillas y frutos oleaginosos$", "Oleaginosos") %>%
    str_replace("^Resto de productos$", "Resto") %>%
    str_replace("^Frutas secas o procesadas$", "Frutas secas/proc.") %>%
    str_replace("^Frutas frescas$", "Frutas frescas") %>%
    str_replace("^Textiles y confecciones$", "Textiles") %>%
    str_replace("^Grasas y aceites$", "Grasas y aceites") %>%
    str_replace("^Pieles y cueros$", "Pieles y cueros") %>%
    str_replace("^Materias plásticas y sus manufacturas$", "Plásticos") %>%
    str_replace("^Otros$", "Otros") %>%
    str_replace("^Otros detallados$", "Otros") %>%
    str_replace("^No desagregado$", "No desagregado") %>%
    str_trunc(28, ellipsis = "…")
}

## -------- Treemap 2025: La Rioja / NOA-Resto / Resto país --------
## Principales subrubros; ítems con share < 4% se agrupan en "Otros"
## (en La Rioja evita celdas mínimas que treemapify dibuja sin texto).
df_pub <- df %>%
  filter(
    anio == ANIO_TREEMAP,
    !is.na(exportaciones_millones_usd),
    exportaciones_millones_usd > 0
  )

totales_tm <- df %>%
  filter(anio == ANIO_TREEMAP) %>%
  distinct(la_rioja_region, total_grupo_millones_usd)

df_tm <- df_pub %>%
  group_by(la_rioja_region) %>%
  mutate(
    rank = row_number(desc(exportaciones_millones_usd)),
    subrubro_plot = case_when(
      subrubro == "Resto de productos" ~ "Resto de productos",
      share_pct < 4 ~ "Otros",
      rank <= 8 ~ subrubro,
      TRUE ~ "Otros"
    )
  ) %>%
  group_by(la_rioja_region, subrubro_plot) %>%
  summarise(
    exportaciones_millones_usd = sum(exportaciones_millones_usd),
    share_pct = sum(share_pct),
    .groups = "drop"
  )

residual <- df_tm %>%
  group_by(la_rioja_region) %>%
  summarise(publicado = sum(exportaciones_millones_usd), .groups = "drop") %>%
  left_join(totales_tm, by = "la_rioja_region") %>%
  mutate(
    exportaciones_millones_usd = pmax(total_grupo_millones_usd - publicado, 0),
    share_pct = 100 * exportaciones_millones_usd / total_grupo_millones_usd,
    subrubro_plot = "No desagregado"
  ) %>%
  filter(exportaciones_millones_usd > 0.05) %>%
  select(la_rioja_region, subrubro_plot, exportaciones_millones_usd, share_pct)

df_tm <- bind_rows(df_tm, residual) %>%
  mutate(
    label = paste0(
      acortar_subrubro(subrubro_plot), "\n",
      format(round(share_pct, 1), decimal.mark = ","), "%"
    )
  )

p_tm <- df_tm %>%
  ggplot(aes(
    area = exportaciones_millones_usd,
    fill = share_pct,
    label = label,
    subgroup = la_rioja_region
  )) +
  geom_treemap(color = "white", size = 1.5) +
  geom_treemap_subgroup_border(color = FUNDAR_TEXTO, size = 2) +
  geom_treemap_text(
    colour = FUNDAR_TEXTO,
    place = "centre",
    grow = FALSE,
    reflow = TRUE,
    size = 10,
    min.size = 0
  ) +
  geom_treemap_subgroup_text(
    colour = FUNDAR_TEXTO,
    place = "topleft",
    grow = FALSE,
    size = 12,
    fontface = "bold",
    padding.x = grid::unit(2, "mm"),
    padding.y = grid::unit(2, "mm")
  ) +
  scale_fill_gradient(
    name = "Share (%)",
    low = "#A8DCC8",
    high = "#2D6E6E"
  ) +
  theme_monitor() +
  theme(legend.position = "right") +
  labs(
    title = paste0("Composición de las exportaciones por subrubro · ", ANIO_TREEMAP),
    subtitle = "La Rioja / NOA-Resto / Resto país · millones de USD (OPEX-INDEC)",
    caption = fuente_fundar(
      paste0(
        "Fundar, con base en OPEX-INDEC. Solo principales subrubros publicados; ",
        "el residual agrupa el resto. Ausencia ≠ exportación nula."
      )
    )
  )

ggsave(
  "./outputs/plots/14_exportaciones_treemap_subrubros.png",
  p_tm,
  width = 14,
  height = 9
)

## Treemaps facetados (más claros para presentar por grupo).
p_tm_facet <- df_tm %>%
  ggplot(aes(
    area = exportaciones_millones_usd,
    fill = share_pct,
    label = label
  )) +
  geom_treemap(color = "white", size = 1.2) +
  geom_treemap_text(
    colour = FUNDAR_TEXTO,
    place = "centre",
    grow = FALSE,
    reflow = TRUE,
    size = 9,
    min.size = 0
  ) +
  facet_wrap(~la_rioja_region, nrow = 1) +
  scale_fill_gradient(name = "Share (%)", low = "#A8DCC8", high = "#2D6E6E") +
  theme_monitor() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  ) +
  labs(
    title = paste0("Composición exportadora por subrubro · ", ANIO_TREEMAP),
    subtitle = "Participación % dentro de cada grupo · OPEX-INDEC (principales subrubros)",
    caption = fuente_fundar(
      paste0(
        "Fundar, con base en OPEX-INDEC. Solo principales subrubros publicados; ",
        "\"No desagregado\" = total del grupo menos la suma de subrubros con monto ",
        "(confidencialidad / no publicado). Ítems < 4% se agrupan en \"Otros\"."
      )
    )
  )

ggsave(
  "./outputs/plots/14_exportaciones_treemap_subrubros_facet.png",
  p_tm_facet,
  width = 16,
  height = 7
)

## -------- Heatmap La Rioja 2015-2025 (share %) --------
df_heat <- df %>%
  filter(
    la_rioja_region == "3. La Rioja",
    anio %in% ANIOS_HEAT
  ) %>%
  mutate(subrubro_corto = acortar_subrubro(subrubro))

## Orden de filas: productos por share promedio (solo años con dato).
orden_prod <- df_heat %>%
  group_by(subrubro_corto) %>%
  summarise(share_medio = mean(share_pct, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(share_medio)) %>%
  pull(subrubro_corto)

df_heat <- df_heat %>%
  mutate(subrubro_corto = factor(subrubro_corto, levels = rev(orden_prod)))

p_heat <- df_heat %>%
  ggplot(aes(x = anio, y = subrubro_corto, fill = share_pct)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(
    aes(label = ifelse(
      is.na(share_pct),
      "",
      format(round(share_pct, 0), decimal.mark = ",")
    )),
    size = 2.8,
    color = FUNDAR_TEXTO
  ) +
  scale_x_continuous(breaks = ANIOS_HEAT) +
  scale_fill_gradient(
    name = "Share (%)",
    low = "#EDE8E0",
    high = "#2D6E6E",
    na.value = "#F5F5F5"
  ) +
  theme_monitor() +
  theme(
    panel.grid = element_blank(),
    axis.text.y = element_text(size = 9),
    legend.position = "right"
  ) +
  labs(
    title = "La Rioja: participación de los principales subrubros exportados",
    subtitle = "Share % del total provincial · 2015-2025 · celdas vacías = no publicado ese año",
    x = "Año",
    y = NULL,
    caption = fuente_fundar(
      paste0(
        "Fundar, con base en OPEX-INDEC. La fuente publica solo los principales ",
        "subrubros de cada año; la ausencia no implica exportaciones nulas."
      )
    )
  )

ggsave(
  "./outputs/plots/14_exportaciones_heatmap_larioja.png",
  p_heat,
  width = 13,
  height = 8
)

## -------- Evolución de montos totales (millones USD) 2015-2025 --------
## Facetas con ejes libres: La Rioja es un orden de magnitud menor que
## Resto país; un único eje comprimiría su serie.
df_tot <- df %>%
  filter(anio %in% ANIOS_HEAT) %>%
  distinct(anio, la_rioja_region, total_grupo_millones_usd, provisorio) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

key_tot <- df_tot %>%
  group_by(la_rioja_region) %>%
  filter(anio == max(anio)) %>%
  ungroup() %>%
  mutate(
    label = paste0(
      format(round(total_grupo_millones_usd), big.mark = ".", decimal.mark = ",",
             scientific = FALSE),
      " MUSD"
    )
  )

p_tot <- df_tot %>%
  ggplot(aes(
    x = anio,
    y = total_grupo_millones_usd,
    group = la_rioja_region,
    color = la_rioja_region
  )) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_point(data = key_tot, size = 2.5, show.legend = FALSE) +
  geom_text_repel(
    data = key_tot,
    aes(label = label),
    size = 3,
    fontface = "bold",
    show.legend = FALSE,
    min.segment.length = 0,
    box.padding = 0.4,
    max.overlaps = Inf,
    seed = 42
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y", nrow = 1) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_continuous(breaks = ANIOS_HEAT) +
  scale_y_continuous(
    labels = scales::label_number(big.mark = ".", decimal.mark = ","),
    expand = expansion(mult = c(0.05, 0.18))
  ) +
  theme_monitor() +
  theme(
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "none"
  ) +
  labs(
    title = "Exportaciones totales en millones de dólares",
    subtitle = "2015-2025 · suma de provincias de cada grupo · OPEX-INDEC",
    x = "Año",
    y = "Millones de USD",
    caption = fuente_fundar(
      "Fundar, con base en OPEX-INDEC. Montos corrientes en dólares. 2024-2025 provisorios."
    )
  )

ggsave(
  "./outputs/plots/14_exportaciones_totales_region.png",
  p_tot,
  width = 14,
  height = 6
)

message("Gráficos en outputs/plots/14_exportaciones_*.png")
