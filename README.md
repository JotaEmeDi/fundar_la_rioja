# Fundar – Monitor Socioeconómico La Rioja

Repositorio de código para el procesamiento y visualización de indicadores
socioeconómicos del Gobierno de La Rioja, desarrollado por
<a href="https://fund.ar/" target="_blank" rel="noopener">Fundar</a>.

## Objetivo

Generar un pipeline replicable que permita calcular y visualizar una serie de indicadores clave a partir de microdatos públicos. Los indicadores se organizan en torno a tres ejes temáticos: **trabajo e ingresos**, **desarrollo** y **macroeconomía**.

## Indicadores

La columna **Código** identifica el indicador en el repositorio: es el prefijo
de los scripts en `src/`, de los CSV en `data/inputs_md/` y de los gráficos en
`outputs/plots/` (por ejemplo, el código `14` corresponde a `14_prep_exportaciones.R`,
`14_exportaciones_*.csv` y `14_exportaciones_*.png`).

| Código | Indicador | Tópico | Fuente | Estado |
|---|---|---|---|---|
| 04 | Tasa de desempleo (% de la PEA) | Trabajo – Informalidad y Desempleo | EPH | ✓ |
| 09a | Tasa de informalidad por aportes a SS (% de asalariados) | Trabajo – Informalidad y Desempleo | EPH | ✓ |
| 10 | Tasa de empleo (ocupados cada 100 hab.) | Trabajo – Participación laboral | EPH | ✓ |
| 12 | % de población +25 con estudios superiores completos | Desarrollo – Educación | EPH | ✓ |
| 13a | % Hogares con Necesidades Básicas Insatisfechas (NBI) — pobreza por NBI | Desarrollo – Pobreza | EPH | ✓ |
| 13b | % Población en hogares con NBI — pobreza por NBI | Desarrollo – Pobreza | EPH | ✓ |
| 03 | Salarios en el sector formal privado (remuneración promedio) | Trabajo – Salarios e ingresos | SIPA (Min. de Capital Humano) | ✓ |
| 03b | Salario de asalariados registrados, público y privado | Trabajo – Salarios e ingresos | EPH | ✓ |
| 05 | Puestos de trabajo asalariados formales privados totales | Trabajo – Salarios e ingresos | SIPA (Min. de Capital Humano) | ✓ |
| 06 | Cantidad de empleados públicos cada 1.000 hab. | Trabajo – Salarios e ingresos | EPH Total Urbano | ✓ |
| 07 | Cantidad de empresas | Macroeconomía – Crecimiento | SRT | ✓ |
| 14 | Exportaciones | Macroeconomía – Crecimiento | OPEX-INDEC | ✓ |
| 15 | PIB / PBG provincial y % industrial / estructura | Macroeconomía – Crecimiento | CEPAL / Min. Economía | ✓ |
| 16 | Recursos propios sobre recursos totales | Macroeconomía – Crecimiento | Min. Economía (TOP + RON) | ✓ |
| 17 | Resultado fiscal APNF / PBG nominal (La Rioja) | Macroeconomía – Crecimiento | APNF Min. Economía + PBG nominal (DGEyC La Rioja) | ✓ |
| 18 | Trayectoria escolar (cohorte primaria→secundaria) | Desarrollo – Educación | Relevamiento Anual (provincia) | ✓ |

## Estructura del repositorio

```
fundar_la_rioja/
├── src/                          # Prep + visualización por indicador (numerados)
│   └── 000_install_deps.R        # Dependencias (paquetes R + opcional TinyTeX)
├── data/
│   ├── raw_data/                 # Fuentes crudas (EPH, SIPA, OPEX, CEPAL, TOP/RON, …)
│   ├── proc_data/                # EPH canónica (eph_individuo.rds, eph_hogar.rds)
│   └── inputs_md/                # CSVs tidy listos para graficar / informe
├── outputs/plots/                # PNG estáticos del monitor
├── informe/
│   ├── monitor_la_rioja.Rmd      # Informe knit-able (coyuntura + fichas al final)
│   ├── monitor_la_rioja_tufte.Rmd # Misma info, salida estilo Tufte (HTML)
│   └── monitor_la_rioja_tufte_fundar.Rmd # Ídem, con paleta/estilo Fundar
├── style/                        # Temas ggplot (activo: fundar_monitor_theme.R)
└── fundar_larioja.Rproj
```

### Informe para la provincia (HTML, PDF o Word)

El mismo `informe/monitor_la_rioja.Rmd` puede salir como **HTML**, **PDF** o **Word**.

**Recomendado: HTML.** El monitor está pensado así (TOC flotante a la izquierda,
link a fichas metodológicas, navegación web). PDF y Word son opciones de entrega
(archivo único / edición); no replican igual esa experiencia.

Hay dos cosas distintas:

| Qué | Dónde | Cuándo |
|---|---|---|
| Instalar dependencias | `src/000_install_deps.R` (consola, **fuera** del RMD) | Una vez por máquina |
| Generar el informe | Desde el RMD: Knit en RStudio, o `rmarkdown::render(...)` | Cada vez que quieras HTML / PDF / Word |

Las dependencias **no** se corren “desde adentro” del RMD: el knit solo usa lo
ya instalado. Si falta LaTeX, el PDF falla aunque el RMD esté bien. Word no
necesita LaTeX.

#### HTML (default, recomendado)

```r
# Una vez por máquina:
source("src/000_install_deps.R")

# Luego, cada vez — Knit → Knit to HTML
# o en consola (raíz del repo):
rmarkdown::render("informe/monitor_la_rioja.Rmd")
# → informe/monitor_la_rioja.html
```

#### PDF (opcional)

Requiere la misma base del HTML **más** una distribución LaTeX. El RMD usa
`xelatex` (Unicode / texto en español). Primera instalación de TinyTeX: varios
minutos; el primer knit a PDF también puede tardar (paquetes LaTeX + PNG).

```r
# Una vez por máquina (paquete tinytex + TinyTeX):
source("src/000_install_deps.R")
install_project_deps(pdf = TRUE)
# Si aún no hay motor: tinytex::install_tinytex()
# Reiniciar R / RStudio. Chequear: Sys.which("xelatex")

# Luego, cada vez — Knit → Knit to PDF, o:
rmarkdown::render(
  "informe/monitor_la_rioja.Rmd",
  output_format = "pdf_document"
)
# → informe/monitor_la_rioja.pdf
```

#### Word (opcional)

Misma base de paquetes que el HTML (sin LaTeX). Útil para editar texto o
entregar un `.docx`. Sin TOC flotante ni layout web.

```r
# Dependencias: las del HTML (source("src/000_install_deps.R"))

# Knit → Knit to Word, o:
rmarkdown::render(
  "informe/monitor_la_rioja.Rmd",
  output_format = "word_document"
)
# → informe/monitor_la_rioja.docx
```

#### Variante Tufte (HTML, opcional)

`informe/monitor_la_rioja_tufte.Rmd` es una **copia** del informe con estilo
<a href="https://rstudio.github.io/tufte/" target="_blank" rel="noopener">Tufte</a> (blanco y negro, tipografía ET Book,
notas al margen). Mismo contenido, mismos PNG de `outputs/plots/`; cambia solo
el formato de salida. El informe canónico sigue siendo `monitor_la_rioja.Rmd`.

```r
# Dependencias: las del HTML (source("src/000_install_deps.R"), incluye tufte)

# Knit → Knit to HTML, o:
rmarkdown::render("informe/monitor_la_rioja_tufte.Rmd")
# → informe/monitor_la_rioja_tufte.html
```

#### Variante Tufte + Fundar (HTML, opcional)

`informe/monitor_la_rioja_tufte_fundar.Rmd` es una **copia** de la variante
Tufte anterior, con la paleta tipográfica del informe (teal/slate de
`monitor_estilo.css`) en vez del blanco y negro clásico de Tufte: encabezados,
enlaces y fichas metodológicas quedan con identidad Fundar; el fondo se
mantiene crema (así calzan sin recuadro los PNG con fondo blanco de
`style/fundar_monitor_theme.R`). Estilos en
`informe/monitor_estilo_tufte_fundar.css`.

```r
# Dependencias: las del HTML (source("src/000_install_deps.R"), incluye tufte)

# Knit → Knit to HTML, o:
rmarkdown::render("informe/monitor_la_rioja_tufte_fundar.Rmd")
# → informe/monitor_la_rioja_tufte_fundar.html
```

El RMD inserta los PNG de `outputs/plots/` (no re-descarga datos). Ver
**Qué actualizar / qué no tocar** más abajo.

> **Raw vs CSV.** La carpeta `data/raw_data/` (y `data/proc_data/`) está en
> `.gitignore`: los Excel/crudos **no se versionan** en Git (pesan, se
> regeneran o los aporta la provincia). Los CSV en `data/inputs_md/` **sí**
> están versionados y alcanzan para knitear el Monitor.
>
> **Implicación para la provincia:** cuando actualicen un indicador cuyo raw no
> se descarga solo de internet (p. ej. **PBG nominal DGEyC** o **trayectoria
> escolar**), deben **colocar el Excel en la ruta indicada** en su copia local
> del proyecto y correr prep → viz → knit. El repositorio entrega el pipeline y
> los CSV vigentes; el archivo crudo lo mantienen ellos (o lo reciben por
> carpeta compartida la primera vez).

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
> (ponderador poblacional) como alternativa en las ondas anteriores (~pre-2016), donde la EPH
> imputaba los ingresos y no publica `PONDIIO`. La serie comienza en 2007; en 2015/2016
> cambió el método de imputación de ingresos (y la EPH estuvo interrumpida entre 2015-T3 y
> 2016-T1), por lo que los niveles a ambos lados del quiebre no son estrictamente comparables —
> el gráfico lo indica con una línea vertical punteada.

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
registrado** (no incluye remuneraciones del sector público).

- **`03_prep_salarios_privados_SIPA.R`**: la hoja viene **traspuesta** respecto de A.5.2
  (provincias en filas, meses en columnas, encabezado en la fila 5). El prep pivotea a
  formato largo, parsea el encabezado de fechas (mixto: serial de Excel / ISO / texto
  `mmm-yy`, normalizado a primer día de mes), homologa los nombres de provincia a los
  canónicos de `05`/`07` (tomando `CAPITAL FEDERAL`→`C.A.B.A.` y `BUENOS AIRES`→`Buenos
  Aires`, y descartando `GRAN BUENOS AIRES` y el `Total` nacional), y **recorta desde
  2015** (en pesos corrientes, la historia previa queda distorsionada por la inflación; el raw
  conserva 1995+). Escribe `data/inputs_md/03_salarios_privados_SIPA.csv`:

  | Columna | Descripción |
  |---|---|
  | `jurisdiccion` | Provincia (24 jurisdicciones) |
  | `fecha` | Primer día del mes (`YYYY-MM-01`), desde 2015 |
  | `salario_promedio` | Remuneración promedio del sector privado, en pesos corrientes |

- **`03_salarios_privados_SIPA.R`**: lee ese CSV, clasifica cada provincia en `la_rioja_region`,
  promedia por región y genera un gráfico único con las tres líneas regionales superpuestas
  (eje Y en pesos corrientes) en `outputs/plots/03_salarios_privados_SIPA.png`.

Para la serie en **precios constantes** (IPC nacional) y el índice real:
`03_prep_salarios_privados_SIPA_real.R` → `03_salarios_privados_SIPA_real.R`
(CSV con MA12; el monitor publica la tendencia suavizada).

## Pipeline de datos (EPH Total Urbano — empleados públicos)

Indicador **06**. Fuente distinta de la EPH continua: microdatos de **Total Urbano**
(INDEC), personas, tercer trimestre.

```r
source("src/06_prep_empleados_publicos_eph_tu.R")
source("src/06_empleados_publicos.R")
```

Raw en `data/raw_data/` (TU); CSV tidy y PNG en `inputs_md/` / `outputs/plots/`
con prefijo `06_`. Detalle de actualización en la tabla más abajo y en la ficha 06.

## Pipeline de datos (OPEX — exportaciones)

Indicador **14**. Origen provincial de las exportaciones (INDEC), bienes en
millones de USD: totales, índice 2015 = 100, share nacional y composición por
subrubros.

```r
source("src/14_prep_exportaciones.R")
source("src/14_prep_exportaciones_subrubros.R")
source("src/14_exportaciones_subrubros.R")
source("src/14_prep_exportaciones_indice.R")
source("src/14_exportaciones_indice.R")
```

## Pipeline de datos (SRT — cantidad de empresas)

Indicador **07**. Serie de empresas por jurisdicción (SRT).

```r
source("src/07_prep_cant_empresas.R")
source("src/07_cant_empresas.R")
```

## Pipeline de datos (CEPAL — PBG / estructura / % industrial)

Indicador **15**. VAB provincial por sectores (CEPAL / Min. Economía): niveles,
per cápita, ranking, estructura y peso industrial.

```r
source("src/15_prep_pbg.R")
source("src/15_pbg.R")
```

(Hay scripts auxiliares `15_prep_*` / `15_*` para per cápita, estructura e
industria; el bloque anterior es el núcleo. Ver fichas 15.)

## Pipeline de datos (finanzas públicas — recursos propios y resultado fiscal)

- **16 Recursos propios** (TOP + RON, Min. Economía):

```r
source("src/16_prep_recursos_propios.R")
source("src/16_recursos_propios.R")
```

- **17 Resultado fiscal APNF / PBG nominal** (solo La Rioja). Denominador:
  PBG nominal provincial (DGEyC); el Excel vive en `data/raw_data/pbg/` (no
  versionado en Git — lo aporta/actualiza la provincia):

```r
source("src/17_prep_resultado_fiscal.R")
source("src/17_resultado_fiscal.R")
```

## Pipeline de datos (educación — trayectoria escolar)

Indicador **18**. Relevamiento Anual (provincia). El Excel crudo va en
`data/raw_data/educacion/` (tampoco viaja en Git):

```r
source("src/18_prep_trayectoria_escolar.R")
source("src/18_trayectoria_escolar.R")
```

## Qué actualizar / qué no tocar

### Actualizar (cuando salga dato nuevo)

| Fuente | Indicadores | Frecuencia típica | Dónde obtener | Acción |
|---|---|---|---|---|
| EPH continua | 04, 09a, 10, 12, 13a, 13b, 03b | Trimestral | <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">Bases microdatos INDEC</a> (vía `eph::get_microdata` en `00`) | `00` → `01` → `02` → scripts viz |
| EPH Total Urbano | 06 | Anual (3T) | <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">Bases microdatos INDEC</a> (personas, Total Urbano) | Reemplazar raw TU → `06_prep` → `06` viz |
| SIPA | 03, 05 | Mensual | Portal OEDE / Min. Capital Humano (*Trabajo registrado* y serie de remuneraciones provinciales; el nombre del Excel cambia con el mes) | Reemplazar xlsx en `data/raw_data/sipa/` → prep → viz |
| SRT empresas | 07 | Mensual | <a href="https://www.srt.gob.ar/estadisticas/series/co/up/Serie_historica_Segun_Jurisdiccion%20-%20Ubicacion%20Persona%20Trabajadora%20-%20UP.xlsx" target="_blank" rel="noopener">Descarga directa del Excel SRT (serie UP)</a> | Borrar xlsx en `data/raw_data/srt/` (o dejar que descargue si no está) → `07_prep` → `07` viz |
| OPEX INDEC | 14 | Anual | <a href="https://www.indec.gob.ar/indec/web/Nivel4-Tema-3-2-79" target="_blank" rel="noopener">Página INDEC — Origen provincial de las exportaciones</a> (desde ahí bajar el xls vigente) | Descargar xls OPEX → `14_prep*` → viz |
| CEPAL VAB 52 sectores | 15 | Cuando publiquen | <a href="https://repositorio.cepal.org/server/api/core/bitstreams/539fcce5-8977-4061-a222-fbfd7358a35f/content" target="_blank" rel="noopener">Descarga directa del Excel CEPAL (VAB 52 sectores)</a> | Borrar/reemplazar Excel en `data/raw_data/pbg/` → `15_prep` → `15_pbg` |
| TOP / RON Min. Economía | 16 | Anual | <a href="https://www.argentina.gob.ar/sites/default/files/serie_top_1984_2024_1.xlsx" target="_blank" rel="noopener">Descarga directa TOP</a> · <a href="https://www.argentina.gob.ar/sites/default/files/serie_ron_2003_2025.xlsx" target="_blank" rel="noopener">Descarga directa RON</a> (los nombres de archivo en el portal pueden cambiar) | Reemplazar xlsx en `data/raw_data/finanzas/` → `16_prep` → viz |
| Ejecuciones APNF Min. Economía | 17 | Anual | <a href="https://www.argentina.gob.ar/economia/sechacienda/coordinacion-fiscal-provincial/ejecucion-presupuestaria-provincial/ejecuciones" target="_blank" rel="noopener">Página Min. Economía — Ejecuciones APNF</a> (desde ahí bajar el xlsx vigente) | Reemplazar `serie_aif-apnf-*.xlsx` → `17_prep` → viz |
| PBG nominal La Rioja (DGEyC provincia) | 17 | Anual | Aporte provincia (DGEyC); **sin URL pública** en el pipeline | Colocar/actualizar Excel en `data/raw_data/pbg/` → `17_prep` → viz |
| Relevamiento Anual (educación) | 18 | Anual | Aporte provincia (Unidad de Información Educativa); **sin URL pública** en el pipeline | Colocar/actualizar Excel en `data/raw_data/educacion/` → prep → viz |

Si el texto dice **«Descarga directa…»**, el link apunta al archivo (Excel/xls), no a una página intermedia: el navegador suele bajarlo al instante. Si dice **«Página…»**, hay que entrar y elegir el archivo vigente. Detalle de hoja y nombre de archivo: fichas metodológicas más abajo. Después de regenerar PNG: `rmarkdown::render("informe/monitor_la_rioja.Rmd")`.

### No tocar (salvo decisión metodológica explícita)

- Corte **La Rioja / NOA-Resto / Resto país** (NOA-Resto = Catamarca, Jujuy, Salta, Santiago del Estero, Tucumán; **no** incluye La Rioja).
- Fórmulas de cada indicador (documentadas en el RMD y en el encabezado de cada `src/*_prep*.R`).
- Tema visual `style/fundar_monitor_theme.R` y paleta regional.
- Agrupación de letras CIIU → grandes sectores en PBG (salvo acuerdo con el equipo).

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

Replica el estilo visual del
<a href="https://fund.ar/publicacion/monitor-mensual-de-empresas/" target="_blank" rel="noopener">Monitor Mensual de Empresas</a>
de Fundar. Es el tema usado por todos los scripts de visualización.

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

## Dependencias

Todo se instala **fuera del RMD**, con `src/000_install_deps.R` (una vez por
máquina, o cuando falte un paquete). El script solo instala lo que falta.

```r
# Mínimo: pipeline + knit HTML
source("src/000_install_deps.R")

# Opcional: salida PDF (paquete tinytex + distribución LaTeX TinyTeX)
install_project_deps(pdf = TRUE)
# Si pdflatex sigue sin encontrarse: tinytex::install_tinytex()
# Luego reiniciar R / RStudio. Chequear: Sys.which("pdflatex")
```

| Salida del RMD | ¿Qué hace falta? | Dónde se instala (no en el RMD) |
|---|---|---|
| HTML (recomendado) | `rmarkdown`, `knitr`, etc. | `source("src/000_install_deps.R")` |
| Word (opcional) | Lo mismo que HTML (sin LaTeX) | `source("src/000_install_deps.R")` |
| PDF (opcional) | Lo de HTML **más** LaTeX (`xelatex` vía TinyTeX o MiKTeX) | `install_project_deps(pdf = TRUE)` |

Alternativa a TinyTeX en Windows:
<a href="https://miktex.org" target="_blank" rel="noopener">MiKTeX</a>.

| Paquete | Uso |
|---|---|
| `eph` | Descarga de microdatos de la EPH (INDEC) |
| `tidyverse` | Manipulación de datos y visualización (`dplyr`, `ggplot2`, `readr`) |
| `lubridate` | Manejo de fechas |
| `tictoc` | Medición de tiempos en la descarga |
| `readxl` / `janitor` | Lectura y limpieza de Excel (SIPA, OPEX, PBG, finanzas) |
| `ggrepel` / `treemapify` | Etiquetas y treemaps en gráficos del monitor |
| `rmarkdown` / `knitr` / `here` | Knit del informe |
| `tinytex` | LaTeX liviano para salida PDF (opcional) |

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
source("src/09a_informalidad_aportes.R") # Tasa de informalidad
source("src/10_tasa_empleo.R")           # Tasa de empleo
source("src/12_educ.R")                  # Educación superior
source("src/13a_nbi_hogares.R")          # % Hogares con NBI
source("src/13b_nbi_poblacion.R")        # % Población en hogares con NBI

# 5. Puestos y salarios SIPA (privado registrado)
source("src/05_prep_puestos_asalariados_privados.R")
source("src/05_puestos_asalariados_privados.R")
source("src/03_prep_salarios_privados_SIPA.R")
source("src/03_salarios_privados_SIPA.R")
source("src/03_prep_salarios_privados_SIPA_real.R")
source("src/03_salarios_privados_SIPA_real.R")
```

> La descarga completa (2007–2025) puede tomar varios minutos. El script de descarga es incremental: si se interrumpe, retoma desde el último archivo faltante.

Las demás fuentes (Total Urbano, OPEX, SRT, PBG, finanzas, trayectoria) se
corren con los `source(...)` de cada sección **Pipeline de datos** más arriba.
Después de regenerar PNG: knit del RMD.

---

## Continuidad para el equipo provincial

El Monitor está pensado para que el equipo provincial pueda **actualizarlo**
sin reconstruir el análisis desde cero.

**Tres entregables (separados):**

1. **Fichas metodológicas** (PPT / HTML) — qué mide cada indicador, fuente, fórmula.
2. **RMD de coyuntura** (`informe/monitor_la_rioja.Rmd`) — gráficos y análisis;
   no incluye el manual técnico del proyecto.
3. **Este README** — instalación, actualización y mantenimiento.

### Plantilla de sección del RMD (para quien edita el monitor)

Cada indicador en el RMD sigue este orden (las fichas en PPT y este README
quedan fuera del cuerpo del informe):

1. Título (`##`)
2. Pregunta guía
3. Definición
4. Fuente / URL
5. Raw / scripts / CSV
6. Cálculo / limitaciones
7. Actualización (breve; detalle en la ficha correspondiente más abajo)
8. Gráficos (`mostrar(...)`)
9. Análisis, con el último dato preferentemente leído desde CSV

Esqueleto:

~~~~
## Nombre

**Pregunta.** ¿…?
**Definición.** …
**Fuente / URL.** … — [link](https://…)
**Raw / scripts / CSV.** `data/raw_data/…` · `src/…` · `data/inputs_md/…`
**Cálculo.** … Limitaciones: …
**Actualización.** …

```{r id}
mostrar("outputs/plots/XX.png")
```

### Análisis
…
~~~~

Hay dos piezas técnicas de mantenimiento:

1. **Este README** — manual de fuentes y pasos de actualización (fichas abajo).
2. **`informe/monitor_la_rioja.Rmd`** — informe reproducible: al actualizar datos
   y reejecutar el pipeline, los **gráficos se actualizan**; el texto fijo
   orienta la lectura (no debe congelar de forma permanente el “último número”).

Flujo habitual cuando se publica un dato nuevo:

```text
1. Descargar / reemplazar el raw en data/raw_data/...
2. Ejecutar prep → viz del indicador (o source("src/999_run_pipeline.R"))
3. Revisar PNG en outputs/plots/
4. Knit: rmarkdown::render("informe/monitor_la_rioja.Rmd")
```

### Inventario rápido (estado de entrega)

| Indicador | CSV / plots | En RMD | Notas |
|---|---|---|---|
| 04 Desempleo | ✓ | ✓ | |
| 10 Empleo | ✓ | ✓ | |
| 09a Informalidad | ✓ | ✓ | |
| 05 Puestos SIPA | ✓ | ✓ | |
| 03 Salarios SIPA (+ índice real) | ✓ | ✓ | Corte de serie: ver `FECHA_HASTA` en prep |
| 03b Salarios EPH | ✓ | Parcial | CSV/plots; la lectura principal de salarios en el Monitor es SIPA |
| 06 Empleo público | ✓ | ✓ | |
| 07 Empresas | ✓ | ✓ | |
| 12 Educ. superior | ✓ | ✓ | |
| 13 NBI | ✓ | ✓ | Pobreza por NBI (no IPM) |
| 14 Exportaciones | ✓ | ✓ | |
| 15 PBG / industria / estructura | ✓ | ✓ | Incluye per cápita y ranking |
| 16 Recursos propios | ✓ | ✓ | |
| 17 Resultado fiscal APNF | ✓ | ✓ | Solo La Rioja; % PBG nominal (DGEyC) |
| 18 Trayectoria escolar | ✓ | ✓ | Actualización del RA: tarea provincia |

### Plantilla de ficha (usar para cada indicador)

Copiar y completar:

```markdown
### XX — Nombre del indicador

- **Qué mide:** …
- **Tópico:** …
- **Fuente / organismo:** …
- **Publicación / URL:** … (página + nombre típico del archivo)
- **Frecuencia:** …
- **Archivo raw en el repo:** `data/raw_data/...`
- **CSV tidy:** `data/inputs_md/...`
- **Scripts:** prep `src/XX_prep_....R` → viz `src/XX_....R`
- **Gráficos:** `outputs/plots/XX_....png`
- **Cómo actualizar:**
  1. …
  2. …
  3. …
- **Último dato esperado tras la actualización:** el PNG y, en el RMD, la serie deben
  reflejar el nuevo período (variaciones incluidas).
- **No confundir / limitaciones:** …
```

### Fichas modelo (completas)

#### 05 — Puestos de trabajo asalariados privados

- **Qué mide:** Stock de personas con empleo asalariado en el sector privado registrado, en miles, por provincia.
- **Tópico:** Trabajo e ingresos – Salarios e ingresos.
- **Fuente / organismo:** SIPA / Observatorio de Empleo y Dinámica Empresarial (OEDE), Ministerio de Capital Humano. Reporte *Trabajo registrado*, hoja **A.5.2** (sin estacionalidad).
- **Publicación / URL:** Portal de estadísticas de trabajo registrado del Ministerio de Capital Humano / OEDE (buscar “Trabajo registrado” / estadísticas mensuales). El nombre del Excel cambia con el mes (ej. `trabajoregistrado_2603_estadisticas.xlsx`).
- **Frecuencia:** Mensual.
- **Archivo raw:** `data/raw_data/sipa/trabajoregistrado_XXXX_estadisticas.xlsx` (reemplazar el archivo vigente; actualizar `path_raw` en el prep si cambia el nombre).
- **CSV tidy:** `data/inputs_md/05_puestos_asalariados_privados.csv`
- **Scripts:** `src/05_prep_puestos_asalariados_privados.R` → `src/05_puestos_asalariados_privados.R`
- **Gráficos:** `outputs/plots/05_puestos_asalariados_privados.png`
- **Cómo actualizar:**
  1. Descargar el Excel nuevo de Trabajo registrado.
  2. Guardarlo en `data/raw_data/sipa/` y ajustar `path_raw` en el prep si el nombre cambió.
  3. `source("src/05_prep_puestos_asalariados_privados.R")`
  4. `source("src/05_puestos_asalariados_privados.R")`
  5. Knit del RMD (o revisar el PNG).
- **Limitaciones:** No incluye no registrados ni monotributo puro. La comparación de **niveles** entre provincias está condicionada por tamaño; lo útil es la **dinámica** de La Rioja. Agregación regional en el gráfico = **promedio** de provincias del grupo.

#### 03 — Salarios privados registrados (SIPA) + serie real (IPC)

- **Qué mide:** Remuneración promedio por todo concepto del sector privado registrado. **Nominal:** nivel / ranking provincial. **Tendencia:** se desestacionaliza (la fuente incluye aguinaldo en jun/dic) y se deflacta por IPC; se presenta como índice **ene-2025 = 100**.
- **Tópico:** Trabajo e ingresos – Salarios e ingresos.
- **Fuente / organismo:** SIPA / OEDE – serie **provincial** (`provinciales_serie_remuneraciones_mensual_*.xlsx`, hoja **Total**). IPC: INDEC/SSPM. *(La SA oficial de remuneraciones en `trabajoregistrado_*.xlsx` A.4 es solo total país.)*
- **Publicación / URL:**
  - Remuneraciones provinciales: OEDE / Capital Humano.
  - IPC: <a href="https://infra.datos.gob.ar/catalog/sspm/dataset/145/distribution/145.3/download/indice-precios-al-consumidor-nivel-general-base-diciembre-2016-mensual.csv" target="_blank" rel="noopener">datos.gob.ar – IPC nivel general base dic-2016</a>
- **Frecuencia:** Mensual.
- **Archivos raw:** `data/raw_data/sipa/provinciales_serie_remuneraciones_mensual_2dig_8.xlsx`; `data/raw_data/ipc/…`
- **CSV tidy:** `03_salarios_privados_SIPA.csv`; `03_salarios_privados_SIPA_real.csv` (auxiliar); **`03_salarios_privados_SIPA_indice_region.csv`** (monitor).
- **Scripts:** `03_prep_salarios_privados_SIPA.R` → `03_salarios_privados_SIPA.R`; `03_prep_salarios_privados_SIPA_indice.R` → `03_salarios_privados_SIPA_indice.R` (requiere paquetes `seasonal` + `x13binary`).
- **Gráficos (monitor):** `03_salarios_privados_SIPA.png`; `03_salarios_privados_SIPA_real_sa_indice.png` (índice real SA).
- **Cómo actualizar:** reemplazar Excel provincial → prep/viz nominal → prep/viz índice (X-13).
- **Limitaciones:** Solo privado registrado; incluye SAC (por eso X-13). IPC nacional no captura canasta regional. Series regionales: media simple de provincias.

#### 14 — Exportaciones (OPEX)

- **Qué mide:** Exportaciones de bienes por origen provincial (millones USD); índice 2015=100; participación sobre la suma de las 24 jurisdicciones; composición por subrubros.
- **Tópico:** Macroeconomía – Crecimiento.
- **Fuente / organismo:** INDEC – Origen provincial de las exportaciones (OPEX).
- **Publicación / URL:**
  - Página: https://www.indec.gob.ar/indec/web/Nivel4-Tema-3-2-79
  - Archivo típico: `https://www.indec.gob.ar/ftp/cuadros/economia/sh_opex_principales_grubros_1993_XXXX.xls` (el año final del nombre cambia).
- **Frecuencia:** Anual (años recientes a menudo provisorios).
- **Archivo raw:** `data/raw_data/exportaciones/sh_opex_principales_grubros_1993_2025.xls` (reemplazar y/o actualizar `url_opex` / `path_raw` en el prep).
- **CSV tidy:** `14_exportaciones_por_provincia.csv`, `14_exportaciones_subrubros_*.csv`, `14_exportaciones_indice_2015_region.csv`
- **Scripts:** `14_prep_exportaciones.R`, `14_prep_exportaciones_subrubros.R`, `14_prep_exportaciones_indice.R` → `14_exportaciones_subrubros.R`, `14_exportaciones_indice.R`
- **Gráficos:** totales, treemap, heatmap, índice 2015=100, share nacional (`outputs/plots/14_*.png`)
- **Cómo actualizar:**
  1. Descargar el xls OPEX nuevo desde la página INDEC (o borrar el raw local para que el prep lo baje si la URL está al día).
  2. Actualizar el nombre/URL en `14_prep_exportaciones.R` si cambió el año del archivo.
  3. Correr prep totales → prep subrubros → prep índice → ambos viz.
  4. Knit del RMD.
- **Limitaciones:** Solo bienes (no servicios). La suma de subrubros detallados **no** cierra con el total provincial (usar filas/total del CSV de totales para shares). Agregación regional = **suma**. El índice compara dinámicas, no niveles absolutos. Minería puede no aparecer desagregada para La Rioja en OPEX.

#### 04 — Tasa de desempleo

- **Qué mide:** Desocupados / PEA × 100 (aglomerados).
- **Fuente / URL:** EPH continua (INDEC) — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases de microdatos</a>. Descarga en repo vía `eph::get_microdata()` (`00_descarga_eph.R`).
- **Frecuencia:** Trimestral.
- **Scripts:** `00` → `01` → `02` → `04_desoc.R`.
- **CSV / plot:** indicadores en `data/inputs_md/` (serie desoc) · `outputs/plots/04_desoc.png`.
- **Cómo actualizar:** correr descarga incremental → limpieza → indicadores → viz.
- **Limitaciones:** Para La Rioja es el aglomerado capital, no toda la provincia.

#### 10 — Tasa de empleo

- **Qué mide:** Ocupados / población × 100.
- **Fuente / URL:** misma EPH continua — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases</a>.
- **Scripts:** pipeline EPH → `10_tasa_empleo.R`.
- **Plot:** `outputs/plots/10_tasa_empleo.png`.

#### 09a — Informalidad (aportes)

- **Qué mide:** Asalariados sin aportes / asalariados × 100.
- **Fuente / URL:** misma EPH continua — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases</a>.
- **Scripts:** pipeline EPH → `09a_informalidad_aportes.R`.
- **Plot:** `outputs/plots/09a_informalidad_aportes.png`.

#### 12 — Educación superior (+25)

- **Qué mide:** % de 25+ con estudios superiores completos.
- **Fuente / URL:** misma EPH continua — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases</a>.
- **Scripts:** pipeline EPH → `12_educ.R`.
- **Plot:** `outputs/plots/12_educ.png`.

#### 13a / 13b — Pobreza por NBI (hogares y población)

- **Qué mide:** % de hogares (13a) y % de población en esos hogares (13b) con al
  menos una Necesidad Básica Insatisfecha (`NBI_TOT`). Sub-dimensiones: hacinamiento,
  vivienda, saneamiento, escolaridad, capacidad de subsistencia (definiciones en
  `CLAUDE.md` / pipeline EPH).
- **Nombre en el monitor / fichas:** **pobreza por NBI** (no “pobreza
  multidimensional” / IPM).
- **Tópico:** Desarrollo – Pobreza.
- **Fuente / URL:** EPH continua (INDEC) — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases de microdatos</a>.
- **Scripts:** pipeline EPH → `13a_nbi_hogares.R`, `13b_nbi_poblacion.R`.
- **Plots:** `13a_nbi_hogares.png`, `13b_nbi_poblacion.png`.
- **No confundir / limitaciones:** Conserva dimensiones críticas de privación
  (vivienda, saneamiento, escolaridad, hacinamiento, subsistencia), pero **no es
  un Índice de Pobreza Multidimensional (IPM)**: no usa la misma canasta de
  indicadores, umbrales ni agregación (p. ej. Alkire-Foster) que un IPM. Es el
  indicador clásico de NBI sobre EPH. Para La Rioja, aglomerado capital (EPH
  continua), no toda la provincia.

#### 06 — Empleados públicos cada 1.000 hab. (+ composición)

- **Qué mide:** Asalariados estatales cada 1.000 habitantes (urbano); composición por rama CAES.
- **Fuente / URL:** EPH Total Urbano (INDEC) — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases de microdatos</a> (personas, 3T).
- **Frecuencia:** Anual (3er trimestre).
- **Raw:** `data/raw_data/eph_total_urbano_*/`.
- **Scripts:** `06_prep_empleados_publicos_eph_tu.R` → `06_empleados_publicos.R`; composición `06_prep_empleados_publicos_composicion.R` → `06_empleados_publicos_composicion.R`.
- **Plots:** `06_empleados_publicos_*.png`.
- **Cómo actualizar:** sumar carpeta del nuevo 3T → prep → viz.
- **Limitaciones:** Cobertura urbana; 2019/2020 con jurisdicciones faltantes en algunos años.

#### 07 — Cantidad de empresas

- **Qué mide:** Empresas empleadoras registradas por jurisdicción.
- **Fuente / URL:** SRT — <a href="https://www.srt.gob.ar/estadisticas/series/co/up/Serie_historica_Segun_Jurisdiccion%20-%20Ubicacion%20Persona%20Trabajadora%20-%20UP.xlsx" target="_blank" rel="noopener">serie histórica por jurisdicción (ubicación de la persona trabajadora)</a> (hoja Cuadro 6.2).
- **Raw / CSV / scripts:** `data/raw_data/srt/` · `07_prep_cant_empresas.R` → `07_serie_empresas_por_jurisdiccion.csv` · `07_cant_empresas.R`.
- **Plot:** `11_empresas_jurisdiccion.png`.
- **Cómo actualizar:** borrar el xlsx en `data/raw_data/srt/` → prep → viz.

#### 15 — PBG / % industrial / estructura

- **Qué mide:** VAB provincial precios 2004; share industrial; estructura sectorial.
- **Fuente / URL:** <a href="https://repositorio.cepal.org/server/api/core/bitstreams/539fcce5-8977-4061-a222-fbfd7358a35f/content" target="_blank" rel="noopener">Excel CEPAL 52 sectores</a>.
- **Scripts:** `15_prep_pbg.R` → `15_pbg.R`; per cápita: `15_prep_pbg_per_capita.R` → `15_pbg_per_capita.R`; ranking provincial (bump chart): `15_pbg_ranking_percapita.R`.
- **Plots:** `15_pbg_*.png` (incluye `15_pbg_ranking_percapita.png`).
- **Cómo actualizar:** reemplazar Excel en `data/raw_data/pbg/` → prep → viz.

#### 16 — Recursos propios / totales

- **Qué mide:** TOP / (TOP + RON).
- **Fuente / URL:** <a href="https://www.argentina.gob.ar/sites/default/files/serie_top_1984_2024_1.xlsx" target="_blank" rel="noopener">TOP</a>, <a href="https://www.argentina.gob.ar/sites/default/files/serie_ron_2003_2025.xlsx" target="_blank" rel="noopener">RON</a> (Min. Economía; nombres pueden cambiar).
- **Scripts:** `16_prep_recursos_propios.R` → `16_recursos_propios.R`.
- **Plot:** `16_recursos_propios.png`.
- **Relacionado:** resultado fiscal APNF (17) — cuenta completa, no solo tributario.

#### 17 — Resultado fiscal (APNF / PBG nominal) — solo La Rioja

- **Qué mide:** Resultado financiero y primario de la APNF de La Rioja como
  **% del PBG nominal** provincial (valores corrientes a precios básicos).
- **Por qué solo La Rioja:** no se dispone de una serie de PBG nominal homogénea
  para el resto de las provincias; por eso **no** se replica la comparación
  NOA-Resto / resto país en este indicador.
- **Fuentes:**
  - Numerador: <a href="https://www.argentina.gob.ar/economia/sechacienda/coordinacion-fiscal-provincial/ejecucion-presupuestaria-provincial/ejecuciones" target="_blank" rel="noopener">Ejecuciones presupuestarias APNF</a> · `data/raw_data/finanzas/serie_aif-apnf-2025.xlsx`.
  - Denominador: PBG nominal La Rioja — **Dirección General de Estadísticas y
    Censos de la provincia de La Rioja** ·
    `data/raw_data/pbg/PBG_cuadros_generales_sectoreales_final_sept_2026.xlsx`
    (hoja `Corrientes`, fila Total; miles de $ → millones / 1000).
- **Actualización:** el Excel de PBG nominal lo aporta y actualiza la
  **Dirección General de Estadísticas y Censos** de la provincia. Como
  `data/raw_data/` no se versiona en Git, ese Excel **no viaja en el repo**: hay
  que copiarlo a
  `data/raw_data/pbg/PBG_cuadros_generales_sectoreales_final_sept_2026.xlsx`
  (o el nombre vigente) en la máquina local y luego correr
  `17_prep` → `17_resultado_fiscal.R` → knit. El APNF se reemplaza cuando
  publica el Ministerio de Economía (mismo esquema: raw local → prep).
  Los CSV en `inputs_md/` sí quedan en el repositorio para poder knitear sin
  recalcular.
- **Scripts:** `17_prep_resultado_fiscal.R` → `17_resultado_fiscal.R`.
- **CSV:** `17_resultado_fiscal_la_rioja.csv`, `15_pbg_nominal_la_rioja.csv`
  (y `17_resultado_fiscal_por_provincia.csv` como referencia APNF).
- **Plots:** `17_resultado_fiscal.png`, `17_resultado_fiscal_primario.png`.
- **Nota:** valores nominales; **no** usar PBG CEPAL (constantes 2004) como
  denominador. La serie se limita a la intersección de años APNF ∩ PBG nominal.

#### 18 — Trayectoria escolar (cohorte primaria → secundaria)

- **Qué mide:** Para una cohorte teórica de **12 años** (7 de primaria + 5 de secundaria en La Rioja):

  \[
  \text{Trayectoria} = \frac{\text{matrícula en 5° año (año final)}}{\text{matrícula en 1° grado (año inicial)}} \times 100
  \]

  Ejemplo con la base provincial 2014–2025: \(5325 / 6912 \approx 77\%\).

- **Tópico:** Desarrollo – Educación.
- **Fuente / organismo:** Relevamiento Anual (RA) procesado por la Unidad de Información y Estadística Educativa de La Rioja (no es EPH).
- **Acuerdo metodológico con la provincia** (dejar registro explícito):
  - Reunión **3/7/2026** con Claudia Garcete (Coordinadora Unidad de Información y Estadística Educativa): priorizar flujo primaria→secundaria; no cobertura; no cruzar con lengua/matemática; La Rioja es 7+5 (no 6+6).
  - Reunión **10/7/2026** con Diego Oviedo: fijar numerador = matrícula de **5° año** (no egreso formal si el RA del año aún no cierra); denominador = matrícula de **1° grado** de la cohorte; ideal restar repitentes de 1° grado cuando existan; desagregar sexo y estatal/privado si la base lo permite.
  - Notas/Word de esas reuniones y Excel de trabajo viven en `trayectoria educativa/` del repo (insumo de diseño; el raw operativo del pipeline irá a `data/raw_data/educacion/` cuando se versionen los scripts).
- **Qué NO mide:** egreso con título; panel nominal de los mismos alumnos; cobertura escolar; trayectoria desde inicial.
- **Limitaciones:** aproximación de stock de matrícula entre dos puntas de cohorte (migración, repitencia y reingresos afectan la lectura). Mejora futura: excluir repitentes de 1° grado del denominador; comparar cohortes sucesivas; NOA vía anuarios nacionales.
- **Frecuencia:** Anual (cuando cierra el RA / anuario).
- **Archivo raw:** `data/raw_data/educacion/trayectoria_2014_2025_la_rioja.xlsx`
  (Excel del Relevamiento Anual / provincia). Misma lógica que el PBG nominal:
  la actualización del crudo es **tarea provincial**; se coloca en esa ruta y
  se corre prep → viz → knit. `data/raw_data/` no se versiona en Git; los CSV
  tidy en `inputs_md/` sí permiten knitear el Monitor con la serie vigente.
- **CSV tidy:** `18_trayectoria_escolar_matricula.csv`, `18_trayectoria_escolar_cohorte.csv`.
- **Scripts:** `18_prep_trayectoria_escolar.R` → `18_trayectoria_escolar.R`.
- **Gráficos:** `18_trayectoria_escolar.png`, `18_trayectoria_escolar_matricula.png`, `18_trayectoria_escolar_desagregada.png`.
- **Cómo actualizar (tarea de la provincia):**
  1. Cuando cierre el Relevamiento Anual del año nuevo, armar/actualizar la tabla de cohorte (mismo formato: nivel, año calendario, año de estudio, matrícula total, y si se puede sexo y sector).
  2. Para la cohorte “a término” de 12 años: 1° grado en \(t\) y 5° año en \(t+11\) (con primaria de 7 años).
  3. Colocar/reemplazar el Excel en `data/raw_data/educacion/` (mantener el nombre o ajustar `path_raw` en el prep). El raw no viaja en Git: lo mantienen en su copia local del proyecto.
  4. `source("src/18_prep_trayectoria_escolar.R")` → `source("src/18_trayectoria_escolar.R")` → knit del monitor.  5. Validar el número con el equipo de Educación antes de publicar.
- **Responsable de la serie de matrícula:** cartera educativa provincial (RA). Fundar deja el pipeline reproducible; la provincia sostiene la actualización del input.

#### 03b — Salarios registrados EPH (público/privado)

- **Qué mide:** Ingreso ocupación principal de asalariados registrados, por sector.
- **Fuente / URL:** EPH continua / Total Urbano según script — <a href="https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos" target="_blank" rel="noopener">bases INDEC</a>.
- **Scripts:** `03b_salarios_registrados_EPH.R` y preps `03b_prep_*`.
- **Nota:** útil para sector público; el análisis de talleres priorizó SIPA privado por ahora.

---

## Contexto del proyecto

Este repositorio corresponde al **Componente 3** de un proyecto más amplio con el Gobierno de La Rioja. El trabajo se organiza en tres etapas:

1. **Coordinación y definición de indicadores**: alineación con los demás componentes del proyecto.
2. **Diseño de maquetas**: definición del tipo de gráfico, paleta de colores y jerarquía visual para cada indicador. El código se desarrolla en R con `ggplot2` como base, incorporando `plotly` cuando se requieren versiones interactivas.
3. **Materiales para talleres de visualización de datos**.
