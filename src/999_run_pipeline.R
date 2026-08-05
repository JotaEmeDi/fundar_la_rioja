# 1. Descargar microdatos EPH (individuo y hogar)
source("src/00_descarga_eph.R")


tictoc::tic()
# 2. Limpiar y canonizar -> data/proc_data/eph_individuo.rds, eph_hogar.rds
source("src/01_limpieza_eph.R")

# 3. Calcular indicadores -> CSVs en data/inputs_md/
source("src/02_indicadores_eph_individuo.R")
source("src/02_indicadores_eph_hogar.R")

# 4. Generar visualizaciones por indicador

# 5. Indicadores de fuente SIPA (prep -> viz)
source("src/03_prep_salarios_privados_SIPA.R")       # Salarios sector privado
source("src/03_salarios_privados_SIPA.R")
source("src/03_prep_salarios_privados_SIPA_real.R")  # Serie real / IPC (CSV)
source("src/03_prep_salarios_privados_SIPA_indice.R") # X-13 + índice ene-2025 + IPC
source("src/03_salarios_privados_SIPA_indice.R")
source("src/03b_salarios_registrados_EPH.R") # Salarios registrados EPH (público/privado)
source("src/04_desoc.R")                 # Tasa de desocupación

source("src/05_prep_puestos_asalariados_privados.R") # Puestos asalariados privados
source("src/05_puestos_asalariados_privados.R")

source("src/09a_informalidad_aportes.R") # Tasa de informalidad
source("src/10_tasa_empleo.R")           # Tasa de empleo
source("src/12_educ.R")                  # Educación superior
source("src/13a_nbi_hogares.R")          # % Hogares con NBI
source("src/13b_nbi_poblacion.R")        # % Población en hogares con NBI

# 6. Pipelines no-EPH (prep + viz)
source("src/06_prep_empleados_publicos_eph_tu.R")
source("src/06_empleados_publicos.R")
source("src/14_prep_exportaciones_subrubros.R")
source("src/14_exportaciones_subrubros.R")
source("src/14_prep_exportaciones_indice.R")
source("src/14_exportaciones_indice.R")
source("src/15_prep_pbg.R")
source("src/15_pbg.R")
source("src/15_prep_pbg_per_capita.R")
source("src/15_pbg_per_capita.R")
source("src/16_prep_recursos_propios.R")
source("src/16_recursos_propios.R")
source("src/17_prep_resultado_fiscal.R")
source("src/17_resultado_fiscal.R")
source("src/18_prep_trayectoria_escolar.R")
source("src/18_trayectoria_escolar.R")
tictoc::toc()
