tictoc::tic()
# 1. Descargar microdatos EPH (individuo y hogar)
source("src/00_descarga_eph.R")

# 2. Limpiar y canonizar -> data/proc_data/eph_individuo.rds, eph_hogar.rds
source("src/01_limpieza_eph.R")

# 3. Calcular indicadores -> CSVs en data/inputs_md/
source("src/02_indicadores_eph_individuo.R")
source("src/02_indicadores_eph_hogar.R")

# 4. Generar visualizaciones por indicador
source("src/04_desoc.R")                 # Tasa de desocupación

# 5. Indicadores de fuente SIPA (prep -> viz)
source("src/03_prep_salarios_privados_SIPA.R")       # Salarios sector privado
source("src/03_salarios_privados_SIPA.R")
source("src/05_prep_puestos_asalariados_privados.R") # Puestos asalariados privados
source("src/05_puestos_asalariados_privados.R")

source("src/03b_salarios_registrados_EPH.R") # Salarios registrados EPH (público/privado)
source("src/09a_informalidad_aportes.R") # Tasa de informalidad
source("src/10_tasa_empleo.R")           # Tasa de empleo
source("src/12_educ.R")                  # Educación superior
source("src/13a_nbi_hogares.R")          # % Hogares con NBI
source("src/13b_nbi_poblacion.R")        # % Población en hogares con NBI
tictoc::toc()