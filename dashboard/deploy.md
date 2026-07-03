# Deploy del dashboard

El dashboard tiene dos formas de correr online, ambas desde el mismo núcleo de
graficado (`R/data.R` + `R/plots.R`):

1. **App Shiny interactiva** → shinyapps.io (servidor R, filtros ricos).
2. **Sitio HTML estático** → GitHub Pages (sin servidor, interactividad plotly).

---

## 1. App Shiny en shinyapps.io

### Preparar la cuenta (una sola vez)

1. Crear una cuenta gratuita en <https://www.shinyapps.io/>.
2. En **Account → Tokens**, copiar el bloque `setAccountInfo(...)`.
3. En R:

   ```r
   install.packages("rsconnect")
   rsconnect::setAccountInfo(name = "<cuenta>", token = "<token>", secret = "<secret>")
   ```

### Desplegar

Desde la **raíz del repo**:

```bash
Rscript dashboard/deploy.R
```

`deploy.R` copia los CSV de `data/inputs_md/` y el tema de `style/` dentro de
`dashboard/` (como `data_inputs/` y `style/`) y despliega **sólo** esa carpeta,
así el bundle es liviano y no incluye los microdatos crudos. `R/data.R` detecta
esas copias automáticamente. La app queda en
`https://<cuenta>.shinyapps.io/monitor-la-rioja/`.

> El tier gratuito de shinyapps.io permite 5 apps y 25 horas activas/mes, suficiente
> para difusión. Para uso institucional intensivo, considerar Posit Connect o un
> servidor Shiny propio.

---

## 2. Sitio estático en GitHub Pages

El workflow `.github/workflows/dashboard.yml` renderiza `dashboard/index.qmd` a
un HTML autocontenido y lo publica en la rama `gh-pages` en cada push a `main`
que toque el dashboard o los datos.

### Activar Pages (una sola vez)

En **Settings → Pages** del repo en GitHub, elegir **Source: Deploy from a branch**
y seleccionar la rama `gh-pages` (carpeta `/root`). La URL queda como
`https://<usuario>.github.io/fundar_la_rioja/`.

### Render local (para previsualizar)

```bash
quarto render dashboard/index.qmd
```

Genera `dashboard/index.html` autocontenido (un solo archivo, sin dependencias
externas). Se puede abrir directo en el navegador.

> `docs/` está en `.gitignore` (regla de pkgdown), por eso el sitio se publica en
> la rama `gh-pages` y no en `/docs`. Si se prefiere `/docs`, quitar esa línea del
> `.gitignore` y ajustar el workflow.
