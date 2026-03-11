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

## Arquitectura del ETL (`etl/1_extract.R`)

**Fuente de códigos:**
- API de GitHub: `https://api.github.com/repos/ces-bcsf/CicSFE_GitHub/contents/indicadores`
- `fetch_codigos()` filtra los `_out.xlsx` y excluye los `HP_*` (no son series)

**Fuente de datos por indicador:**
- Excel: `https://ces-bcsf.github.io/CicSFE_GitHub/indicadores/{codigo}_out.xlsx`
- HTML:  `https://ces-bcsf.github.io/CicSFE_GitHub/indicadores/{codigo}_views.html`

**Estructura del Excel:**
- Hoja `Portada`: metadatos en col 3, filas 2/3/4/6 (nombre, um, fuente, id)
- Hoja `Data`: col 1 = fecha, col 13 (M) = `g_final` (única columna de valores a usar)

**Salida — archivos RDS en `data/processed/`:**
- `indicadores.rds`: id, nombre, unidad_medida, fuente, fecha_ultimo_dato, frecuencia, resumen_coyuntura
- `datos.rds`: id_indicador, fecha, valor (sin NAs)
- La Shiny app los consume con `readRDS("data/processed/indicadores.rds")`

Ver documentación completa en `docs/etl.md`.

---

## Arquitectura de la App Shiny (`app/`)

**Ejecución:** siempre desde la raíz del proyecto con `shiny::runApp("app")`

**Módulos (en `app/modules/`):**
- `data_loader.R` — lógica pura R: carga y filtra los RDS con `here()` para paths
- `selector_ui.R` — módulo Shiny: dropdown de indicadores, muestra frecuencia y último dato
- `chart_ui.R` — módulo Shiny: gráfico plotly de la serie temporal + descarga CSV
- `info_ui.R` — módulo Shiny: panel de metadata (fuente, unidad, resumen de coyuntura)

**Layout:** `bslib::page_sidebar` con selector en sidebar y tabs (Gráfico / Información) en panel principal.

**Coordinación:** `app.R` ensambla los módulos. Los reactives se pasan como parámetros entre módulos, no hay imports laterales entre ellos.

---

## Estructura de carpetas

```
IndiCES-Alpha/
├── app/
│   ├── app.R              # punto de entrada de la app Shiny
│   └── modules/
│       ├── data_loader.R  # carga y filtrado de RDS
│       ├── selector_ui.R  # selector de indicadores
│       ├── chart_ui.R     # gráfico plotly
│       └── info_ui.R      # panel de información
├── etl/
│   └── 1_extract.R        # extracción y estructurado de datos
├── data/
│   └── processed/
│       ├── indicadores.rds  # generado por el ETL
│       └── datos.rds        # generado por el ETL
├── docs/
│   └── etl.md             # documentación técnica del ETL
├── renv/                  # librería local de R (no editar)
├── renv.lock              # lockfile de dependencias
├── CLAUDE.md              # este archivo
└── README.md
```

---

## Git

- Rama de desarrollo: `feature/etl` (luego → `develop` → `main`)
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
