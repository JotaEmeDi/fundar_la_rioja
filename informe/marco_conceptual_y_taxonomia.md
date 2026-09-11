# Marco conceptual y taxonomía de visualizaciones — Monitor socioeconómico de La Rioja

**Consultoría de fortalecimiento de capacidades · Gobierno de La Rioja — Fundar**
**Componente 3 · Etapa 2 (diseño de maquetas)**

---

## 0. Presentación

Este documento acompaña al prototipo de **Monitor socioeconómico de La Rioja**
([`informe/monitor_la_rioja_tufte_fundar.html`](monitor_la_rioja_tufte_fundar.html))
y cumple dos funciones:

1. **Marco conceptual y metodológico** (Parte 1): fija los criterios de
   *integridad visual* con los que se diseñan, revisan y actualizan los
   gráficos del Monitor. Es la traducción operativa, al caso La Rioja, del
   [Informe final de evaluación de las visualizaciones de Argendata](../clases/materiales/Informe_final_argendata.pdf)
   (Rosati, 2024) y de las tres clases del componente formativo
   ([`clases/`](../clases/)).

2. **Taxonomía de elementos gráficos adaptada al Monitor** (Parte 2): toma la
   taxonomía *preliminar* de Argendata (una herramienta gráfica por cada
   *operación analítica × tipo de dato*) y la contrasta, una por una, con las
   visualizaciones efectivamente usadas en el Monitor, señalando
   correspondencias, buenas prácticas ya incorporadas y oportunidades de mejora.

**Destinatarios.** Equipo de la Dirección General de Planificación y Monitoreo
de Políticas Públicas (perfil de comunicación y perfil de mantenimiento del
código) y equipo de Fundar.

**Fuentes.** Tufte (1983, 1990, 1997); Munzner (2014); Healy (2019);
Cleveland & McGill (1984); Kosara (2016); Quinan, Padilla, Creem-Regehr &
Meyer (2019); Informe final Argendata (Rosati, 2024). Ver
[bibliografía](#bibliografía).

---

# PARTE 1 · Marco conceptual y metodológico

## 1.1. Punto de partida: un gráfico es un mapeo de datos a canales

Todo gráfico traduce datos a **propiedades visuales** (canales): posición,
longitud, ángulo, área, color, forma. Cuatro décadas de estudios perceptuales
—desde Cleveland & McGill (1984) hasta Munzner (2014)— establecen que **los
canales no son intercambiables**: existe un orden de eficacia para decodificar
magnitudes.

| Tipo de variable | Canales, de mejor a peor |
|---|---|
| **Ordinal / cuantitativa** | posición sobre escala común › posición sobre escalas no alineadas › longitud › ángulo/pendiente › área › luminancia/saturación › curvatura › volumen (3D) |
| **Categórica (nominal)** | posición espacial · color (*hue*, sin variar saturación ni luminancia) › ... › movimiento › forma de las marcas (peor) |

Consecuencias directas, que se citan a lo largo del documento:

- Los **gráficos de torta** codifican en **ángulo** (canal débil): se
  desaconsejan frente al *waffle chart*, que codifica en **posición/área
  contable** sobre una grilla.
- Los **treemaps** codifican en **área** (canal débil): son aceptables para
  estructura jerárquica, pero no para lecturas de magnitud precisa.
- La **posición sobre una escala común** es el mejor canal: es la razón por la
  que un *slope chart* capta variaciones más chicas que un *waffle*, y por la
  que un *Cleveland dot plot* es preferible a las barras cuando hay muchas
  categorías.

> **Regla 1.** Elegí la geometría que ponga la comparación que te importa en el
> mejor canal posible.

## 1.2. Integridad gráfica (Tufte): los tres principios

El Informe de Argendata sintetiza la *integridad gráfica* de Tufte en tres
principios rectores:

1. **Proporcionalidad.** «La representación de números en la superficie del
   gráfico debe ser directamente proporcional a las cantidades numéricas
   representadas.»
2. **Etiquetas claras y detalladas** que reduzcan la distorsión y la
   ambigüedad. Si la variable es poco intuitiva (variación de una variación,
   variación de un *ranking*, índice), hay que **explicitar cómo se construyó**.
3. **Datos en su contexto.** El dato aislado engaña. El contexto puede venir de
   (a) la comparación con otras unidades, (b) períodos más largos en las series
   de tiempo, o (c) la variabilidad de la distribución de origen.

En el Monitor, el principio 2 se materializa en la **ficha metodológica** que
acompaña a cada indicador (definición, para qué sirve, qué dice si sube/baja,
comportamiento esperado, unidad, fórmula, fuente oficial, frecuencia,
limitaciones) y el principio 3 en el **corte territorial constante**
(La Rioja / NOA-Resto / Resto país) —ver [1.8](#18-datos-en-su-contexto) y
[1.10](#110-cómo-se-operacionaliza-en-el-monitor).

## 1.3. El factor de mentira (*lie factor*)

Medida de distorsión de Tufte:

```
factor de mentira  =  tamaño del efecto en el gráfico  ÷  tamaño del efecto en los datos
```

- `= 1` → representación fiel.
- `> 1,05` → el gráfico **sobrestima** el efecto.
- `< 0,95` → el gráfico lo **subestima**.

Chequeos derivados para cada gráfico del Monitor:

- La longitud o el área dibujada es proporcional al número representado.
- La **dimensionalidad del gráfico no supera la de los datos**: un dato de una
  dimensión no se representa con un área ni con un volumen.
- El eje no está truncado sin avisar (ver [1.6](#16-ejes)).

## 1.4. *Chart junk* y aglomeramiento visual (*visual cluttering*)

**Chart junk** (Tufte): sombras, tramas de fondo, degradados decorativos,
efectos 3D, colores sobresaturados, cualquier adorno que no represente
información. **Regla:** si podés borrar un elemento sin perder información,
borralo.

**Visual cluttering:** saturación por exceso de elementos que *sí* portan
información (demasiadas series, categorías, marcas, etiquetas). Aumenta el
esfuerzo cognitivo y esconde el mensaje principal.

**Respuesta por defecto al *cluttering*: *small multiples* (facetado).** Una
grilla de gráficos chicos que **comparten ejes y escalas**, un panel por
categoría. El cerebro compara paneles idénticos con rapidez. Es preferible a
superponer muchas series en un solo panel.

> **Regla 2.** Ante muchas series superpuestas, probá primero *small multiples*
> con escala compartida; recién si las escalas son inconciliables, pasá a ejes
> libres (y explicitalo) o a índice base 100.

En el Monitor el facetado ya es el caballo de batalla: PBG, recursos propios,
resultado fiscal, % industrial, exportaciones, empresas, puestos asalariados y
salarios EPH se muestran facetados por región.

## 1.5. Variación en los datos, no en el diseño

> «Debemos visualizar la variación en los datos, no en el diseño.»

Si el gráfico cambia de escala, de unidad, de dimensiones o de encuadre a lo
largo de sí mismo, el lector lee variación que no está en los datos. De aquí se
desprenden:

- **Nada de 3D, perspectiva ni sombras.** Munzner (2014, cap. 6) da cinco
  razones: la percepción de profundidad es imprecisa; los objetos se ocluyen;
  la perspectiva deforma distancias y ángulos; sólo obtenemos un punto de
  información por rayo visual; la información sobre el plano 2D es mucho mayor
  que sobre la profundidad.
- **Dimensionalidad.** La dimensión del gráfico no puede superar la de los
  datos (vínculo directo con el *lie factor*).
- **Contexto temporal.** No recortar la serie de modo que oculte el
  comportamiento típico del indicador.
- **Nominal vs. real** (Playfair): en **series de tiempo monetarias**, casi
  siempre es mejor usar **unidades constantes / deflactadas**. Una serie de
  pesos corrientes en Argentina muestra sobre todo inflación, no el fenómeno.
  → Ver [1.11, punto 1](#111-decisiones-abiertas-y-trabajo-futuro).

## 1.6. Ejes

**Eje Y — rango.**

- Empieza en **cero**. Si por una razón fundada no arranca en cero, el quiebre
  se marca explícitamente.
- **Única excepción admitida:** *líneas facetadas* en las que lo que se compara
  son **variaciones relativas, no niveles** (índices base 100, correlaciones de
  dinámica). El Monitor usa esta excepción de forma correcta en las series
  índice.

**Marcas (*ticks*).**

- Entre **6 y 8 marcas por eje**. Menos deja al lector sin referencias; más
  satura. En ejes temporales largos: mostrar años, no todos los períodos.
- Sin marcas secundarias.
- Etiquetas sin ceros ni decimales innecesarios: si son miles de millones,
  escribir «1.000» y aclarar la unidad en el **título del eje**.

**Unidades.** Van en el **título del eje** (`$`, `%`, «miles de puestos»), no
repetidas en cada marca.

**Doble eje: nunca.** Las escalas de un doble eje son arbitrarias y pueden
**fabricar correlaciones** que no existen. Alternativas: (a) facetar por
variable; (b) llevar ambas series a **índice base 100**. El Monitor ya evita el
doble eje en todos los casos.

## 1.7. El color como canal

El color son **tres subcanales** (Munzner, 2014):

| Subcanal | Pregunta | Ordinalidad implícita |
|---|---|---|
| **Luminancia** | ¿qué tan brillante? | **Sí** |
| **Saturación** | ¿qué tan colorido? | **Sí** |
| ***Hue* / cromaticidad** | ¿qué «color» es? | **No** |

**Regla de mapeo:**

- **Variable cualitativa** → variar el ***hue***, con saturación y luminancia
  parejas.
- **Variable ordinal o cuantitativa** → variar **luminancia o saturación**, no
  el *hue*. Escala **secuencial** si el dominio va en un solo sentido;
  **divergente** si hay un punto medio con significado.

**Cantidad de colores.** Entre **6 y 12** discriminables como máximo (contando
fondo y líneas del gráfico). Si hacen falta más: (a) agrupar categorías
—aprovechando jerarquías— o dejar una categoría «resto»; (b) **combinar
subcanales** (p. ej. *hue* para agrupar clases y saturación para distinguir
subclases —caso ENGHo del Informe).

**Uniformidad perceptual.** La percepción del color no es lineal. Si pasos
iguales en los datos **no** producen pasos iguales en el color (medidos en un
espacio perceptual como **CAM02-UCS**, con distancia ΔE), el gráfico:

1. **inventa cortes** que no están en los datos (discretización implícita —
   Quinan et al., 2019); y
2. **esconde** variaciones reales, porque colores parecidos se mapean a valores
   dispares.

Es una violación directa del principio 1 de Tufte. `jet` es el contraejemplo
clásico; **viridis** y **plasma** cumplen uniformidad y además son legibles con
**daltonismo**. El Informe de Argendata midió las paletas institucionales
`fundar_1` / `fundar_2` y encontró que «muestran oscilaciones mucho más fuertes
sobre todo en los valores finales de la escala».

**Énfasis.** El color debe destacar lo que se quiere destacar. En el Monitor,
**La Rioja va en el teal oscuro `#2D6E6E`** y las series de contexto en tonos
claros: el **contraste de luminancia** hace que La Rioja salte a la vista sin
necesidad de otro elemento gráfico.

## 1.8. Datos en su contexto

Tres formas de dar contexto, y su estado en el Monitor:

| Forma de contexto | En el Monitor |
|---|---|
| **Grupo de comparación** (otras unidades) | ✔ Corte territorial constante: La Rioja / NOA-Resto / Resto país en casi todos los indicadores. |
| **Períodos largos** | ✔ Series desde 2004 (PBG), 2007 (EPH), 2015 (exportaciones); lecturas de «largo plazo» + «reciente». |
| **Variabilidad de la distribución** | ⚠ Hoy verbal: en NBI se describe una «banda p25–p75 de los últimos años» y se aclara que es «un indicador estructural, no un termómetro mes a mes». Todavía no hay geometría de variabilidad (IC, *ribbon*, boxplot). → [1.11, punto 5](#111-decisiones-abiertas-y-trabajo-futuro). |

**Ruido muestral.** Varios indicadores (desempleo, empleo, informalidad, NBI,
educación superior) salen de la **EPH continua**, que para La Rioja cubre sólo
el **aglomerado capital** y tiene un dominio chico. Antes de contar una
variación hay que preguntarse si es señal o ruido; promediar las cuatro ondas
del año estabiliza.

## 1.9. Alineación entre narrativa y visualización

- **Granularidad pareja.** Si el análisis habla de cuatro rubros, el gráfico no
  muestra doce. (Caso ENGHo del Informe: la reformulación desagrega sólo los
  rubros que menciona el texto.)
- **El título afirma el hallazgo**, no nombra la variable.
  *«Tasa de desocupación»* → *«La desocupación de La Rioja se ubica por debajo
  del NOA desde 2021»*. En el Monitor esto se resuelve hoy con las **preguntas
  guía** en cada sección (*«¿Cómo evolucionó el producto bruto de La Rioja?»*).
- **El subtítulo** fija unidad, universo y período: *«% de la PEA. Aglomerado
  La Rioja, 2007–2025, trimestral.»*
- **El *caption*** lleva la fuente completa y las **advertencias
  metodológicas**: quiebres de serie, cambios de metodología, períodos sin
  relevamiento. El Monitor ya lo hace en salarios EPH (línea punteada +
  nota del cambio de metodología de ingresos 2015–2016).

## 1.10. Cómo se operacionaliza en el Monitor

**El «dilema de percepción».** No podemos hacer una visualización por lector.
Lo mejor que se puede hacer es **generar uniformidad**: que todos los gráficos
se lean igual. Eso es lo que hace el tema compartido.

| Pieza del repo | Qué fija |
|---|---|
| [`style/fundar_monitor_theme.R`](../style/fundar_monitor_theme.R) | Tema `theme_monitor()`: grilla sólo horizontal y suave, sin marcas ni líneas de eje, leyenda horizontal arriba sin caja, títulos en negrita, fondo de panel beige `#EDE8E0` (réplica del *Monitor Mensual de Empresas* de Fundar). |
| `FUNDAR_MULTI` (en el tema) | Paleta regional: Resto país `#A8DCC8` · NOA-Resto `#C8C87A` · **La Rioja `#2D6E6E`** (énfasis por luminancia). `FUNDAR_SECTOR` para público/privado. |
| `scale_color_fundar_multi()` / `scale_fill_fundar_multi()` | Aplicación consistente de la paleta. |
| Ficha metodológica por indicador (en el `.Rmd`) | Principio 2 de Tufte: etiquetas y contexto. |
| [`clases/materiales/checklist_visualizacion.md`](../clases/materiales/checklist_visualizacion.md) | Lista de control de una página para usar al armar o revisar un gráfico. |

**Buenas prácticas ya incorporadas** (se listan para no perderlas en futuras
ediciones):

- Facetado con escala compartida como opción por defecto.
- Índices base 100 en lugar de nominales o de doble eje (PBG 2004=100,
  per cápita 2010=100, exportaciones 2015=100, salario real ene-2025=100).
- Facetado con ejes libres (`free_y`) para escalas regionales inconciliables
  (exportaciones totales, participación, empresas, puestos), en vez de un eje
  compartido que aplastaría la serie riojana.
- Deflactación + desestacionalización en el salario real.
- Marca explícita del quiebre metodológico EPH 2016 (`geom_vline` punteada).
- Capa de anotación sobria: punto + etiqueta sólo en el último valor de cada
  serie; líneas de referencia en 100 (índices) y en 0 (resultado fiscal).

## 1.11. Decisiones abiertas y trabajo futuro

Hoja de ruta de mejoras de integridad visual, en orden aproximado de prioridad.
Ninguna bloquea el uso del Monitor; todas están acotadas.

1. **Indicador 03 (salarios SIPA), lectura nominal.** La sección presenta
   primero la serie en **pesos corrientes** (para *rankings* provinciales del
   mismo mes) y luego la serie real en índice. En una serie de tiempo, los
   pesos corrientes muestran sobre todo inflación (Playfair; [1.5](#15-variación-en-los-datos-no-en-el-diseño)).
   *Acción:* que la **lectura principal** de la evolución sea la serie real /
   índice; reservar el nominal para la tabla de *ranking* de un mes puntual.

2. **Familia EPH — eje X.** `04_desoc.R`, `09a_informalidad_aportes.R`,
   `10_tasa_empleo.R`, `12_educ.R`, `13a_nbi_hogares.R`, `13b_nbi_poblacion.R`
   usan `scale_x_discrete()` sobre el *string* `"YYYY-Qn"` y limitan las marcas
   a Q1/Q3 (≈ 36 marcas para ~18 años, rotadas 45°). Sigue por encima de las
   6–8 marcas recomendadas y sigue siendo un eje **categórico**.
   *Acción:* `lubridate::yq()` + `scale_x_date(date_breaks = "2 years")`.
   Parametrizar además la rotación del eje X en `theme_monitor()` (hoy 45°
   fijo).

3. **Auditoría de la paleta `FUNDAR_MULTI`.** Nunca se proyectó a CAM02-UCS ni
   se verificó con simulación de daltonismo. Puntos a revisar: (a) uniformidad
   perceptual (retomar `src/test_escalas.R`, que quedó a medias); (b) contraste
   entre las dos series de contexto (`#A8DCC8` verde menta y `#C8C87A` oliva
   tienen luminancia parecida y podrían confundirse en impresión B/N o con
   deuteranopía); (c) verificación con `colorspace::deutan()` / `protan()`.

4. **Barras apiladas al 100 % para «parte de un todo».** `15_pbg_estructura` y
   `06_empleados_publicos_composicion` (×2) usan barra apilada. La taxonomía de
   Argendata recomienda **waffle** (corte transversal) o **waffle facetado /
   slope** (serie de tiempo). La decisión es analítica: ¿interesan las
   variaciones chicas (→ *slope*, mejor canal) o sólo las grandes (→ *waffle*,
   más robusto ante ruido muestral)? — ver caso ENGHo del Informe.

5. **Medidas de variabilidad en indicadores muestrales.** Hoy la variabilidad
   de la EPH (dominio chico, aglomerado La Rioja) se maneja con texto. Evaluar
   `geom_ribbon()` con banda de variabilidad, líneas con intervalo de
   confianza, o boxplots simplificados por grupo. Ejercicio de referencia:
   `clases/clase_2_integridad_y_catalogo/soluciones/`.

6. **Resultado fiscal.** Versión provisoria sobre *ingresos totales APNF*;
   objetivo del Monitor: **% del PBG nominal provincial** (pendiente de la serie
   provincial en consulta con la provincia).

7. **Nuevas herramientas de la taxonomía todavía sin uso** (ver
   [Parte 2.4](#24-herramientas-de-la-taxonomía-todavía-sin-uso-en-el-monitor)):
   Cleveland dot plot para las **6 dimensiones de NBI**; *slope chart* para la
   composición del empleo público entre dos momentos.

---

# PARTE 2 · Taxonomía de elementos gráficos adaptada al Monitor

## 2.1. La taxonomía de Argendata

> Toda visualización tiene por detrás una **tarea analítica**. No todas las
> representaciones son igualmente aptas para todas las tareas. Tres preguntas
> antes de elegir: **¿qué pregunta querés responder? ¿qué tipo de datos tenés?
> ¿qué operación estás haciendo sobre ellos?**

Operaciones habituales detectadas en Argendata: *parte de un todo · rankear
unidades · mostrar brechas · correlacionar variables · analizar
distribuciones*. Cruzadas con el tipo de dato (corte transversal / serie de
tiempo) y la dimensionalidad (cuántas variables, cuántas categorías, cuántos
cortes temporales):

| Operación | Corte transversal | Serie de tiempo |
|---|---|---|
| **Parte de un todo** | *waffle chart* (sin niveles anidados) · **treemap** (con niveles anidados) | *waffle* facetado · *slope chart* |
| **Rankear unidades** | **barras horizontales ordenadas** (1 variable, 1 momento) | *slope chart* (2 momentos) · **bump chart** (muchos momentos) |
| **Correlacionar variables** | **scatter plot** | **líneas facetadas** — una por variable — *nunca doble eje* |
| **Mostrar brechas** | **Cleveland dot plot** | líneas con **brecha implícita** (área entre las dos líneas) |
| **Cambios en el tiempo — 1 categoría** | — | ≤ 5 instancias: *slope* · 5–50: **línea** · > 50: **área** · distribución: líneas con IC |
| **Cambios en el tiempo — 2 a 5 categorías** | — | ≤ 5 instancias: *slope* |
| **Cambios en el tiempo — > 5 categorías** | — | 5–100 instancias: **spaghetti** · hasta 12 categorías / > 100 instancias: **áreas** |

Advertencias transversales del Informe:

- **Ejes desde cero**, salvo líneas facetadas de variaciones relativas.
- **Nunca doble eje** → facetar o índice base 100.
- **6–8 marcas** por eje; sin marcas secundarias.
- Si hay muchas categorías cualitativas, ponerlas en el **eje Y** y la magnitud
  en el **eje X** (facilita la comparación).

## 2.2. Inventario de visualizaciones del Monitor

Las ~29 salidas gráficas del Monitor, agrupadas por familia. Referencias:
`script` en [`src/`](../src/) → `PNG` en `outputs/plots/` → sección del
`.Rmd`.

| # | Gráfico (PNG) | Script | Geometría (ggplot2) | Tipo en taxonomía Argendata | Operación analítica | Ev. |
|---|---|---|---|---|---|:--:|
| 1 | `15_pbg_evolucion` | `15_pbg.R` | `geom_line` + `facet_wrap` (escala fija) | línea (serie de tiempo, 2–5 categorías, 5–50 instancias) + *small multiples* | Cambios en el tiempo, comparación regional de **dinámica** (índice 2004=100) | ✔ |
| 2 | `15_pbg_pct_industrial` | `15_pbg.R` | `geom_line` + `facet_wrap` fija | ídem | Cambios en el tiempo (participación) | ✔ |
| 3 | `15_pbg_estructura` | `15_pbg.R` | `geom_col` apilada (100 %) | *parte de un todo*, corte transversal, con categorías | Composición sectorial del PBG por región | ⚠ (ver [1.11 §4](#111-decisiones-abiertas-y-trabajo-futuro)) |
| 4 | *(evolución estructura)* | `15_pbg.R` | `geom_area` apilada | **áreas** (serie de tiempo, > 50 instancias / > 12 categorías) | Cambios de composición en el tiempo | ✔ (generado; no embebido) |
| 5 | `15_pbg_per_capita_relativo` | `15_pbg_per_capita.R` | `geom_col` horizontal, ordenado, `geom_vline(100)` | **barras horizontales ordenadas** | Rankear 24 jurisdicciones, 1 momento (100 = media nacional) | ✔ |
| 6 | `15_pbg_ranking_percapita` | `15_pbg_ranking_percapita.R` | `geom_line` + `scale_y_reverse`, series destacadas | **bump chart** | Rankear unidades en el tiempo (posición, no nivel) | ✔ |
| 7 | `16_recursos_propios` | `16_recursos_propios.R` | `geom_line` + `facet_wrap` fija | línea + *small multiples* | Cambios en el tiempo (ratio TOP/(TOP+RON)) | ✔ |
| 8 | `17_resultado_fiscal` | `17_resultado_fiscal.R` | `geom_line` + `geom_hline(0)` + `facet_wrap` fija | línea + *small multiples* | Cambios en el tiempo; 0 como referencia (déficit/superávit) | ✔ |
| 9 | `17_resultado_fiscal_primario` | `17_resultado_fiscal.R` | ídem | ídem | ídem (resultado primario) | ✔ |
| 10 | `14_exportaciones_totales_region` | `14_exportaciones_subrubros.R` | `geom_line` + `facet_wrap` **`free_y`** | **líneas facetadas** (evita doble eje / eje compartido que aplasta) | Niveles con escalas regionales muy dispares | ✔ |
| 11 | `14_exportaciones_indice_2015_region` | `14_exportaciones_indice.R` | `geom_line` + `geom_hline(100)` | línea, índice base 100 | Cambios en el tiempo, **dinámica** comparable | ✔ |
| 12 | `14_exportaciones_share_nacional_region` | `14_exportaciones_indice.R` | `geom_line` + `facet_wrap` `free_y` | líneas facetadas | Participación en el total nacional | ✔ |
| 13 | `14_exportaciones_treemap_subrubros_facet` | `14_exportaciones_subrubros.R` | `geom_treemap` + `facet_wrap`, `scale_fill_gradient` | **treemap** (parte de un todo, estructura anidada) | Composición de la canasta exportadora por región | ✔ (área = canal débil; cuidar escala de color) |
| 14 | *(treemap con subgrupos)* | `14_exportaciones_subrubros.R` | `geom_treemap` + `geom_treemap_subgroup_*` | treemap jerárquico | Composición con agrupamiento | ✔ (generado; variante) |
| 15 | *(heatmap subrubros)* | `14_exportaciones_subrubros.R` | `geom_tile` + `geom_text`, `scale_fill_gradient` | *heatmap* / matriz categoría × año (no explícito en la taxonomía) | Evolución del *share* por subrubro | ⚠ (usar escala secuencial uniforme; verificar ΔE) |
| 16 | `11_empresas_jurisdiccion` | `07_cant_empresas.R` | `geom_line` + `facet_wrap` `free_y` | líneas facetadas | Cambios en el tiempo, escalas dispares | ✔ |
| 17 | `12_educ` | `12_educ.R` | `geom_line`, `scale_x_discrete` (Q1/Q3) | línea (serie de tiempo, 2–5 categorías) | Cambios en el tiempo (% +25 con superior) | ⚠ eje X (ver [1.11 §2](#111-decisiones-abiertas-y-trabajo-futuro)) |
| 18 | `18_trayectoria_escolar` | `18_trayectoria_escolar.R` | `geom_point` en grilla 10×10 | **waffle chart** (KPI, parte de un todo, 1 distribución) | «77 de cada 100 llegan a 5.º año» | ✔ |
| 19 | `18_trayectoria_escolar_matricula` | `18_trayectoria_escolar.R` | `geom_col` vertical | barras (niveles) | Matrícula por etapa de la cohorte | ✔ |
| 20 | `18_trayectoria_escolar_desagregada` | `18_trayectoria_escolar.R` | `geom_col` por grupo | barras (comparación categórica, corte transversal) | Trayectoria por sexo y sector | ✔ |
| 21 | `13a_nbi_hogares` | `13a_nbi_hogares.R` | `geom_line`, `scale_x_discrete` (Q1/Q3) | línea (serie de tiempo, 2–5 categorías) | Cambios en el tiempo (% hogares con NBI) | ⚠ eje X · variabilidad sólo verbal |
| 22 | `13b_nbi_poblacion` | `13b_nbi_poblacion.R` | ídem | ídem | % población en hogares con NBI | ⚠ ídem |
| 23 | `04_desoc` | `04_desoc.R` | `geom_line`, `scale_x_discrete` (Q1/Q3), `ylim(0,20)` | línea (serie de tiempo, 2–5 categorías, > 50 instancias) | Cambios en el tiempo (tasa de desocupación) | ⚠ eje X |
| 24 | `10_tasa_empleo` | `10_tasa_empleo.R` | ídem | ídem | Tasa de empleo | ⚠ eje X |
| 25 | `09a_informalidad_aportes` | `09a_informalidad_aportes.R` | ídem | ídem | Tasa de informalidad por aportes | ⚠ eje X |
| 26 | `03_salarios_privados_SIPA` | `03_salarios_privados_SIPA.R` | `geom_line` + `geom_point` + `geom_text_repel`, `scale_x_date` | línea (serie de tiempo) | Nivel/evolución del salario nominal + *ranking* provincial | ⚠ **pesos corrientes** (ver [1.11 §1](#111-decisiones-abiertas-y-trabajo-futuro)) |
| 27 | `03_salarios_privados_SIPA_real_sa_indice` | `03_salarios_privados_SIPA_indice.R` | `geom_line` + `geom_hline(100)` | línea, índice base 100 (real, desestacionalizado) | Evolución del poder de compra | ✔ |
| 28 | `03b_salarios_registrados_EPH` | `03b_salarios_registrados_EPH.R` | `geom_line` + `geom_vline(2016)` + `facet_wrap` `free_y` | líneas facetadas + marca de quiebre de serie | Salario público vs. privado por región | ✔ (podría ser *brecha implícita* — ver 2.3.K) |
| 29 | `05_puestos_asalariados_privados` | `05_puestos_asalariados_privados.R` | `geom_line` + `facet_wrap` `free_y` | líneas facetadas | Cambios en el tiempo, escalas dispares | ✔ |
| 30 | `06_empleados_publicos_cada_1000_hab` | `06_empleados_publicos.R` | `geom_line` + `geom_point` | línea (serie de tiempo, 2–5 categorías, ≤ 50 instancias) | Cambios en el tiempo (empleo público c/1000 hab.) | ✔ |
| 31 | `06_empleados_publicos_cada_1000_hab_noa` | `06_empleados_publicos.R` | `geom_line`, 6 provincias, La Rioja destacada | próximo a **spaghetti** (muchas categorías, una resaltada) | Comparación intra-NOA con foco en La Rioja | ✔ |
| 32 | `06_empleados_publicos_composicion` | `06_empleados_publicos_composicion.R` | `geom_col` apilada 100 % + `facet_wrap` | *parte de un todo*, serie de tiempo | Composición del empleo público por rama | ⚠ (candidato a *waffle* facetado / *slope*) |
| 33 | `06_empleados_publicos_composicion_ultimo` | `06_empleados_publicos_composicion.R` | `geom_col` apilada 100 %, 1 momento | *parte de un todo*, corte transversal | Composición por rama, último año | ⚠ (candidato a *waffle*) |

**Lectura del inventario.** El Monitor cubre bien **cambios en el tiempo**
(líneas, con y sin facetado; índices base 100), **rankear unidades** (barras
horizontales ordenadas, *bump chart*) y tiene un uso puntual y correcto de
**treemap** y **waffle**. Las tensiones se concentran en tres focos: eje X de
la familia EPH, serie nominal en el indicador 03, y barras apiladas donde la
taxonomía sugiere *waffle* / *slope*.

## 2.3. Fichas por familia de gráfico

Formato: **qué es · dónde se usa · match con Argendata · checklist propio ·
riesgos**.

### A. Líneas multiserie con *small multiples* (escala compartida)

- **Qué es.** Un panel por categoría (aquí: región), mismos ejes y misma escala
  Y, para comparar dinámicas.
- **Dónde.** PBG, % industrial, recursos propios, resultado fiscal (×2).
- **Match Argendata.** «Cambios en el tiempo, 2–5 categorías, 5–50 instancias»
  → **línea**, potenciada con **small multiples** (respuesta por defecto al
  *cluttering*).
- **Checklist.** ☐ misma escala Y en todos los paneles ☐ 6–8 marcas en X ☐
  eje Y desde cero (o índice, con `hline` de referencia) ☐ La Rioja en
  `#2D6E6E` ☐ etiqueta sólo en el último punto.
- **Riesgos.** Si una serie tiene un rango muy distinto, la escala compartida
  la aplana → recién ahí pasar a `free_y` (familia C) y avisarlo.

### B. Líneas multiserie en un panel único

- **Qué es.** Todas las series en el mismo panel, diferenciadas por color.
- **Dónde.** Desempleo, empleo, informalidad, educación superior, NBI (×2),
  empleo público c/1000, exportaciones índice.
- **Match Argendata.** «Cambios en el tiempo, 2–5 categorías» → **línea**. Con
  3 series bien contrastadas, superponer es legible y no hace falta facetar.
- **Checklist.** ☐ ≤ 5 series ☐ contraste de luminancia suficiente entre
  series ☐ 6–8 marcas en X ☐ leyenda arriba, sin caja.
- **Riesgos.** A partir de 4–5 series o si se cruzan mucho, pasar a facetado o
  a *spaghetti* (familia E).

### C. Líneas facetadas con ejes libres (`free_y`)

- **Qué es.** Un panel por categoría, **cada uno con su propia escala Y**.
- **Dónde.** Exportaciones totales y participación, cantidad de empresas,
  salarios EPH, puestos asalariados privados.
- **Match Argendata.** **«Líneas facetadas — nunca doble eje»**. Es la
  alternativa canónica cuando las series tienen escalas inconciliables (La
  Rioja exporta cientos de millones; el resto del país, decenas de miles de
  millones).
- **Checklist.** ☐ el texto aclara que **las escalas Y no son comparables entre
  paneles** ☐ se compara **forma/dinámica**, no nivel ☐ orden de paneles con
  sentido (La Rioja primero o último, consistente).
- **Riesgos.** El lector puede creer que compara niveles. Mitigación: subtítulo
  explícito + complementar con una vista en índice base 100 (familia D), como
  ya hace la sección de exportaciones.

### D. Líneas en índice base 100

- **Qué es.** Cada serie reexpresada como `100 × valorₜ / valor_base`.
- **Dónde.** PBG (2004=100), PBG per cápita (2010=100), exportaciones
  (2015=100), salario real (ene-2025=100).
- **Match Argendata.** Recomendación explícita como **alternativa al doble eje**
  y para homologar unidades entre series con rangos muy distintos. Habilita la
  **única excepción** a «eje desde cero».
- **Checklist.** ☐ `geom_hline(yintercept = 100)` de referencia ☐ año base en
  el subtítulo ☐ se lee como «X % por encima/debajo del año base» ☐ no se
  mezcla con lectura de nivel absoluto en el mismo gráfico.
- **Riesgos.** Elección del año base: si el año base es atípico, distorsiona
  toda la lectura. Documentar por qué se eligió.

### E. Líneas tipo *spaghetti* (muchas categorías, una resaltada)

- **Qué es.** Una línea por unidad; la unidad de interés en color saturado, el
  resto en gris de contexto.
- **Dónde.** Empleo público c/1000 en las 6 provincias del NOA (La Rioja
  resaltada). Uso incipiente.
- **Match Argendata.** **spaghetti plot** — «5–100 instancias temporales,
  muchas categorías, una destacada y el resto en gris».
- **Checklist.** ☐ series de contexto en gris claro, sin leyenda individual ☐
  serie destacada con color + etiqueta ☐ no más de 1–2 destacadas.
- **Oportunidad.** Aplicable a las 24 jurisdicciones en varios indicadores hoy
  facetados (puestos asalariados, empresas) usando índice base 100 — ejercicio
  `clase_2/.../03_spaghetti_puestos.R`.

### F. *Bump chart*

- **Qué es.** Evolución de la **posición en un *ranking***, no del nivel. Eje Y
  = puesto (invertido); una línea por unidad.
- **Dónde.** Ranking del PBG per cápita provincial, 24 jurisdicciones,
  2010–último año.
- **Match Argendata.** **bump chart** — «rankear unidades, serie de tiempo,
  muchos momentos».
- **Checklist.** ☐ eje Y invertido (`scale_y_reverse`), 1 = arriba ☐ grupos de
  interés resaltados (La Rioja + NOA en verde, resto en gris) ☐ el texto aclara
  que se sigue **la posición**, no el valor ☐ etiquetas de unidad a los
  costados.
- **Riesgos.** Con muchas unidades cerca en el *ranking*, el cruce de líneas
  satura. Mitigación: resaltar sólo lo que se analiza.

### G. Barras horizontales ordenadas

- **Qué es.** Ranking de unidades por una variable, **un momento**, ordenado
  por la variable (no alfabéticamente).
- **Dónde.** PBG per cápita relativo a la media nacional (24 provincias,
  `geom_vline` en 100).
- **Match Argendata.** **barras horizontales ordenadas** — «rankear unidades,
  corte transversal, una variable».
- **Checklist.** ☐ orden por la variable ☐ eje X desde cero ☐ unidad de interés
  resaltada por color (en este gráfico, La Rioja en `#E4572E` sobre gris
  `#9CA3AF`) ☐ variable cualitativa en Y, magnitud en X.
- **Riesgos.** Eje X que no arranca en cero (barras engañan por longitud).

### H. Barras verticales simples

- **Qué es.** Magnitud por categoría, pocas categorías, un momento.
- **Dónde.** Matrícula por etapa de la cohorte; trayectoria por sexo/sector.
- **Match Argendata.** No tiene ficha propia; es el caso base. Aceptable con
  pocas categorías y eje desde cero.
- **Checklist.** ☐ eje Y desde cero ☐ ≤ ~8 categorías ☐ sin 3D, sin degradado
  ☐ no combinar con puntos/líneas para la misma variable.

### I. Barras apiladas al 100 % (parte de un todo)

- **Qué es.** Composición porcentual; segmentos apilados que suman 100 %.
- **Dónde.** Estructura productiva del PBG; composición del empleo público por
  rama (evolución y último año).
- **Match Argendata.** La operación es **parte de un todo**, para la cual la
  taxonomía recomienda **waffle** (transversal) o **waffle facetado / slope**
  (serie de tiempo). La barra apilada 100 % es una solución intermedia: legible
  para el segmento de base, pero los segmentos «del medio» no tienen línea de
  referencia común (peor canal).
- **Checklist.** ☐ ≤ ~6 segmentos (agrupar el resto) ☐ orden de segmentos
  estable entre barras ☐ paleta cualitativa con agrupamiento semántico ☐
  etiquetas de valor en los segmentos grandes.
- **Trabajo futuro.** Evaluar *waffle* facetado o *slope* según si importan las
  variaciones chicas (ver [1.11 §4](#111-decisiones-abiertas-y-trabajo-futuro)).

### J. Áreas apiladas

- **Qué es.** Como la barra apilada pero en continuo temporal.
- **Dónde.** Evolución de la estructura productiva (generado en `15_pbg.R`, no
  embebido en el `.html` actual).
- **Match Argendata.** **área** — «cambios en el tiempo, > 50 instancias» o
  «> 12 categorías».
- **Checklist.** ☐ orden de capas estable y con lógica (sectores afines
  juntos) ☐ ≤ ~6–7 capas ☐ eje Y hasta 100 % ☐ no usar si importa el valor
  exacto de una capa intermedia año a año.

### K. Treemap

- **Qué es.** Rectángulos anidados; **área ∝ valor**; jerarquía por
  subdivisión.
- **Dónde.** Composición de las exportaciones por subrubro, facetado por
  región; variante con bordes de subgrupo.
- **Match Argendata.** **treemap** — «parte de un todo, con niveles anidados».
- **Checklist.** ☐ se usa por la **estructura jerárquica**, no para lectura de
  magnitud precisa (área = canal débil) ☐ escala de color: si el *fill* mapea
  una cantidad, **secuencial y perceptualmente uniforme** ☐ etiquetas de
  subgrupo legibles ☐ la categoría «no desagregado / resto» explicitada.
- **Riesgos.** Comparar tamaños de rectángulos no contiguos es impreciso;
  complementar con el texto (top-3 subrubros, % de concentración) como ya hace
  la sección.

### L. *Heatmap* / matriz categoría × tiempo (`geom_tile`)

- **Qué es.** Grilla categoría (Y) × año (X); color de celda ∝ valor.
- **Dónde.** *Share* de los principales subrubros exportados de La Rioja,
  2015–2025 (celdas vacías = no publicado).
- **Match Argendata.** No tiene ficha propia. Se rige por las reglas de
  **escalas ordenadas**: color **secuencial**, **uniforme** (ΔE), legible con
  daltonismo.
- **Checklist.** ☐ escala secuencial (no *jet*, no arcoíris) ☐ leyenda de color
  con unidad ☐ celdas faltantes marcadas de forma distinta al cero ☐ orden de
  filas con sentido (por magnitud o por afinidad).

### M. *Waffle chart* (KPI de parte de un todo)

- **Qué es.** Grilla 10×10 = 100 unidades; cuadrados/puntos coloreados ∝
  proporción.
- **Dónde.** Trayectoria escolar: «de cada 100 que empiezan 1.er grado, 77
  llegan a 5.º año».
- **Match Argendata.** **waffle chart** — preferido sobre la torta porque
  codifica en **posición/conteo** (mejor canal) y los estudios perceptuales
  (Kosara, 2016) muestran errores menores.
- **Checklist.** ☐ 100 celdas exactas ☐ 1 color por categoría ☐ redondeo
  honesto (77/100, no 76,8) ☐ el subtítulo explica la cohorte y qué mide (y qué
  **no** mide: no es egreso con título).
- **Oportunidad.** Formato natural para varios KPI del Monitor (% con NBI, % con
  superior completo) en cabecera de sección.

### N. Capa de anotación (transversal)

- **Qué es.** Elementos que no son la geometría principal: `geom_point` +
  `geom_text_repel` en el último valor, `geom_hline` (100 en índices, 0 en
  resultado fiscal), `geom_vline` (quiebre de serie 2016 en salarios EPH).
- **Match Argendata.** «Agregar leyendas, títulos, marcas y anotaciones que
  amplíen la interpretación, **siempre que no generen aglomeramiento**» +
  «marcar quiebres y cambios de metodología».
- **Checklist.** ☐ etiqueta sólo en puntos clave (último valor, hitos), no en
  todos ☐ líneas de referencia finas y grises ☐ todo elemento no obvio
  (diagonal, área sombreada, línea de corte, línea punteada) explicado en
  *caption* o nota al margen ☐ `geom_text_repel` para evitar solapamiento.

## 2.4. Herramientas de la taxonomía todavía sin uso en el Monitor

| Herramienta | Operación que resuelve | Dónde encajaría en el Monitor |
|---|---|---|
| **Cleveland dot plot** | Brechas / *ranking* con muchas categorías (posición sobre escala común, ocupa poco) | Las **6 dimensiones de NBI** (hacinamiento, vivienda, saneamiento, escolaridad, subsistencia, total) en un momento; comparación provincial en un año. Ejercicio: `clase_2/.../01_cleveland_nbi.R`. |
| ***Slope chart*** | Cambios entre **2 momentos** para varias categorías (≤ 5 instancias) | Composición del empleo público por rama entre dos años; estructura productiva inicio vs. fin. |
| **Scatter plot** | Correlación entre 2 variables cuantitativas (corte transversal) | Empleo público c/1000 vs. empleo privado formal; salario real vs. informalidad, por provincia. |
| **Líneas con brecha implícita** (`geom_ribbon`) | Evolución de una **brecha** entre 2 categorías (el área entre líneas se lee de forma preatentiva) | Salario público vs. privado (hoy familia C); brecha La Rioja – NOA en cualquier tasa. Ejercicio: `clase_2/.../02_brecha_salarios.R`. |
| **Líneas con intervalo de confianza / banda de variabilidad** | Variación de una distribución en el tiempo | Toda la familia EPH (dominio muestral chico) — hoy la incertidumbre se maneja con texto. |
| ***Spaghetti* canónico** | > 5 categorías, 5–100 instancias, una destacada | 24 jurisdicciones en índice base 100 (puestos, empresas, salarios). |
| ***Waffle* facetado** | Parte de un todo en el tiempo (pocas instancias) | Composición del empleo público / estructura productiva, en lugar de barras apiladas. |

## 2.5. Matriz resumen: indicador × operación × herramienta

| Indicador (Monitor) | Operación analítica dominante | Herramienta actual | Herramienta canónica (Argendata) | ¿Coinciden? |
|---|---|---|---|:--:|
| PBG provincial (dinámica) | Cambios en el tiempo, 3 regiones | líneas + *small multiples* + índice 100 | línea (5–50 inst.) + *small multiples* | ✔ |
| PBG per cápita relativo | Rankear unidades, 1 momento | barras horizontales ordenadas | barras horizontales ordenadas | ✔ |
| PBG per cápita — ranking | Rankear unidades en el tiempo | *bump chart* | *bump chart* | ✔ |
| % PBG industrial | Cambios en el tiempo | líneas + *small multiples* | línea | ✔ |
| Estructura productiva del PBG | Parte de un todo | barras apiladas 100 % / áreas | *waffle* / *waffle* facetado / áreas | ~ |
| Exportaciones (nivel) | Niveles con escalas dispares | líneas facetadas `free_y` | líneas facetadas (no doble eje) | ✔ |
| Exportaciones (dinámica) | Cambios en el tiempo | líneas índice 2015=100 | línea / índice | ✔ |
| Exportaciones (composición) | Parte de un todo, anidada | *treemap* facetado (+ *heatmap*) | *treemap* | ✔ |
| Cantidad de empresas | Cambios en el tiempo, escalas dispares | líneas facetadas `free_y` | líneas facetadas | ✔ |
| Recursos propios / totales | Cambios en el tiempo | líneas + *small multiples* | línea | ✔ |
| Resultado fiscal (APNF) | Cambios en el tiempo, 0 = referencia | líneas + `hline(0)` + facetado | línea | ✔ |
| Educación superior +25 | Cambios en el tiempo (EPH) | líneas, eje X categórico | línea (eje temporal, 6–8 marcas) | ~ (eje X) |
| Trayectoria escolar (KPI) | Parte de un todo | *waffle* | *waffle* | ✔ |
| Trayectoria — matrícula / desagregada | Niveles / comparación categórica | barras verticales | barras | ✔ |
| NBI hogares / población | Cambios en el tiempo (EPH) | líneas, eje X categórico | línea + (banda de variabilidad) | ~ (eje X, variabilidad) |
| Tasa de desempleo | Cambios en el tiempo (EPH) | líneas, eje X categórico | línea / área (> 50 inst.) | ~ (eje X) |
| Tasa de empleo | Cambios en el tiempo (EPH) | líneas, eje X categórico | línea | ~ (eje X) |
| Tasa de informalidad (aportes) | Cambios en el tiempo (EPH) | líneas, eje X categórico | línea | ~ (eje X) |
| Salario privado SIPA (nominal) | Nivel + *ranking* mensual | líneas, pesos corrientes | serie real / índice + tabla de *ranking* | ~ (nominal) |
| Salario privado SIPA (real) | Cambios en el tiempo (poder de compra) | líneas índice ene-2025=100, SA + deflactado | línea / índice | ✔ |
| Salario registrado EPH (púb./priv.) | Brecha entre 2 categorías en el tiempo | líneas facetadas + marca de quiebre | líneas con brecha implícita | ~ (candidato a *ribbon*) |
| Puestos asalariados privados | Cambios en el tiempo, escalas dispares | líneas facetadas `free_y` | líneas facetadas / *spaghetti* índice | ✔ |
| Empleados públicos c/1000 hab. | Cambios en el tiempo, 3 regiones | líneas + puntos | línea | ✔ |
| Empleados públicos — NOA | Comparación de unidades, una destacada | líneas, La Rioja resaltada | *spaghetti* | ✔ |
| Empleo público — composición por rama | Parte de un todo (transversal y temporal) | barras apiladas 100 % (+ facetado) | *waffle* / *waffle* facetado / *slope* | ~ |

Leyenda: **✔** coincide · **~** coincide parcialmente, con acción en la hoja de
ruta de [1.11](#111-decisiones-abiertas-y-trabajo-futuro).

---

# Anexo

## Glosario

- **Canal (visual).** Propiedad estética de una marca gráfica usada para
  codificar datos: posición, longitud, ángulo, área, color, forma, tamaño.
- **Corte transversal.** Datos de muchas unidades en un mismo momento.
- **Factor de mentira (*lie factor*).** Cociente entre el tamaño del efecto en
  el gráfico y en los datos. Ideal = 1.
- **Índice base 100.** Serie reexpresada respecto de un año/período de
  referencia (`100 × valorₜ / valor_base`).
- **Small multiples / facetado.** Grilla de gráficos chicos con estructura
  idéntica, un panel por categoría.
- **Uniformidad perceptual.** Propiedad de una escala de color en la que pasos
  iguales en los datos se perciben como pasos iguales de color (medido en
  CAM02-UCS con distancia ΔE).
- **Chart junk.** Elementos decorativos sin función informativa.
- **Visual cluttering.** Saturación por exceso de elementos, aun informativos.

## Bibliografía

- Cleveland, W. S., & McGill, R. (1984). Graphical perception: Theory,
  experimentation, and application to the development of graphical methods.
  *Journal of the American Statistical Association*, 79(387), 531–554.
- Healy, K. (2019). *Data visualization: A practical introduction.* Princeton
  University Press.
- Kosara, R. (2016). *A reanalysis of a study about (square) pie charts from
  2009.* eagereyes.org.
- Kosara, R., & Ziemkiewicz, C. (2010). Do Mechanical Turks dream of square pie
  charts? *BELIV '10*, 63–70.
- Munzner, T. (2014). *Visualization analysis & design.* CRC Press.
- Quinan, P. S., Padilla, L. M., Creem-Regehr, S. H., & Meyer, M. (2019).
  Examining implicit discretization in spectral schemes. *Computer Graphics
  Forum*, 38(3), 363–374.
- Rosati, G. (2024). *Evaluación, análisis y propuesta de mejoras del sistema
  de visualizaciones de Argendata. Informe final.* STAN–CONICET para Fundar.
  ([`clases/materiales/Informe_final_argendata.pdf`](../clases/materiales/Informe_final_argendata.pdf))
- Tufte, E. R. (1983). *The visual display of quantitative information.*
  Graphics Press.
- Tufte, E. R. (1990). *Envisioning information.* Graphics Press.
- Tufte, E. R. (1997). *Visual explanations.* Graphics Press.

## Correspondencia de archivos

| Recurso | Ubicación |
|---|---|
| Monitor (documento) | [`informe/monitor_la_rioja_tufte_fundar.Rmd`](monitor_la_rioja_tufte_fundar.Rmd) → `.html` |
| Tema y paleta | [`style/fundar_monitor_theme.R`](../style/fundar_monitor_theme.R) |
| CSS del informe | [`informe/monitor_estilo_tufte_fundar.css`](monitor_estilo_tufte_fundar.css) |
| Scripts de visualización | [`src/`](../src/) (`03`–`18`, prefijo por indicador) |
| PNG generados | `outputs/plots/` |
| Checklist operativo | [`clases/materiales/checklist_visualizacion.md`](../clases/materiales/checklist_visualizacion.md) |
| Guion de la Clase 2 (integridad y catálogo) | [`clases/clase_2_integridad_y_catalogo/guion.md`](../clases/clase_2_integridad_y_catalogo/guion.md) |
| Test de escalas (a completar) | `src/test_escalas.R` |

---

*Documento elaborado para la Etapa 2 del Componente 3. Última revisión:
septiembre 2026.*
