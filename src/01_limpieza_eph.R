library(eph)
library(tidyverse)
source("./src/utils_eph.R")

## Limpia y canoniza los microdatos crudos de individuo y hogar, y persiste
## un .rds comprimido por fuente en data/proc_data/. Estos dos archivos son
## el punto de partida único para la etapa de cálculo de indicadores
## (02_indicadores_eph_individuo.R y 02_indicadores_eph_hogar.R).

dir.create("./data/proc_data", showWarnings = FALSE, recursive = TRUE)

## ============================== Individuo ==================================

cols_character_individuo <- c("REGION", "AGLOMERADO", "ESTADO", "NIVEL_ED",
                               "PP04A", "PP04C", "PP04C99", "CAT_OCUP", "PP07H", "PP07I",
                               "CH03", "CH10", "CH12", "CH13")

df_ind <- limpiar_base_eph("./data/raw_data/eph/individuo", type = "individual",
                            cols_a_character = cols_character_individuo)

### Procesamiento tasas laborales
df_ind <- df_ind %>%
  mutate(ocupado = if_else(ESTADO == "Ocupado", 1, 0),
         desocupado = if_else(ESTADO == "Desocupado", 1, 0),
         pea = if_else(ESTADO %in% c("Ocupado", "Desocupado"), 1, 0),
         no_pea = if_else(!(ESTADO %in% c("Ocupado", "Desocupado")), 1, 0))

### Procesamiento nivel educativo
df_ind <- df_ind %>%
  mutate(niv_educ_sup = if_else(
    NIVEL_ED %in% c("Superior universitaria incompleta",
                    "Superior universitaria completa"), 1, 0)) %>%
  mutate(mayor_25 = if_else((CH06 > 25 & CH06 != 99), 1, 0)) %>%
  mutate(mayor_25_superior = if_else((mayor_25 == 1 & niv_educ_sup == 1), 1, 0))

### Procesamiento informalidad
#### Tamanio
df_ind <- df_ind %>%
  mutate(PP04C_rec = case_when(
    PP04C == "0" ~ "NC",
    PP04C == "Ns./Nr." ~ "NR",
    PP04C %in% c("1 persona", "2 personas", "3 personas",
                 "4 personas", "5 personas") ~ "Hasta 5 personas",
    PP04C %in% c("6 a 10 personas", "11 a 25 personas", "26 a 40 personas") ~ "6 a 40 personas",
    TRUE ~ "Más de 40 personas"
  )) %>%
  mutate(tamanio_estab = case_when(
    PP04C_rec == "NC" & PP04C99 == "0" ~ "NC",
    PP04C_rec == "NR" & PP04C99 == "hasta 5" ~ "Hasta 5 personas",
    PP04C_rec == "NR" & PP04C99 == "de 6 a 40" ~ "6 a 40 personas",
    PP04C_rec == "NR" & PP04C99 == "mas de 40" ~ "Más de 40 personas",
    PP04C_rec == "NR" & PP04C99 == "Ns./Nr.." ~ "NR"
  ))

#### Aportes
df_ind <- df_ind %>%
  mutate(
    descuento = if_else(PP07H == "Si", 1, 0),
    aporta = if_else(PP07I == "Si", 1, 0),
    asalariado_ocupado = if_else(
      (CAT_OCUP == "Obrero o empleado" & ESTADO == "Ocupado"), 1, 0)
  ) %>%
  mutate(
    aportes_descuentos = if_else(
      (aporta == 1 | descuento == 1), 1, 0)
  )

#### Sector (público / privado), desde PP04A (1 = estatal, 2 = privado, 3 = otro).
#### Se usa para el indicador de salarios de asalariados registrados
#### (03b_salarios_registrados_EPH). "De otro tipo" y Ns./Nr. quedan en NA y se
#### excluyen del cálculo. La derivación es tolerante a cómo llegue PP04A: texto
#### etiquetado por organize_labels() en cualquier capitalización ("Estatal",
#### "estatal", "Sector estatal"...) o el código numérico ("1"/"2") si no vino
#### etiquetado. Diagnóstico: table(df_ind$PP04A, useNA = "always").
df_ind <- df_ind %>%
  mutate(sector = case_when(
    str_detect(str_to_lower(PP04A), "estatal|públic|public") ~ "Público",
    str_detect(str_to_lower(PP04A), "privad")                ~ "Privado",
    PP04A == "1" ~ "Público",
    PP04A == "2" ~ "Privado",
    TRUE         ~ NA_character_
  ))

## Región
df_ind <- df_ind %>%
  asignar_la_rioja_region()

## Dropeo de columnas crudas ya consumidas por las variables derivadas de arriba
## (bajan el peso del canónico; siguen disponibles sin red en los .rds crudos
## de data/raw_data/eph/individuo/ si hicieran falta para un indicador nuevo).
df_ind <- df_ind %>%
  select(-PP04A, -PP04C, -PP04C99, -CH04, -PP03C)

write_rds(df_ind, "./data/proc_data/eph_individuo.rds", compress = "gz")

## ================================ Hogar =====================================

cols_character_hogar <- c("REGION", "AGLOMERADO", "IV1", "IV2", "IV4", "IV5", "IV6", "IV7",
                           "IV8", "IV9", "IV10", "IV11", "II1", "II2")

df_hog <- limpiar_base_eph("./data/raw_data/eph/hogar", type = "hogar",
                            cols_a_character = cols_character_hogar)

## Región
df_hog <- df_hog %>%
  asignar_la_rioja_region()

## Indicadores NBI que dependen solo de hogar (no requieren cruzar con individuo)

### NBI_HAC: hacinamiento (más de 3 personas por cuarto)
df_hog <- df_hog %>%
  mutate(
    II1_num = case_when(II1 %in% c("99", "Ns./Nr.") ~ NA_real_, TRUE ~ as.numeric(II1)),
    personas_por_cuarto = IX_TOT / II1_num,
    NBI_HAC = case_when(
      is.na(personas_por_cuarto) ~ NA_real_,
      personas_por_cuarto > 3 ~ 1,
      TRUE ~ 0
    )
  )

### NBI_VIV: vivienda de tipo inconveniente (excluye casa, departamento y rancho)
df_hog <- df_hog %>%
  mutate(NBI_VIV = case_when(
    IV1 %in% c("Casa", "Departamento", "Rancho") ~ 0,
    IV1 %in% c("Pieza de inquilinato", "Pieza en hotel familiar o pensión",
               "Local no construido para habitación", "Casilla",
               "Vivienda móvil", "Otros") ~ 1,
    TRUE ~ NA_real_
  ))

### NBI_SAN: condiciones sanitarias (sin baño, o baño sin desagüe adecuado)
### IV8 = ¿tiene baño/letrina? (Sí/No). IV9 es la UBICACIÓN del baño (dentro/fuera
### de la vivienda), no si tiene o no, por eso NO se usa acá.
df_hog <- df_hog %>%
  mutate(NBI_SAN = case_when(
    IV8 %in% c("No") ~ 1,
    IV8 %in% c("Sí", "Si") & IV11 %in% c("9", "0", "4") ~ 1,
    IV8 %in% c("Sí", "Si") ~ 0,
    TRUE ~ NA_real_
  ))

## Dropeo de columnas de vivienda/saneamiento no usadas en ningún NBI vigente
## (NBI_VIV usa solo IV1, NBI_SAN usa IV8+IV11, NBI_HAC usa IX_TOT/II1),
## más las columnas auxiliares que ya se resumieron en NBI_HAC.
df_hog <- df_hog %>%
  select(-IV2, -IV4, -IV5, -IV6, -IV7, -IV9, -IV10, -II2, -II1_num, -personas_por_cuarto)

write_rds(df_hog, "./data/proc_data/eph_hogar.rds", compress = "gz")
