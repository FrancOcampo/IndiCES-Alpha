# CLAUDE.md — Briefing del proyecto IndiCES-Alpha

Este archivo es leído automáticamente por Claude Code al inicio de cada sesión.
Contiene las convenciones, decisiones de arquitectura y restricciones del proyecto.

---

## Qué es este proyecto

Web app interactiva para visualización de indicadores económicos del CES (Centro de
Estudios y Servicios) de Santa Fe, Argentina. Es la tesina de grado de Franco Ocampo
en Ingeniería en Sistemas de Información — UTN Santa Fe.

El sistema tiene dos partes:
1. **ETL** — descarga, limpia y estructura los datos desde la web del CES
2. **App Shiny** — visualiza los datos procesados (MVP funcional)

---

## Stack

| Tecnología | Versión | Uso |
|------------|---------|-----|
| R | 4.5.0 | lenguaje principal |
| renv | 1.1.7 | gestión de dependencias |
| box | — | sistema de módulos (reemplaza `library()`) |
| readxl | — | lectura de Excel |
| dplyr | — | manipulación de datos |
| purrr | — | iteración funcional |
| rvest | — | scraping HTML |
| jsonlite | — | consumo de la API de GitHub |
| Shiny | — | app web (MVP funcional) |
| bslib | — | theming Bootstrap 5 para Shiny |
| plotly | — | gráficos interactivos |
| here | — | resolución de paths desde la raíz del proyecto |

---

## Convenciones de código

### Módulos — usar siempre `box::use()`, nunca `library()` ni `require()`
```r
# CORRECTO
box::use(
  dplyr[tibble, filter],
)

# INCORRECTO
library(dplyr)
```

### Nombres
- Funciones: `snake_case` con verbo al inicio — `extract_metadata()`, `build_url()`
- Variables: `snake_case` — `fecha_ultimo_dato`, `id_indicador`
- Constantes globales: `UPPER_SNAKE_CASE` — `BASE_URL`, `INDICADORES`

### Estilo
- Indentación: 2 espacios
- Pipe: `|>` (nativo de R), no `%>%`
- Documentación de funciones: comentarios `#'` sobre cada función
- Trailing comma en tibbles y listas multilínea: sí (NO en funciones como `plot_ly()` — R no lo permite)

### Archivos temporales
Usar siempre `on.exit(unlink(temp))` para garantizar limpieza, no `finally`.

---

## Arquitectura del ETL (`etl/pipeline-core.R`)

**Fuente de códigos:**
- API de GitHub: `https://api.github.com/repos/ces-bcsf/CicSFE_GitHub/contents/indicadores`
- `fetch_codigos()` filtra los `_out.xlsx` y excluye los `HP_*` (no son series)

**Fuente de datos por indicador:**
- Excel: `https://ces-bcsf.github.io/CicSFE_GitHub/indicadores/{codigo}_out.xlsx`
- HTML:  `https://ces-bcsf.github.io/CicSFE_GitHub/indicadores/{codigo}_views.html`

**Estructura del Excel:**
- Hoja `Portada`: metadatos en col 3, filas 2/3/4/6 (nombre, um, fuente, id)
- Hoja `Data`: col 1 = fecha, col 2 (B) = `g_original` (serie original), col 13 (M) = `g_final` (serie filtrada económicamente)

**Estructura del HTML (`{codigo}_views.html`):**
- `fetch_html(codigo)` descarga y parsea el HTML — llamar una sola vez por indicador y pasar el objeto a las funciones
- `extract_resumen(html)` — div.info-box tras el h2 "Resumen de coyuntura"
- `extract_descripcion(html)`, `extract_codigo_str(html)`, `extract_um_str(html)`, `extract_fuente_primaria_str(html)` — h3 con `<b>Etiqueta</b> | valor` tras el segundo `<hr>`

**Salida — archivos RDS en `data/processed/`:**
- `indicadores.rds`: id, nombre, unidad_medida, fuente, clasificacion_sectorial, fecha_ultimo_dato, frecuencia, resumen_coyuntura, descripcion_str, codigo_str, um_str, fuente_primaria_str
- `datos.rds`: id_indicador, fecha, valor (`g_final`), valor_original (`g_original`) — ambas columnas siempre tienen la misma longitud
- La Shiny app los consume con `readRDS("data/processed/indicadores.rds")`

Ver documentación completa en `docs/etl.md`.

---

## Arquitectura de la App Shiny (`app/`)

**Ejecución:** siempre desde la raíz del proyecto con `shiny::runApp("app")`

**UI custom:** La app usa `htmlTemplate()` con un HTML/CSS/JS propio (estilo Our World in Data).
- `app/www/index.html` — template HTML con placeholders `{{ }}` para los módulos Shiny
- `app/www/styles.css` — CSS responsivo (mobile-first, variables CSS, paleta verde CES #0c4c1c)
- `app/www/app.js` — JS: menú hamburguesa mobile + scrollspy con IntersectionObserver
- `app/www/logo_marca_minima_indicadores_sf.svg` — logo del proyecto (favicon + header + hero)

**Módulos (en `app/modules/`):**
- `data_loader.R` — lógica pura R: carga y filtra los RDS con paths relativos
- `selector_ui.R` — módulo Shiny: dropdown de indicadores con filtro sectorial ("Todas" + sectores). Las clasificaciones que empiezan con "Otros" siempre se ordenan al final (convención `grepl("^Otros", ...)`)
- `chart_ui.R` — módulo Shiny: gráfico plotly con dos trazas — "Datos originales" (gris, punteado) y "Datos filtrados" (negro, sólido). Leyenda horizontal centrada debajo del gráfico
- `metadata_ui.R` — 3 módulos: tarjetas principales, detalle, texto explicativo (coyuntura)
- `acciones_ui.R` — todos los botones (Más información, Descargar PDF, Descargar CSV) viven dentro del `renderUI`, respetan el `req()` y usan íconos SVG homogéneos (Bootstrap Icons)

**Datos:** los RDS se duplican en `app/data/processed/` para deploy a shinyapps.io.

**Layout (scroll vertical, tipo artículo):**
1. Header con navbar (desktop) / hamburguesa (mobile)
2. Hero con logo
3. Selector de indicador
4. Metadata principal (nombre, último dato, frecuencia) en tarjetas
5. Gráfico plotly
6. Botones de acción (PDF, más info, CSV)
7. Detalle (fuente, unidad, frecuencia)
8. Resumen de coyuntura
9. Footer

**Coordinación:** `app.R` ensambla los módulos. Los reactives se pasan como parámetros entre módulos, no hay imports laterales entre ellos.

**Deploy:** shinyapps.io con `rsconnect::deployApp("app", appName = "indicesApp")`

**Cache de box:** al modificar módulos, borrar `AppData/Local/R/cache/R/box` y reiniciar.

---

## Estructura de carpetas

```
IndiCES-Alpha/
├── app/
│   ├── app.R              # punto de entrada (usa htmlTemplate)
│   ├── data/
│   │   └── processed/     # copia de RDS para deploy
│   ├── modules/
│   │   ├── data_loader.R  # carga y filtrado de RDS
│   │   ├── selector_ui.R  # selector de indicadores
│   │   ├── chart_ui.R     # gráfico plotly
│   │   ├── metadata_ui.R  # tarjetas + detalle + texto explicativo
│   │   └── acciones_ui.R  # botones PDF, más info, CSV
│   └── www/
│       ├── index.html     # template HTML custom
│       ├── styles.css     # CSS responsivo
│       └── app.js         # JS menú hamburguesa
├── etl/
│   └── pipeline-core.R    # extracción y estructurado de datos
├── data/
│   └── processed/
│       ├── indicadores.rds  # generado por el ETL
│       └── datos.rds        # generado por el ETL
├── .github/
│   └── workflows/
│       └── etl.yml        # GitHub Actions: ETL automático cada lunes
├── docs/
│   ├── etl.md             # documentación técnica del ETL
│   └── ci-cd.md           # documentación del pipeline de CI/CD
├── renv/                  # librería local de R (no editar)
├── renv.lock              # lockfile de dependencias
├── CLAUDE.md              # este archivo
└── README.md
```

---

## CI/CD

El ETL corre automáticamente cada lunes via GitHub Actions (`.github/workflows/etl.yml`):
1. Ejecuta `etl/pipeline-core.R`
2. Copia los RDS a `app/data/processed/`
3. Commitea los datos si cambiaron
4. Redeploya a shinyapps.io

Requiere tres secrets en el repo: `SHINYAPPS_ACCOUNT`, `SHINYAPPS_TOKEN`, `SHINYAPPS_SECRET`.
Ver documentación completa en `docs/ci-cd.md`.

---

## Git

- Rama de desarrollo activa: crear `feature/<nombre>` desde `develop`
- Flujo: `feature/*` → PR a `develop` → PR a `main`
- Rama principal: `main`
- Los PRs van de `develop` → `main`
- Commits en español, descriptivos, sin `--no-verify`

---

## Lo que NO hacer

- No usar `library()` ni `require()` — siempre `box::use()`
- No usar `%>%` — usar el pipe nativo `|>`
- No leer datos desde archivos locales en el ETL — todo viene de URLs
- No dejar archivos temporales sin limpiar
- No modificar nada dentro de `renv/` manualmente
- No commitear sin que el usuario lo pida explícitamente
- Cuando se modifique el ETL, regenerar los RDS y copiarlos a `app/data/processed/`:
  ```r
  source("etl/pipeline-core.R")
  file.copy("data/processed/indicadores.rds", "app/data/processed/indicadores.rds", overwrite = TRUE)
  file.copy("data/processed/datos.rds",       "app/data/processed/datos.rds",       overwrite = TRUE)
  ```
