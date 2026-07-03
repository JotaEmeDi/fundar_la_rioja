# =============================================================================
# Deploy de la app Shiny a shinyapps.io
# -----------------------------------------------------------------------------
# La app vive en dashboard/, pero necesita los CSV (data/inputs_md/) y el tema
# (style/), que están fuera de esa carpeta. Este script "bundlea" copias dentro
# de dashboard/ y despliega SÓLO dashboard/ (self-contained), sin arrastrar los
# microdatos crudos de data/raw_data/.
#
# Requisitos previos (una sola vez):
#   install.packages("rsconnect")
#   rsconnect::setAccountInfo(name = "<cuenta>", token = "<token>", secret = "<secret>")
#   (los datos de la cuenta se sacan de https://www.shinyapps.io/ -> Account -> Tokens)
#
# Uso:  Rscript dashboard/deploy.R
# =============================================================================

app_dir   <- "dashboard"
root       <- normalizePath(".")
data_src   <- file.path(root, "data", "inputs_md")
style_src  <- file.path(root, "style")
data_dst   <- file.path(app_dir, "data_inputs")
style_dst  <- file.path(app_dir, "style")

# 1. Copiar los CSV agregados y los archivos de estilo dentro del bundle.
dir.create(data_dst,  showWarnings = FALSE, recursive = TRUE)
dir.create(style_dst, showWarnings = FALSE, recursive = TRUE)
file.copy(list.files(data_src,  full.names = TRUE), data_dst,  overwrite = TRUE)
file.copy(list.files(style_src, full.names = TRUE), style_dst, overwrite = TRUE)

# 2. Desplegar sólo la carpeta de la app (con las copias bundleadas).
#    data.R detecta esas copias y las usa en lugar del árbol del repo.
rsconnect::deployApp(
  appDir      = app_dir,
  appName     = "monitor-la-rioja",
  appTitle    = "Monitor Socioeconómico La Rioja",
  appFiles    = c("app.R", "R", "data_inputs", "style"),
  forceUpdate = TRUE
)
