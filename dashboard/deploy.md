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

> **Estado actual:** el workflow ya corre y publica. La rama `gh-pages` existe y
> contiene el `index.html` renderizado (autocontenido, sin recursos externos). Lo
> único que falta para que el sitio quede accesible es **activar Pages** (checklist
> abajo) — es un paso manual en la configuración del repo, no se puede automatizar.

### Activar Pages (una sola vez) — checklist

- [ ] Ir a **Settings → Pages** del repo en GitHub.
- [ ] En **Source**, elegir **Deploy from a branch**.
- [ ] Branch: **`gh-pages`**, carpeta **`/ (root)`** → **Save**.
- [ ] Esperar 1–2 min la primera vez y abrir la URL:
      **`https://gefero.github.io/fundar_la_rioja/`**.
- [ ] Verificar que carga el dashboard (no un 404 "There isn't a GitHub Pages site here").

Una vez activado, no hay que volver a tocar nada: cada push a `main` que toque
`dashboard/**`, `data/inputs_md/**` o `style/**` regenera y republica el sitio solo.
Si un render llegara a fallar, el sitio live **no se pisa** (la acción de deploy sólo
publica cuando el render tuvo éxito).

### Comprobar que el workflow corrió

En la pestaña **Actions** del repo, el workflow *"Dashboard estático (GitHub Pages)"*
debe figurar en verde para el último commit. También se puede confirmar desde la
terminal que `gh-pages` apunta al deploy del `main` actual:

```bash
git fetch origin gh-pages main
git log --oneline -1 origin/gh-pages   # "deploy: <sha del main actual>"
```

### Render local (para previsualizar)

```bash
quarto render dashboard/index.qmd
```

Genera `dashboard/index.html` autocontenido (un solo archivo, sin dependencias
externas). Se puede abrir directo en el navegador.

> `docs/` está en `.gitignore` (regla de pkgdown), por eso el sitio se publica en
> la rama `gh-pages` y no en `/docs`. Si se prefiere `/docs`, quitar esa línea del
> `.gitignore` y ajustar el workflow.
