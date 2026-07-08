# Fundar – Monitor Socioeconómico La Rioja

Repositorio de código para el procesamiento y visualización de indicadores socioeconómicos del Gobierno de La Rioja, desarrollado por [Fundar](https://fund.ar/) — grupo factor~data.

## Objetivo

Generar un pipeline replicable que permita calcular y visualizar una serie de indicadores clave a partir de microdatos públicos. Los indicadores se organizan en torno a tres ejes temáticos: **trabajo e ingresos**, **desarrollo** y **macroeconomía**.

## Indicadores

| # | Indicador | Tópico | Fuente | Estado |
|---|---|---|---|---|
| 04 | Tasa de desempleo (% de la PEA) | Trabajo – Informalidad y Desempleo | EPH | ✓ |
| 09a | Tasa de informalidad por aportes a SS (% de asalariados) | Trabajo – Informalidad y Desempleo | EPH | ✓ |
| 10 | Tasa de empleo (ocupados cada 100 hab.) | Trabajo – Participación laboral | EPH | ✓ |
| 12 | % de población +25 con estudios superiores completos | Desarrollo – Educación | EPH | ✓ |
| 13a | % Hogares con Necesidades Básicas Insatisfechas (NBI) | Desarrollo – Pobreza | EPH | ✓ |
| 13b | % Población en hogares con NBI | Desarrollo – Pobreza | EPH | ✓ |
| 03 | Salarios en el sector formal privado (remuneración promedio) | Trabajo – Salarios e ingresos | SIPA (Min. de Capital Humano) | ✓ |
| 03b | Salario de asalariados registrados, público y privado | Trabajo – Salarios e ingresos | EPH | ✓ |
| 05 | Puestos de trabajo asalariados formales privados totales | Trabajo – Salarios e ingresos | SIPA (Min. de Capital Humano) | ✓ |
| — | Cantidad de empleados públicos cada 1.000 hab. | Trabajo – Salarios e ingresos | — | Pendiente |
| — | Tasa de pobreza multidimensional | Desarrollo – Pobreza | — | Pendiente |
| — | Trayectoria escolar | Desarrollo – Educación | — | Pendiente |
| — | PIB provincial | Macroeconomía – Crecimiento | — | Pendiente |
| — | % del PIB que es industrial | Macroeconomía – Crecimiento | — | Pendiente |
| — | Cantidad de empresas | Macroeconomía – Crecimiento | — | ✓ |
| — | Exportaciones | Macroeconomía – Crecimiento | — | Pendiente |
| — | Resultado fiscal (ingreso total – gasto total) | Macroeconomía – Crecimiento | — | Pendiente |
| — | Recursos propios sobre recursos totales | Macroeconomía – Crecimiento | — | Pendiente |

## Estructura del repositorio

```
fundar_la_rioja/
├── src/
│   ├── utils_eph.R                # Funciones compartidas: descarga, limpieza, región
│   ├── 00_descarga_eph.R          # Etapa 1: descarga incremental (individuo + hogar)
│   ├── 01_limpieza_eph.R          # Etapa 2: limpieza y canonización -> data/proc_data/
│   ├── 02_indicadores_eph_individuo.R # Etapa 3: indicadores de individuo -> CSVs
│   ├── 02_indicadores_eph_hogar.R # Etapa 3: indicadores NBI de hogar -> CSVs
│   ├── 03_prep_salarios_privados_SIPA.R # Prep: lee xlsx SIPA (hoja "Total") -> CSV
│   ├── 03_salarios_privados_SIPA.R # Visualización: remuneración promedio sector privado
│   ├── 03b_salarios_registrados_EPH.R # Visualización: salario registrados EPH (público/privado)
│   ├── 04_desoc.R                # Visualización: tasa de desocupación
│   ├── 05_prep_puestos_asalariados_privados.R # Prep: lee xlsx SIPA (hoja A.5.2) -> CSV
│   ├── 05_puestos_asalariados_privados.R # Visualización: puestos asalariados privados
│   ├── 09a_informalidad_aportes.R # Visualización: tasa de informalidad (aportes)
│   ├── 10_tasa_empleo.R          # Visualización: tasa de empleo
│   ├── 12_educ.R                 # Visualización: % población +25 con estudios superiores
│   ├── 13a_nbi_hogares.R         # Visualización: % hogares con NBI
│   ├── 13b_nbi_poblacion.R       # Visualización: % población en hogares con NBI
│   └── 999_run_pipeline.R        # Corre todo el pipeline EPH de punta a punta
├── data/
│   ├── raw_data/
│   │   ├── eph/                  # Microdatos EPH crudos por año y trimestre (*.rds)
│   │   └── sipa/                 # Reporte "Trabajo registrado" del SIPA (*.xlsx)
│   ├── proc_data/                # Datasets EPH canónicos, ya limpios (eph_individuo.rds, eph_hogar.rds)
│   └── inputs_md/                # Agregados por indicador listos para graficar (*.csv)
├── style/
│   ├── fundar_larioja_theme.R    # Tema original (paleta La Rioja / NOA / Resto país)
│   └── fundar_monitor_theme.R    # Tema inspirado en el Monitor Mensual de Empresas de Fundar
└── fundar_larioja.Rproj          # Proyecto RStudio
```

> Los archivos en `data/raw_data/` y `data/proc_data/` están excluidos del control de versiones (`.gitignore`). Los CSVs en `data/inputs_md/` sí están versionados.

## Pipeline de datos (EPH)

El flujo de trabajo de la EPH se separa en 3 etapas, cada una en su propio script, para poder
re-ejecutar solo una parte sin repetir las anteriores (por ejemplo, recalcular un indicador sin
volver a descargar ni relimpiar los microdatos):

### 1. Descarga incremental (`00_descarga_eph.R`)

Itera sobre todos los años (2007–2025) y trimestres (1–4) y descarga los microdatos de individuo y
de hogar de la EPH usando `eph::get_microdata()`. Cada trimestre se guarda como un `.rds` separado en
`data/raw_data/eph/individuo/` y `data/raw_data/eph/hogar/`. Si el archivo ya existe, se omite la
descarga.

> **Re-descarga por variables nuevas.** La descarga trae solo un subconjunto de columnas
> (`vars_individuo` / `vars_hogar`). Al agregar una variable nueva a esa lista, los `.rds` ya
> en disco **no** se actualizan (el paso es incremental y saltea archivos existentes): hay que
> **borrar** los `.rds` afectados y volver a correr `00`. El indicador 03b sumó a individuo
> `P21` (ingreso de la ocupación principal), `PONDIIO` (ponderador de ingreso) y `PP04A`
> (sector estatal/privado).

### 2. Limpieza y canonización (`01_limpieza_eph.R`)

Une todos los `.rds` crudos de cada fuente, aplica `organize_labels()`, construye las variables
analíticas reutilizables, y persiste dos datasets canónicos comprimidos:

- **`data/proc_data/eph_individuo.rds`**: `ocupado`, `desocupado`, `pea`, `no_pea`, `niv_educ_sup`,
  `mayor_25`, `mayor_25_superior`, `tamanio_estab`, `descuento`, `aporta`, `aportes_descuentos`,
  `asalariado_ocupado`, `sector` (público/privado, desde `PP04A`), `la_rioja_region`, y las crudas
  de ingreso `P21` / `PONDIIO`.
- **`data/proc_data/eph_hogar.rds`**: `la_rioja_region` y los indicadores NBI que dependen solo de
  hogar (`NBI_HAC`, `NBI_VIV`, `NBI_SAN`).

Para mantener estos archivos livianos, se dropean las columnas crudas ya consumidas por las variables
derivadas (ej. `PP04C`/`PP04C99` de individuo, `IV4`-`IV7`/`IV9`/`IV10` de hogar) y se comprimen con
`compress = "gz"` (buen balance entre peso en disco y velocidad de lectura, ya que estos archivos se
leen en cada corrida de la etapa de indicadores). Los `.rds` crudos por trimestre no se tocan — siguen
teniendo todas las columnas descargadas, por si hiciera falta reconstruir el canónico con otras
variables sin re-descargar nada.

`la_rioja_region` clasifica cada aglomerado en tres grupos: `1. Resto país`, `2. NOA-Resto`,
`3. La Rioja` *(énfasis visual)*.

### 3. Cálculo de indicadores (`02_indicadores_eph_individuo.R` / `02_indicadores_eph_hogar.R`)

Leen los `.rds` canónicos (el de hogar cruza además con el de individuo, para NBI_ESC/NBI_SUB/NBI_TOT)
y agrupan por `fecha` y `la_rioja_region`, guardando cada indicador como CSV en `data/inputs_md/`:

| Archivo CSV | Indicador | Variable clave |
|---|---|---|
| `04_tasa_desoc.csv` | Tasa de desocupación | `tasa_desoc` |
| `03b_salarios_registrados_EPH.csv` | Salario de asalariados registrados por sector (`fecha`, `la_rioja_region`, `sector`) | `salario_promedio` |
| `09a_tasa_informalidad_aportes.csv` | Tasa de informalidad (aportes) | `tasa_inf_aportes` |
| `10_tasa_empleo.csv` | Tasa de empleo | `tasa_empleo` |
| `12_mayor_25_superior.csv` | % población +25 con estudios superiores | `porc_mayor_25_superior` |
| `13a_nbi_hogares.csv` | % Hogares con NBI (total y por sub-dimensión) | `pct_hogares_NBI_TOT` |
| `13b_nbi_poblacion.csv` | % Población en hogares con NBI (total y por sub-dimensión) | `pct_pob_NBI_TOT` |

> **Salarios EPH (03b) — ponderación y quiebre 2015/2016.** El salario es un promedio
> ponderado `sum(P21*w)/sum(w)` de asalariados registrados. El peso `w` es `PONDIIO`
> (ponderador de ingreso, que corrige la no-respuesta) cuando existe, y `PONDERA`
> (ponderador poblacional) como fallback en las ondas viejas (~pre-2016), donde la EPH
> imputaba los ingresos y no publica `PONDIIO`. La serie arranca en 2007; como en 2015/2016
> cambió el método de imputación de ingresos (y la EPH estuvo interrumpida entre 2015-T3 y
> 2016-T1), los niveles a ambos lados del quiebre no son estrictamente comparables — el
> gráfico lo marca con una línea vertical punteada.

### 4. Visualización

Cada script `src/XX_*.R` lee su CSV correspondiente y genera un gráfico de líneas con `ggplot2`, usando las escalas definidas en `style/fundar_monitor_theme.R`.

## Pipeline de datos (SIPA)

El indicador de puestos de trabajo asalariados privados no viene de la EPH sino del reporte
mensual "Trabajo registrado" del SIPA (`data/raw_data/sipa/trabajoregistrado_2603_estadisticas.xlsx`),
hoja **A.5.2**: *"Personas con empleo asalariado en el sector privado, según provincia. Sin
estacionalidad. En miles"* — serie mensual y desestacionalizada, en miles de personas.

- **`05_prep_puestos_asalariados_privados.R`**: lee la hoja A.5.2 (el período viene con tipo
  mixto: serial de fecha de Excel hasta ene-2015 y texto abreviado en español desde entonces),
  homologa los nombres de provincia a los mismos usados en `07_serie_empresas_por_jurisdiccion.csv`,
  y escribe el formato largo (una fila por fecha-provincia) en
  `data/inputs_md/05_puestos_asalariados_privados.csv`:

  | Columna | Descripción |
  |---|---|
  | `jurisdiccion` | Provincia (24 jurisdicciones) |
  | `fecha` | Primer día del mes (`YYYY-MM-01`) |
  | `puestos_miles` | Puestos asalariados privados, en miles (tal cual la fuente) |

- **`05_puestos_asalariados_privados.R`**: lee ese CSV, clasifica cada provincia en
  `la_rioja_region` y genera el gráfico facetado por región en
  `outputs/plots/05_puestos_asalariados_privados.png`.

### Salarios en el sector formal privado (indicador 03)

El indicador de salarios sale de otro archivo SIPA
(`data/raw_data/sipa/provinciales_serie_remuneraciones_mensual_2dig_8.xlsx`),
hoja **"Total"**: *"Remuneración promedio de los trabajadores registrados del sector
privado. Remuneración por todo concepto por provincia, a valores corrientes. En pesos"* —
serie mensual por provincia. **Alcance:** la fuente cubre solo el **sector privado
registrado** (el sector público queda pendiente por falta de fuente).

- **`03_prep_salarios_privados_SIPA.R`**: la hoja viene **traspuesta** respecto de A.5.2
  (provincias en filas, meses en columnas, encabezado en la fila 5). El prep pivotea a
  formato largo, parsea el encabezado de fechas (mixto: serial de Excel / ISO / texto
  `mmm-yy`, normalizado a primer día de mes), homologa los nombres de provincia a los
  canónicos de `05`/`07` (tomando `CAPITAL FEDERAL`→`C.A.B.A.` y `BUENOS AIRES`→`Buenos
  Aires`, y descartando `GRAN BUENOS AIRES` y el `Total` nacional), y **recorta desde
  2015** (en pesos corrientes la historia previa queda aplastada por la inflación; el raw
  conserva 1995+). Escribe `data/inputs_md/03_salarios_privados_SIPA.csv`:

  | Columna | Descripción |
  |---|---|
  | `jurisdiccion` | Provincia (24 jurisdicciones) |
  | `fecha` | Primer día del mes (`YYYY-MM-01`), desde 2015 |
  | `salario_promedio` | Remuneración promedio del sector privado, en pesos corrientes |

- **`03_salarios_privados_SIPA.R`**: lee ese CSV, clasifica cada provincia en `la_rioja_region`,
  promedia por región y genera un gráfico único con las tres líneas regionales superpuestas
  (eje Y en pesos corrientes) en `outputs/plots/03_salarios_privados_SIPA.png`.

## Sistema de estilos

El proyecto cuenta con dos archivos de estilo en `style/`:

### `fundar_larioja_theme.R` (tema original)

- **`scale_color_larioja()`** / **`scale_fill_larioja()`**: paleta regional (gris para Resto país, azul para NOA-Resto, naranja para La Rioja).
- **`scale_linewidth_larioja()`**: grosor de línea diferenciado por región.
- **`theme_larioja()`**: tema minimalista con tipografía y márgenes estandarizados.
- **`theme_larioja_mapa()`**: variante sin ejes ni grilla para cartografía.
- **`grafico_lineas_regional()`**: helper para gráficos de líneas regionales.
- **`PALETA_CONTINUA`**: gradiente azul → blanco → naranja para variables continuas.

### `fundar_monitor_theme.R` (tema activo — Monitor Mensual de Empresas)

Replica el estilo visual del [Monitor Mensual de Empresas](https://fund.ar/publicacion/monitor-mensual-de-empresas/) de Fundar. Es el tema usado por todos los scripts de visualización.

**Paleta de colores:**

| Variable | Color | Uso |
|---|---|---|
| `FUNDAR_VERDE` | `#52C8A0` | Verde menta — color principal / positivo |
| `FUNDAR_ROSA` | `#F4877A` | Rosa salmón — negativo / caídas |
| `FUNDAR_BEIGE` | `#EDE8E0` | Fondo del área del gráfico |
| `FUNDAR_OSCURO` | `#1C1C1C` | Fondo oscuro para slides de KPIs |

**Asignación regional:**

| Región | Color |
|---|---|
| `1. Resto país` | `#A8DCC8` (verde menta claro) |
| `2. NOA-Resto` | `#C8C87A` (amarillo oliva) |
| `3. La Rioja` | `#2D6E6E` (verde azulado oscuro — énfasis) |

**Componentes:**

- **`theme_fundar()`**: tema base con fondo beige, grilla horizontal suave, leyenda arriba, etiquetas del eje X a 45°.
- **`theme_fundar_oscuro()`**: variante con fondo oscuro.
- **`theme_fundar_barras_h()`**: variante para gráficos de barras horizontales.
- **`scale_color_fundar_multi()`** / **`scale_fill_fundar_multi()`**: escala de color para series múltiples.
- **`scale_fill_fundar_div()`**: escala verde/rosa para gráficos divergentes.
- **`fuente_fundar()`**: helper para el caption en formato `"Fuente: ..."`.
- **`grafico_lineas_monitor()`**: helper para gráfico de línea única estilo Monitor.
- **`grafico_barras_div()`**: helper para barras horizontales divergentes con etiquetas.

Los prefijos numéricos en la clasificación regional garantizan que ggplot dibuje La Rioja por encima del resto sin transformaciones adicionales.

## Dashboard interactivo

El directorio [`dashboard/`](dashboard/) contiene un dashboard para explorar los
indicadores online, respetando el estilo visual del informe. Comparte un único
núcleo de graficado (`dashboard/R/plots.R`, que reusa `style/fundar_monitor_theme.R`)
entre dos front-ends:

- **App Shiny** (`dashboard/app.R`): interactiva, con filtros por región, rango
  temporal, sub-dimensión de NBI, switch entre gráfico fiel (ggplot) e interactivo
  (plotly), y descarga de PNG/CSV. Desplegable a shinyapps.io.
- **Sitio estático** (`dashboard/index.qmd`): HTML autocontenido publicable en
  GitHub Pages (sin servidor), con interactividad plotly del lado del cliente.

```r
# Correr la app localmente
shiny::runApp("dashboard")
# Generar el sitio estático
# quarto render dashboard/index.qmd
```

Ver [`dashboard/README.md`](dashboard/README.md) y [`dashboard/deploy.md`](dashboard/deploy.md).

## Dependencias

```r
# Pipeline de datos
install.packages(c("eph", "tidyverse", "lubridate", "tictoc", "readxl"))
# Dashboard
install.packages(c("shiny", "bslib", "bsicons", "plotly", "here", "rsconnect"))
# + Quarto CLI (https://quarto.org) para el sitio estático
```

| Paquete | Uso |
|---|---|
| `eph` | Descarga de microdatos de la EPH (INDEC) |
| `tidyverse` | Manipulación de datos y visualización (`dplyr`, `ggplot2`, `readr`) |
| `lubridate` | Manejo de fechas |
| `tictoc` | Medición de tiempos en la descarga |
| `readxl` | Lectura del reporte SIPA en formato `.xlsx` |
| `shiny` / `bslib` / `bsicons` | App interactiva del dashboard y su theming |
| `plotly` | Versión interactiva de los gráficos (hover/zoom) |
| `here` | Resolución de rutas robusta en el dashboard |
| `rsconnect` | Deploy de la app a shinyapps.io |

## Cómo reproducir

Para correr todo el pipeline EPH de punta a punta (descarga → limpieza → indicadores →
visualización) de una sola vez:

```r
source("src/999_run_pipeline.R")
```

O paso a paso:

```r
# 1. Descargar microdatos EPH (individuo y hogar)
source("src/00_descarga_eph.R")

# 2. Limpiar y canonizar -> data/proc_data/eph_individuo.rds, eph_hogar.rds
source("src/01_limpieza_eph.R")

# 3. Calcular indicadores -> CSVs en data/inputs_md/
source("src/02_indicadores_eph_individuo.R")
source("src/02_indicadores_eph_hogar.R")

# 4. Generar visualizaciones por indicador
source("src/04_desoc.R")                 # Tasa de desocupación

# 5. Puestos de trabajo asalariados privados (SIPA) -> data/inputs_md/, luego gráfico
source("src/05_prep_puestos_asalariados_privados.R")
source("src/05_puestos_asalariados_privados.R")

source("src/09a_informalidad_aportes.R") # Tasa de informalidad
source("src/10_tasa_empleo.R")           # Tasa de empleo
source("src/12_educ.R")                  # Educación superior
source("src/13a_nbi_hogares.R")          # % Hogares con NBI
source("src/13b_nbi_poblacion.R")        # % Población en hogares con NBI
```

> La descarga completa (2007–2025) puede tomar varios minutos. El script de descarga es incremental: si se interrumpe, retoma desde el último archivo faltante.

## Contexto del proyecto

Este repositorio corresponde al **Componente 3** de un proyecto más amplio con el Gobierno de La Rioja. El trabajo se organiza en tres etapas:

1. **Coordinación y definición de indicadores**: alineación con los demás componentes del proyecto.
2. **Diseño de maquetas**: definición del tipo de gráfico, paleta de colores y jerarquía visual para cada indicador. El código se desarrolla en R con `ggplot2` como base, incorporando `plotly` cuando se requieren versiones interactivas.
3. **Materiales para talleres de visualización de datos**.
