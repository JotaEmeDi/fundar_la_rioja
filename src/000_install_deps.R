# Instala dependencias del repo (paquetes R + opcional TinyTeX para PDF).
# Correr una vez por máquina / cuando falte un paquete. No forma parte del RMD.
#
# Uso (desde la raíz del repo):
#   source("src/000_install_deps.R")
#   source("src/000_install_deps.R"); install_project_deps(dashboard = TRUE, pdf = TRUE)
#
# Fallos esperables:
# - Sin internet / CRAN caído → install.packages falla.
# - TinyTeX: descarga grande; puede pedir reiniciar la sesión de R.

install_project_deps <- function(
  pipeline = TRUE,
  informe = TRUE,
  dashboard = FALSE,
  pdf = FALSE,
  repos = getOption("repos", c(CRAN = "https://cloud.r-project.org"))
) {
  pkgs <- character()
  if (isTRUE(pipeline)) {
    pkgs <- c(
      pkgs,
      "eph", "tidyverse", "lubridate", "tictoc", "readxl",
      "janitor", "ggrepel", "treemapify", "stringi", "jsonlite",
      "seasonal", "x13binary"
    )
  }
  if (isTRUE(informe)) {
    pkgs <- c(pkgs, "rmarkdown", "knitr", "here", "readr", "dplyr", "tufte")
  }
  if (isTRUE(dashboard)) {
    pkgs <- c(pkgs, "shiny", "bslib", "bsicons", "plotly", "rsconnect")
  }
  if (isTRUE(pdf)) {
    pkgs <- c(pkgs, "tinytex")
  }

  pkgs <- unique(pkgs)
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    message("Instalando: ", paste(missing, collapse = ", "))
    install.packages(missing, repos = repos)
  } else {
    message("Paquetes R: OK (", length(pkgs), " revisados).")
  }

  if (isTRUE(pdf)) {
    if (!requireNamespace("tinytex", quietly = TRUE)) {
      stop("No se pudo cargar tinytex tras la instalación.")
    }
    has_pdflatex <- nzchar(Sys.which("pdflatex"))
    tinytex_ok <- isTRUE(tryCatch(tinytex::is_tinytex(), error = function(e) FALSE))
    if (!has_pdflatex && !tinytex_ok) {
      message("Instalando TinyTeX (LaTeX). Puede tardar varios minutos…")
      tinytex::install_tinytex()
    }
    has_pdflatex <- nzchar(Sys.which("pdflatex")) ||
      isTRUE(tryCatch(tinytex::is_tinytex(), error = function(e) FALSE))
    if (!has_pdflatex) {
      warning(
        "pdflatex sigue sin encontrarse. Reiniciá R y volvé a chequear ",
        "con Sys.which(\"pdflatex\"), o instalá MiKTeX."
      )
    } else {
      message("LaTeX / pdflatex: disponible para knit a PDF.")
    }
  }

  invisible(NULL)
}

# Al source()-ar: instala pipeline + informe (sin dashboard ni TinyTeX).
install_project_deps()
