# Dashboard — Monitor Socioeconómico La Rioja

Dashboard interactivo para explorar los indicadores del proyecto, respetando el
estilo visual del informe (tema `style/fundar_monitor_theme.R`).

## Arquitectura

Un **núcleo de graficado compartido** alimenta **dos front-ends**, para que ambos
muestren exactamente lo mismo sin duplicar lógica:

```
dashboard/
├── R/
│   ├── data.R      # registro de indicadores + carga/tidy de los CSV + KPIs
│   └── plots.R     # plot_indicador(): ggplot fiel al informe + variante plotly
├── app.R           # front-end Shiny (interactivo, filtros ricos)
├── index.qmd       # front-end estático → HTML autocontenido (GitHub Pages)
├── styles.css      # estilo del sitio estático
├── deploy.R        # script de deploy a shinyapps.io
└── deploy.md       # instrucciones de deploy (shinyapps.io + Pages)
```

Ambos front-ends leen los CSV ya versionados de `data/inputs_md/`. No tocan el
pipeline EPH/SIPA: si se recalculan los indicadores, el dashboard toma los nuevos
datos sin cambios.

## Indicadores incluidos

Los 8 indicadores con datos disponibles: tasa de desocupación, tasa de empleo,
informalidad por aportes, educación superior (25+), NBI hogares y NBI población
(con sus 6 sub-dimensiones), puestos asalariados privados (SIPA) y cantidad de
empresas (SRT). Los indicadores pendientes del proyecto tienen lugar reservado en
el registro (`INDICADORES` en `R/data.R`) para sumarse cuando haya datos.

## Correr localmente

### App Shiny

```r
install.packages(c("shiny", "bslib", "bsicons", "plotly", "here"))
shiny::runApp("dashboard")
```

Controles: selección de indicador (agrupado por tópico), toggle de regiones,
rango temporal, sub-dimensión NBI, switch **"Gráfico interactivo"** (ggplot fiel
↔ plotly) y descarga de PNG/CSV.

### Sitio estático

```bash
quarto render dashboard/index.qmd
```

Genera `dashboard/index.html` autocontenido (abrible directo en el navegador).

## Deploy online

Ver [`deploy.md`](deploy.md): app Shiny a shinyapps.io (`Rscript dashboard/deploy.R`)
y sitio estático a GitHub Pages (workflow `.github/workflows/dashboard.yml`).

## Cómo agregar un indicador

1. Agregar su CSV a `data/inputs_md/` (vía el pipeline).
2. Sumar una entrada a `INDICADORES` en `R/data.R` (id, título, tópico, CSV,
   columna de valor, etiquetas, `shape` A/B, `ylim`).
3. Listo: aparece solo en la app y en el sitio estático.
