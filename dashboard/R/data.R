# =============================================================================
# NÚCLEO DE DATOS DEL DASHBOARD
# -----------------------------------------------------------------------------
# Carga los CSV agregados de data/inputs_md/, los normaliza a una forma larga
# uniforme (fecha, fecha_lab, la_rioja_region, valor) y expone un registro
# único de indicadores (INDICADORES). Es la fuente de verdad consumida tanto
# por la app Shiny (dashboard/app.R) como por el export estático
# (dashboard/index.qmd), para que ambos front-ends muestren exactamente lo
# mismo sin duplicar lógica.
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# -----------------------------------------------------------------------------
# Resolución de rutas
# -----------------------------------------------------------------------------
# Se busca la raíz del repo por el archivo .Rproj para que las rutas funcionen
# igual corriendo local desde RStudio, con shiny::runApp("dashboard"), o
# desplegado en shinyapps.io (donde el working dir es la carpeta desplegada).
.find_root <- function() {
  if (requireNamespace("here", quietly = TRUE)) {
    r <- tryCatch(here::here(), error = function(e) NA_character_)
    if (!is.na(r) && file.exists(file.path(r, "fundar_larioja.Rproj"))) return(r)
  }
  d <- normalizePath(getwd(), mustWork = FALSE)
  while (!file.exists(file.path(d, "fundar_larioja.Rproj")) && dirname(d) != d) {
    d <- dirname(d)
  }
  d
}

.first_existing <- function(paths) {
  for (p in paths) if (dir.exists(p)) return(p)
  paths[[length(paths)]]   # último como fallback aunque no exista todavía
}

.ROOT    <- .find_root()
.APP_DIR <- normalizePath(getwd(), mustWork = FALSE)  # dashboard/ al correr la app

# Se priorizan copias "bundleadas" dentro de la carpeta de la app (las crea el
# deploy a shinyapps.io, ver dashboard/deploy.md); si no existen (dev local o
# render de Quarto), se usan las del árbol del repo. Un único origen de datos:
# no se duplica nada en el repo, sólo en el bundle desplegado.
DATA_DIR  <- .first_existing(c(file.path(.APP_DIR, "data_inputs"),
                               file.path(.ROOT, "data", "inputs_md")))
STYLE_DIR <- .first_existing(c(file.path(.APP_DIR, "style"),
                               file.path(.ROOT, "style")))

# Declara bytes UTF-8 como tales (sin re-encodear). Los CSV se leen como UTF-8,
# pero los literales acentuados de este archivo pueden quedar marcados como
# "unknown"; en un locale C eso hace que "1. Resto país" no matchee contra el
# dato aunque los bytes sean idénticos. Marcarlos UTF-8 los vuelve comparables
# en cualquier locale (los archivos de este repo están guardados en UTF-8).
.utf8 <- function(x) { Encoding(x) <- "UTF-8"; x }

# -----------------------------------------------------------------------------
# Helpers de fecha y región
# -----------------------------------------------------------------------------

# "2007-Q3" -> Date del primer día del trimestre (2007-07-01). Permite ordenar
# y filtrar por rango temporal; la etiqueta original se conserva aparte.
parse_trimestre <- function(x) {
  ano <- as.integer(str_sub(x, 1, 4))
  q   <- as.integer(str_sub(x, 7, 7))
  as.Date(sprintf("%04d-%02d-01", ano, (q - 1L) * 3L + 1L))
}

# Provincias del NOA (mismo criterio que src/05_*.R y src/07_*.R).
NOA_PROVINCIAS <- .utf8(c("Catamarca", "Jujuy", "Salta",
                          "Santiago del Estero", "Tucumán", "La Rioja"))

# Clasifica una columna `jurisdiccion` en las 3 regiones canónicas del proyecto.
asignar_region_provincia <- function(df) {
  df %>%
    mutate(la_rioja_region = case_when(
      jurisdiccion == "La Rioja" ~ "3. La Rioja",
      jurisdiccion %in% NOA_PROVINCIAS ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    ))
}

REGIONES <- .utf8(c("1. Resto país", "2. NOA-Resto", "3. La Rioja"))

# -----------------------------------------------------------------------------
# Registro de indicadores
# -----------------------------------------------------------------------------
# shape "A" = serie trimestral regional de la EPH (una fila por fecha-región).
# shape "B" = serie mensual provincial (SIPA/SRT), se agrega a nivel región.
# shape "C" = serie trimestral regional de la EPH con 2 series por SECTOR
#             (público/privado) y valores en pesos; se facetea por región.
# `dimensiones` (solo NBI) mapea código -> columna del CSV; `dim_labels` su texto.

INDICADORES <- list(
  desocupacion = list(
    id = "desocupacion", titulo = "Tasa de desocupación",
    topico = "Trabajo e ingresos", csv = "04_tasa_desoc.csv",
    y_var = "tasa_desoc", y_lab = "Tasa de desocupación (%)",
    eje_x = "Año", caption = "EPH-INDEC", ylim = c(0, 20), shape = "A",
    desc = "Desocupados como % de la Población Económicamente Activa (PEA)."
  ),
  empleo = list(
    id = "empleo", titulo = "Tasa de empleo",
    topico = "Trabajo e ingresos", csv = "10_tasa_empleo.csv",
    y_var = "tasa_empleo", y_lab = "Ocupados cada 100 hab. (%)",
    eje_x = "Año", caption = "EPH-INDEC", ylim = c(0, 50), shape = "A",
    desc = "Ocupados como % de la población total."
  ),
  informalidad = list(
    id = "informalidad", titulo = "Tasa de informalidad por aportes a la seguridad social",
    topico = "Trabajo e ingresos", csv = "09a_tasa_informalidad_aportes.csv",
    y_var = "tasa_inf_aportes", y_lab = "Asalariados sin aportes a SS (%)",
    eje_x = "Año", caption = "EPH-INDEC", ylim = NULL, shape = "A",
    desc = "Asalariados a quienes no se les realizan aportes jubilatorios, como % del total de asalariados."
  ),
  educacion = list(
    id = "educacion", titulo = "Población de 25+ con estudios superiores completos",
    topico = "Desarrollo", csv = "12_mayor_25_superior.csv",
    y_var = "porc_mayor_25_superior", y_lab = "% de personas de 25 años o más",
    eje_x = "Año", caption = "EPH-INDEC", ylim = c(0, 35), shape = "A",
    desc = "Personas de 25 años o más con nivel superior/universitario completo, como % de esa población."
  ),
  nbi_hogares = list(
    id = "nbi_hogares", titulo = "Hogares con Necesidades Básicas Insatisfechas (NBI)",
    topico = "Desarrollo", csv = "13a_nbi_hogares.csv",
    y_var = "pct_hogares_NBI_TOT", y_lab = "% de hogares",
    eje_x = "Año", caption = "EPH-INDEC", ylim = c(0, 50), shape = "A",
    dimensiones = c(TOT = "pct_hogares_NBI_TOT", HAC = "pct_hogares_NBI_HAC",
                    VIV = "pct_hogares_NBI_VIV", SAN = "pct_hogares_NBI_SAN",
                    ESC = "pct_hogares_NBI_ESC", SUB = "pct_hogares_NBI_SUB"),
    dim_labels = c(TOT = "Total (al menos una privación)",
                   HAC = "Hacinamiento", VIV = "Vivienda inconveniente",
                   SAN = "Condiciones sanitarias", ESC = "Escolaridad",
                   SUB = "Capacidad de subsistencia"),
    desc = "Hogares con al menos una privación de NBI, como % del total de hogares. Elegí la sub-dimensión con el selector."
  ),
  nbi_poblacion = list(
    id = "nbi_poblacion", titulo = "Población en hogares con Necesidades Básicas Insatisfechas (NBI)",
    topico = "Desarrollo", csv = "13b_nbi_poblacion.csv",
    y_var = "pct_pob_NBI_TOT", y_lab = "% de población",
    eje_x = "Año", caption = "EPH-INDEC", ylim = c(0, 60), shape = "A",
    dimensiones = c(TOT = "pct_pob_NBI_TOT", HAC = "pct_pob_NBI_HAC",
                    VIV = "pct_pob_NBI_VIV", SAN = "pct_pob_NBI_SAN",
                    ESC = "pct_pob_NBI_ESC", SUB = "pct_pob_NBI_SUB"),
    dim_labels = c(TOT = "Total (al menos una privación)",
                   HAC = "Hacinamiento", VIV = "Vivienda inconveniente",
                   SAN = "Condiciones sanitarias", ESC = "Escolaridad",
                   SUB = "Capacidad de subsistencia"),
    desc = "Población en hogares con al menos una privación de NBI, como % de la población total. Elegí la sub-dimensión con el selector."
  ),
  puestos_priv = list(
    id = "puestos_priv", titulo = "Puestos de trabajo asalariados privados",
    topico = "Trabajo e ingresos", csv = "05_puestos_asalariados_privados.csv",
    y_var = "puestos_miles", y_lab = "Miles de puestos",
    eje_x = "Fecha",
    caption = "Fundar, con base en datos de SIPA (ARCA), Ministerio de Capital Humano.",
    ylim = NULL, shape = "B",
    desc = "Puestos asalariados registrados del sector privado (en miles), promedio de las provincias de cada región. Fuente SIPA, desestacionalizado."
  ),
  salarios_priv = list(
    id = "salarios_priv", titulo = "Remuneración promedio del sector privado registrado",
    topico = "Trabajo e ingresos", csv = "03_salarios_privados_SIPA.csv",
    y_var = "salario_promedio", y_lab = "Pesos corrientes",
    eje_x = "Fecha",
    caption = "Fundar, con base en datos de SIPA (Observatorio de Empleo y Dinámica Empresarial, STEySS).",
    ylim = NULL, shape = "B",
    desc = "Remuneración promedio de los trabajadores registrados del sector privado (pesos corrientes), promedio de las provincias de cada región. Fuente SIPA. Serie desde 2015."
  ),
  salarios_eph = list(
    id = "salarios_eph", titulo = "Salario de asalariados registrados (público y privado)",
    topico = "Trabajo e ingresos", csv = "03b_salarios_registrados_EPH.csv",
    y_var = "salario_promedio", y_lab = "Pesos corrientes",
    eje_x = "Trimestre",
    caption = "Fundar, con base en la EPH (INDEC).",
    ylim = NULL, shape = "C",
    desc = "Salario promedio de asalariados registrados, según sector público o privado, en cada zona. Ponderado por ingreso (PONDIIO), o por PONDERA antes de 2015. Fuente EPH-INDEC. Serie desde 2007; la línea punteada marca el cambio de metodología de ingresos (2015-2016)."
  ),
  empresas = list(
    id = "empresas", titulo = "Cantidad de empresas por jurisdicción",
    topico = "Macroeconomía", csv = "07_serie_empresas_por_jurisdiccion.csv",
    y_var = "empresas", y_lab = "Cantidad de empresas",
    eje_x = "Fecha", caption = "Fundar, con base en datos de SRT.",
    ylim = NULL, shape = "B",
    desc = "Cantidad de empresas empleadoras, promedio de las provincias de cada región. Fuente SRT."
  )
)

# Orden de los tópicos para las pestañas.
TOPICOS <- c("Trabajo e ingresos", "Desarrollo", "Macroeconomía")

# -----------------------------------------------------------------------------
# Loader unificado
# -----------------------------------------------------------------------------
# Devuelve un data frame largo con columnas estándar para cualquier indicador:
#   fecha (Date), fecha_lab (chr), la_rioja_region (chr), valor (dbl)
# `dimension` sólo aplica a los indicadores NBI (usa la columna correspondiente).
cargar_indicador <- function(id, dimension = "TOT") {
  meta <- INDICADORES[[id]]
  if (is.null(meta)) stop("Indicador desconocido: ", id)

  ruta <- file.path(DATA_DIR, meta$csv)
  df   <- readr::read_csv(ruta, show_col_types = FALSE)

  if (meta$shape == "A") {
    # Serie trimestral regional. Para NBI elige la columna de la sub-dimensión.
    y_col <- if (!is.null(meta$dimensiones)) {
      col <- meta$dimensiones[[dimension]]
      if (is.null(col)) meta$y_var else col
    } else {
      meta$y_var
    }

    df %>%
      transmute(
        fecha_lab       = fecha,
        fecha           = parse_trimestre(fecha),
        la_rioja_region = .utf8(la_rioja_region),
        valor           = .data[[y_col]]
      ) %>%
      arrange(fecha, la_rioja_region)

  } else if (meta$shape == "C") {
    # Serie trimestral regional de la EPH con 2 series por sector (público/privado).
    # Se conserva la columna `sector` como clave de color; la región queda para facetar.
    df %>%
      transmute(
        fecha_lab       = fecha,
        fecha           = parse_trimestre(fecha),
        la_rioja_region = .utf8(la_rioja_region),
        sector          = .utf8(sector),
        valor           = .data[[meta$y_var]]
      ) %>%
      arrange(fecha, la_rioja_region, sector)

  } else {
    # Serie mensual provincial: asignar región y promediar por región y fecha,
    # replicando la agregación de src/05_*.R y src/07_*.R.
    df %>%
      asignar_region_provincia() %>%
      group_by(fecha, la_rioja_region) %>%
      summarise(valor = mean(.data[[meta$y_var]], na.rm = TRUE), .groups = "drop") %>%
      mutate(fecha_lab       = format(fecha, "%m-%Y"),
             la_rioja_region = .utf8(la_rioja_region)) %>%
      arrange(fecha, la_rioja_region)
  }
}

# -----------------------------------------------------------------------------
# KPI: último valor y variación para una región (por defecto La Rioja)
# -----------------------------------------------------------------------------
kpi_indicador <- function(id, dimension = "TOT", region = "3. La Rioja") {
  df <- cargar_indicador(id, dimension) %>%
    filter(la_rioja_region == region, !is.na(valor))

  # Shape "C" tiene 2 series por región (sector): la tarjeta KPI muestra el privado.
  if (!is.null(df$sector)) df <- dplyr::filter(df, sector == .utf8("Privado"))

  df <- df %>% arrange(fecha)

  if (nrow(df) == 0) {
    return(list(valor = NA_real_, fecha_lab = NA_character_,
                delta = NA_real_, region = region))
  }

  ult  <- df[nrow(df), ]
  prev <- if (nrow(df) >= 2) df$valor[nrow(df) - 1] else NA_real_
  list(
    valor     = ult$valor,
    fecha_lab = ult$fecha_lab,
    delta     = ult$valor - prev,
    region    = region
  )
}

# Rango temporal disponible para un indicador (para el slider de fechas).
rango_fechas_indicador <- function(id, dimension = "TOT") {
  f <- cargar_indicador(id, dimension)$fecha
  range(f, na.rm = TRUE)
}
