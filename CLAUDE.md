# Fundar-La Rioja

## Introducción
- Este es un repositorio para generar información para el Gobierno de la Rioja.
- El objetivo es generar código que permita reproducir una serie de indicadores

## Indicadores
| Indicadores seleccionados                                                                        | TOPICO                                               |
|--------------------------------------------------------------------------------------------------|------------------------------------------------------|
| Tasa de pobreza por NBI (Necesidades Básicas Insatisfechas)                                      | Desarrollo - Pobreza                                 |
| PIB provincial                                                                                   | Macroeconomía - Crecimiento                          |
| Salarios en el sector formal (público y privado)                                                 | Trabajo e ingresos - Salarios e ingresos             |
| Tasa de desempleo (% de la PEA)                                                                  | Trabajo e ingresos - Informalidad y Desempleo        |
| Puestos de trabajo asalariados formales privados totales                                         | Trabajo e ingresos - Salarios e ingresos             |
| Cantidad de empleados públicos Cada 1.000 Hab                                                    | Trabajo e ingresos - Salarios e ingresos             |
| Cantidad de empresas                                                                             | Macroeconomía - Crecimiento                          |
| % del PIB que es industrial                                                                      | Macroeconomía - Crecimiento                          |
| Tasa de informalidad (% de los asalariados)                                                      | Trabajo e ingresos - Informalidad y Desempleo        |
| Tasa de empleo (ocupados cada 100 habitantes)                                                    | Trabajo e ingresos - Trabajo y participación laboral |
| Exportaciones                                                                                    | Macroeconomía - Crecimiento                          |
| % de la población +25 con estudios superiores completos                                          | Desarrollo - Educación                               |
| Trayectoria escolar                                                                              | Desarrollo - Educación                               |
| Resultado fiscal (ingreso total - gasto total)                                                   | Macroeconomía - Crecimiento                          |
| Recursos propios sobre recursos totales (incluyendo coparticipación y transferencias nacionales) | Macroeconomía - Crecimiento                          |

- Los scripts a ejectuar están en "./src/"


## Etapas del proyecto
- Etapa 1. Coordinación inicial y definición de indicadores: Esta etapa tiene como propósito articular el trabajo del Componente 3 con los demás equipos del proyecto. Se propone realizar al menos una reunión de alineación con los equipos de los Componentes 1 y 2 para relevar el listado preliminar de indicadores y su naturaleza (evolución temporal, comparación territorial, distribución, proporción, etc.).
- Etapa 2. Diseño de maquetas: En función de los indicadores definidos en la etapa anterior, se definirá para cada uno el tipo de gráfico más adecuado, la paleta de colores a utilizar y la jerarquía visual de la información. El código se desarrolla en R usando ggplot2 como base, con incorporación de plotly cuando se requieran versiones interactivas para uso web. 
- Etapa 3. Diseño de materiales para talleres de visualización de datos y diseño de maquetas de visualizaciones  

## Tareas a realizar
- Diseñar un pipeline replicable de procesamiento de los siguientes indicadores:
      - Tasa de desempleo (% de la PEA)
      - Tasa de empleo (ocupados cada 100 habitantes)
      - Tasa de informalidad (% de los asalariados)
      - % de la población +25 con estudios superiores completos  
      - % Hogares con NBI
      - % Población con NBI
- Desarrollar el código para el pipeline: para esto, 
      - se deberán descargar los datasets de la EPH usando el paquete `eph`
      - se deberán procesar los datos tomando como base el archivo ./src/00_preproc_EPH.R
- Generar un archivo markdpwn que ejecute los siguientes scripts () que generan
los gráficos estáticos para el informe.

## Definición indicadores NBI (Necesidades Básicas Insatisfechas)
- NBI Hacinamiento (NBI_HAC): hogares que tienen más de tres personas por cuarto.
- NBI Vivienda de tipo inconveniente (NBI_VIV): hogares que viven en inquilinato, hotel o
pensión, viviendas no destinadas a fines habitacionales, viviendas precarias y otro tipo de vivienda.
Se excluye a las viviendas tipo casa, departamento y rancho.
- NBI Condiciones sanitarias (NBI_SAN): hogares que viven en viviendas sin baño o letrina.
-  NBI Escolaridad (NBI_ESC): hogares que tienen al menos un niño en edad escolar (6 a 12 años)
que no asiste a la escuela.
- NBI Capacidad de subsistencia (NBI_SUB): hogares que tienen cuatro o más personas por
miembro ocupado y que tienen un jefe que no ha completado el tercer grado de escolaridad
primaria.
- Necesidades básicas insatisfechas (NBI_TOT): hogares que presentan al menos uno de los
 indicadores anteriores de privación
 