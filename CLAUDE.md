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
2. **App Shiny** — visualiza los datos procesados (aún no implementada)

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
| Shiny | — | app web (pendiente) |

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
- Trailing comma en tibbles y listas multilínea: sí

### Archivos temporales
Usar siempre `on.exit(unlink(temp))` para garantizar limpieza, no `finally`.

---

## Arquitectura del ETL (`etl/1_extract.R`)

**Fuente de datos:**
- Excel: `https://ces-bcsf.github.io/CicSFE_GitHub/indicadores/{codigo}_out.xlsx`
- HTML:  `https://ces-bcsf.github.io/CicSFE_GitHub/indicadores/{codigo}_views.html`

**Estructura del Excel:**
- Hoja `Portada`: metadatos en col 3, filas 2/3/4/6 (nombre, um, fuente, id)
- Hoja `Data`: col 1 = fecha, col 13 (M) = `g_final` (única columna de valores a usar)

**Salida — dos tibbles:**
- `$indicadores`: id, nombre, unidad_medida, fuente, fecha_ultimo_dato, frecuencia, resumen_coyuntura
- `$datos`: id_indicador, fecha, valor (sin NAs)

Ver documentación completa en `docs/etl.md`.

---

## Estructura de carpetas

```
IndiCES-Alpha/
├── etl/
│   └── 1_extract.R       # extracción y estructurado de datos
├── docs/
│   └── etl.md            # documentación técnica del ETL
├── renv/                 # librería local de R (no editar)
├── renv.lock             # lockfile de dependencias
├── CLAUDE.md             # este archivo
└── README.md
```

La app Shiny irá en `app/` cuando se implemente.

---

## Git

- Rama de desarrollo: `develop`
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
