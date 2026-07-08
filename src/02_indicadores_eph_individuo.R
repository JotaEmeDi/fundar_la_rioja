library(tidyverse)

## Lee el dataset canónico de individuo (generado por 01_limpieza_eph.R) y
## calcula los indicadores basados en individuo, escribiendo cada uno como
## CSV en data/inputs_md/.

df <- read_rds("./data/proc_data/eph_individuo.rds")

#### 10. Tasa de empleo
df %>%
  filter(ANO4 >= 2007) %>%
  group_by(fecha, la_rioja_region) %>%
  summarise(ocupado = sum(ocupado * PONDERA),
            pob_tot = sum(PONDERA),
            .groups = "drop") %>%
  mutate(tasa_empleo = ocupado / pob_tot * 100) %>%
  write_csv('./data/inputs_md/10_tasa_empleo.csv')

#### 04. Tasa de desocupación
df %>%
  filter(ANO4 >= 2007) %>%
  group_by(fecha, la_rioja_region) %>%
  summarise(desoc = sum(desocupado * PONDERA),
            pea = sum(pea * PONDERA),
            .groups = "drop") %>%
  mutate(tasa_desoc = desoc / pea * 100) %>%
  write_csv('./data/inputs_md/04_tasa_desoc.csv')

#### 09a. Tasa de informalidad (aportes)
df %>%
  filter(ANO4 >= 2007) %>%
  filter(ESTADO == "Ocupado" & CAT_OCUP == "Obrero o empleado") %>%
  group_by(fecha, la_rioja_region) %>%
  summarise(formales = sum(aportes_descuentos * PONDERA),
            asalariados = sum(asalariado_ocupado * PONDERA),
            .groups = "drop") %>%
  mutate(tasa_inf_aportes = 100 - (formales / asalariados * 100)) %>%
  write_csv('./data/inputs_md/09a_tasa_informalidad_aportes.csv')

#### 03b. Salario promedio de asalariados registrados, por sector (público/privado)
#### Promedio ponderado sum(P21*w)/sum(w) (equivalente a weighted.mean). El peso `w`
#### es PONDIIO (ponderador de ingreso, corrige la no-respuesta) cuando existe; en las
#### ondas viejas (~pre-2016) la EPH imputaba los ingresos y NO hay PONDIIO, así que se
#### usa PONDERA (ponderador poblacional) como fallback. Como cada punto es un trimestre
#### (fecha), todas las filas de un grupo caen del mismo lado del quiebre 2015/2016: no
#### se mezclan ponderadores dentro de una misma celda. Universo: asalariados ocupados
#### registrados (aportes_descuentos == 1) con ingreso de la ocupación principal positivo.
ANO_DESDE_SALARIOS <- 2009 
df %>%
  filter(ANO4 >= ANO_DESDE_SALARIOS,
         ESTADO == "Ocupado", CAT_OCUP == "Obrero o empleado",
         aportes_descuentos == 1,
         !is.na(sector), !is.na(P21), P21 > 0) %>%
  mutate(peso_ing = if_else(!is.na(PONDIIO) & PONDIIO > 0, PONDIIO, PONDERA)) %>%
  group_by(fecha, la_rioja_region, sector) %>%
  summarise(salario_promedio = sum(P21 * peso_ing) / sum(peso_ing), .groups = "drop") %>%
  write_csv('./data/inputs_md/03b_salarios_registrados_EPH.csv')

#### Tasa informalidad b PENDIENTE

#### 12. % mayores de 25 años con nivel superior completo
df %>%
  group_by(fecha, la_rioja_region) %>%
  summarise(mayor_25_superior = sum(mayor_25_superior * PONDERA),
            pob_tot = sum(PONDERA),
            .groups = "drop") %>%
  mutate(porc_mayor_25_superior = mayor_25_superior / pob_tot * 100) %>%
  write_csv('./data/inputs_md/12_mayor_25_superior.csv')
