library(eph)
library(tidyverse)

## Descarga incremental: baja un trimestre a la vez, saltea los que ya existen en disco.
## `type` es el valor que espera eph::get_microdata() ("individual" o "hogar").
## `file_tag` es la etiqueta usada en el nombre del archivo (ej. "individuo"), que
## puede diferir de `type` -- deben mantenerse separados para que file.exists()
## compare contra el nombre real de los .rds ya descargados.
## `years` por defecto llega hasta el año en curso, así una onda nueva de la EPH
## se intenta descargar sola sin tener que editar el rango a mano cada año.
## Si un trimestre todavía no está publicado en INDEC, get_microdata() falla:
## se captura el error, se avisa por consola y se sigue con el resto (no corta
## el loop ni pierde lo ya descargado en trimestres anteriores).
##
## `vars_opcionales`: variables que pueden no existir en algunas ondas (ej. PONDIIO,
## el ponderador de ingreso, no existe antes de ~2016 porque la EPH imputaba los
## ingresos faltantes). Si pedirlas hace fallar o devolver un dataset vacío, se
## reintenta la descarga SIN ellas, así las ondas viejas se bajan igual (esas
## columnas quedan ausentes -> NA al unir en la limpieza). No se hardcodea el año
## en que arranca PONDIIO: la onda misma decide si la trae o no.
descargar_eph_incremental <- function(vars, type, out_dir, file_tag = type,
                                       years = 2007:as.integer(format(Sys.Date(), "%Y")),
                                       periods = 1:4, vars_opcionales = character(0)) {
  periodos <- expand_grid(year = years, period = periods)
  tictoc::tic()
  for (i in seq_len(nrow(periodos))) {
    y <- periodos$year[[i]]
    p <- periodos$period[[i]]
    out <- file.path(out_dir, paste0(y, "_", p, "_EPH_", file_tag, ".rds"))
    if (file.exists(out)) {
      cat("El archivo existe:", out, "\n")
      next
    }
    cat("Descargando", out, "\n")
    bajar <- function(vs) tryCatch(
      get_microdata(period = p, year = y, type = type, vars = vs),
      error = function(e) NULL)

    df <- bajar(vars)
    # Reintento sin las opcionales si falló o vino vacío (onda sin PONDIIO, etc.).
    if ((is.null(df) || nrow(df) == 0) && length(vars_opcionales) > 0) {
      df <- bajar(setdiff(vars, vars_opcionales))
    }

    if (!is.null(df) && nrow(df) > 0) {
      write_rds(df, out)
    } else {
      cat("No se pudo descargar", out, "- probablemente todavía no está publicado.\n")
    }
  }
  tictoc::toc()
}

## Saca la clase "labelled" (expss/haven) y sus atributos de etiqueta de una
## columna, si los tiene. organize_labels() deja MUCHAS columnas numéricas
## (no solo las categóricas) como labelled, lo cual rompe operaciones
## aritméticas y comparaciones de tipo estrictas más adelante (if_else(),
## left_join()...) apenas se mezclan con valores planos (ej. Inf) o entre
## dos bases etiquetadas por separado (individuo vs hogar).
quitar_labelled <- function(x) {
  if (inherits(x, "labelled")) {
    x <- unclass(x)
    attributes(x) <- attributes(x)[intersect(names(attributes(x)), "names")]
  }
  x
}

## Carga todos los .rds crudos de una carpeta, une, etiqueta y limpia variables comunes.
limpiar_base_eph <- function(files_dir, type, cols_a_character) {
  files <- list.files(files_dir, pattern = "\\.rds$", full.names = TRUE)
  df <- files %>%
    map(read_rds) %>%
    bind_rows()

  df <- df %>%
    organize_labels(type = type) %>%
    # Primero se resuelve el texto de las columnas categóricas (as.character()
    # sobre un objeto labelled devuelve la etiqueta, ej. "Casa"), y RECIÉN
    # DESPUÉS se pela la clase labelled del resto (columnas numéricas: IDs,
    # conteos, ponderadores). Si se pela todo antes de castear a texto, el
    # as.character() posterior devuelve el código numérico como string
    # (ej. "2") en vez de la etiqueta, y todas las comparaciones de texto
    # (case_when, %in%, ==) dejan de matchear silenciosamente.
    mutate(across(all_of(cols_a_character), as.character)) %>%
    mutate(across(!all_of(cols_a_character), quitar_labelled))

  df %>%
    mutate(
      ANO4 = as.numeric(ANO4),
      TRIMESTRE = unclass(TRIMESTRE),
      fecha = paste0(ANO4, "-Q", TRIMESTRE)
    )
}

## Clasifica aglomerado/región en 3 grupos: La Rioja, NOA-Resto y Resto país.
asignar_la_rioja_region <- function(df) {
  df %>%
    mutate(la_rioja_region = case_when(
      AGLOMERADO == "La Rioja" ~ "3. La Rioja",
      AGLOMERADO != "La Rioja" & REGION == "Noroeste" ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    ))
}
