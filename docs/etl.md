# ETL — Extracción de indicadores

Módulo encargado de obtener, limpiar y estructurar los datos de los indicadores
económicos publicados por el CES Santa Fe.

**Archivo:** `etl/1_extract.R`

---

## Flujo general

```
[Web CES - Excel]          [Web CES - HTML]
       │                          │
  download_excel()          extract_resumen()
       │                          │
  extract_metadata()              │
  extract_serie()                 │
  infer_frecuencia()              │
       │                          │
       └──────────┬───────────────┘
                  │
          process_indicator()
                  │
          load_all_indicators()
                  │
        ┌─────────┴──────────┐
  $indicadores tibble    $datos tibble
```

---

## Fuentes de datos

| Recurso | URL | Uso |
|---------|-----|-----|
| API GitHub | `https://api.github.com/repos/ces-bcsf/CicSFE_GitHub/contents/indicadores` | Listar dinámicamente los códigos de todos los indicadores disponibles |
| Excel   | `{BASE_URL}/{codigo}_out.xlsx` | Metadatos + serie de datos |
| HTML    | `{BASE_URL}/{codigo}_views.html` | Resumen de coyuntura |

`BASE_URL = https://ces-bcsf.github.io/CicSFE_GitHub/indicadores`

Los archivos se publican y actualizan todos los lunes.
El ETL se ejecuta automáticamente cada lunes via GitHub Actions. Ver `docs/ci-cd.md`.

---

## Estructura del Excel

**Hoja `Portada`** (`col_names = FALSE`):

| Celda | Campo |
|-------|-------|
| fila 2, col 3 | nombre |
| fila 3, col 3 | unidad_medida |
| fila 4, col 3 | fuente |
| fila 6, col 3 | id |

**Hoja `Data`**:

| Columna | Campo |
|---------|-------|
| 1 (A)   | fecha |
| 13 (M)  | g_final — datos filtrados (los únicos que se usan) |

---

## Estructura del HTML

El resumen de coyuntura se extrae del primer `div.info-box` que aparece
después del `h2` con texto `"Resumen de coyuntura"`.

---

## Salida

### `$indicadores`
Un tibble con una fila por indicador:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | chr | Código del indicador (ej: `"ARG-IL5"`) |
| `nombre` | chr | Nombre completo |
| `unidad_medida` | chr | Unidad (ej: `"%"`, `"millones $"`) |
| `fuente` | chr | Organismo fuente del dato |
| `fecha_ultimo_dato` | Date | Fecha de la última observación disponible |
| `frecuencia` | chr | `"mensual"`, `"trimestral"`, `"anual"`, etc. |
| `resumen_coyuntura` | chr | HTML interno del div.info-box (preserva `.data-positive`/`.data-negative`) |

### `$datos`
Un tibble con una fila por observación:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_indicador` | chr | FK hacia `$indicadores$id` |
| `fecha` | Date | Fecha de la observación |
| `valor` | dbl | Valor del indicador (sin NAs) |

---

## Referencia de funciones

### `load_all_indicators(codigos)`
Función principal. Recibe el vector `INDICADORES` y retorna la lista con
`$indicadores` y `$datos`.

### `process_indicator(codigo)`
Orquesta la extracción de un solo indicador: descarga el Excel, extrae
metadatos y serie, deriva campos calculados, y borra el archivo temporal.

### `extract_metadata(path)`
Lee la hoja `Portada` del Excel y retorna un tibble de 1 fila con los
campos base del indicador.

### `extract_serie(path, id_indicador)`
Lee la hoja `Data`, selecciona fecha y `g_final`, descarta NAs y retorna
el tibble de observaciones.

### `extract_resumen(html)`
Extrae el HTML interno del `div.info-box` asociado al resumen de coyuntura.
Retorna HTML (no texto plano) para preservar el markup de colores de variaciones
(`.data-positive`, `.data-negative`). Retorna `NA` si no encuentra el nodo.

### `infer_frecuencia(fechas)`
Calcula la mediana de días entre fechas consecutivas y la clasifica:

| Mediana (días) | Frecuencia inferida |
|----------------|---------------------|
| ≤ 10 | semanal |
| ≤ 45 | mensual |
| ≤ 100 | trimestral |
| ≤ 200 | semestral |
| > 200 | anual |

### `download_excel(url)` / `build_excel_url(codigo)` / `build_html_url(codigo)`
Utilidades internas. El Excel se descarga a un archivo temporal que se
elimina automáticamente al finalizar `process_indicator()`.

---

## Cómo agregar indicadores

Editar el vector `INDICADORES` en la sección de configuración del archivo:

```r
INDICADORES <- c(
  "ARG-IL5",
  "SFE-RMP",
  "NUEVO-CODIGO"  # agregar acá
)
```

El código del indicador debe coincidir exactamente con el nombre del archivo
en el servidor (sin el sufijo `_out.xlsx`).

---

## Decisiones de diseño

### Formato de salida: RDS

Se eligió RDS (formato nativo de R) porque preserva los tipos exactos (las fechas quedan como `Date`, no como strings), no requiere transformaciones al leer en la Shiny app (`readRDS()` directo), y es más eficiente que CSV o JSON para tibbles. El único costo —no ser portable fuera de R— no aplica porque tanto el ETL como la app son R puros.

### Dos archivos de salida

Refleja la normalización del DER: `indicadores.rds` tiene una fila por indicador (metadatos), `datos.rds` tiene una fila por observación (serie temporal). Tener un solo archivo implicaría repetir los metadatos en cada fila de datos (redundancia) o usar listas anidadas (difíciles de consumir en Shiny). Con dos archivos, la app carga los indicadores para el selector y filtra las observaciones solo cuando el usuario elige uno.

---

## Dependencias

| Paquete | Uso |
|---------|-----|
| `readxl` | Lectura de archivos Excel |
| `dplyr` | Manipulación de tibbles |
| `purrr` | Iteración sobre indicadores |
| `rvest` | Scraping del resumen HTML |
| `utils` | Descarga de archivos |

Todas gestionadas con `renv`. Para instalar: `renv::restore()`.
