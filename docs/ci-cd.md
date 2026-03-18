# CI/CD — Automatización del ETL semanal

El pipeline de CI/CD corre cada lunes automáticamente via **GitHub Actions**,
replicando el caso de uso "Todos los lunes" del diagrama de casos de uso.

**Archivo:** `.github/workflows/etl.yml`

---

## Flujo

```
GitHub Actions (cron lunes 9:00 AM ARG)
        │
        ▼
  Checkout repo
        │
        ▼
  Setup R 4.5.0 + renv
        │
        ▼
  Rscript etl/1_extract.R
        │
        ▼
  Copiar RDS → app/data/processed/
        │
        ▼
  git commit + push (solo si hubo cambios)
        │
        ▼
  rsconnect::deployApp() → shinyapps.io
```

---

## Trigger

```yaml
on:
  schedule:
    - cron: "0 12 * * 1"  # lunes 12:00 UTC = 9:00 AM Argentina (UTC-3)
  workflow_dispatch:       # disparo manual desde GitHub → Actions
```

`workflow_dispatch` permite ejecutar el workflow manualmente desde la UI de GitHub
sin esperar el lunes — útil para testing y deploys manuales.

---

## Steps explicados

### 1. Checkout
```yaml
- uses: actions/checkout@v4
```
La VM de GitHub Actions empieza vacía. Este step clona el repo en ella.

### 2. Setup R
```yaml
- uses: r-lib/actions/setup-r@v2
  with:
    r-version: "4.5.0"
    use-public-rspm: true
```
Instala R 4.5.0. `use-public-rspm: true` usa paquetes precompilados de Posit —
sin esto cada paquete se compilaría desde fuente (~20 min extra).

### 3. Setup renv
```yaml
- uses: r-lib/actions/setup-renv@v2
  with:
    cache-version: 1
```
Lee `renv.lock` e instala exactamente esas versiones. El cache evita reinstalar
paquetes en cada ejecución — solo se reinstala si cambia `renv.lock`.

### 4. Ejecutar ETL
```yaml
- run: Rscript etl/1_extract.R
```
Si el script falla (error de R), el workflow se detiene aquí.
No se commitean ni deployan datos rotos.

### 5. Copiar RDS
```yaml
- run: |
    cp data/processed/indicadores.rds app/data/processed/indicadores.rds
    cp data/processed/datos.rds app/data/processed/datos.rds
```
Sincroniza los datos generados por el ETL con la copia que consume la app Shiny.

### 6. Commit
```yaml
- run: |
    git config --local user.name "github-actions[bot]"
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git add data/processed/ app/data/processed/
    git diff --staged --quiet || git commit -m "etl: actualizar datos $(date +'%Y-%m-%d')"
    git push
```
`git diff --staged --quiet || git commit` — solo commitea si hubo cambios en los datos.
Sin este guard, el workflow fallaría si los datos no se modificaron entre lunes.

### 7. Deploy
```yaml
- env:
    SHINYAPPS_ACCOUNT: ${{ secrets.SHINYAPPS_ACCOUNT }}
    SHINYAPPS_TOKEN: ${{ secrets.SHINYAPPS_TOKEN }}
    SHINYAPPS_SECRET: ${{ secrets.SHINYAPPS_SECRET }}
  run: |
    Rscript -e "
      rsconnect::setAccountInfo(...)
      rsconnect::deployApp('app', appName = 'indicesApp', forceUpdate = TRUE)
    "
```
Las credenciales nunca se escriben en el código — se inyectan desde GitHub Secrets.

---

## Configuración de secrets

Antes de que el workflow funcione hay que cargar tres secrets en el repositorio:

**GitHub → Settings → Secrets and variables → Actions → New repository secret**

| Secret | Dónde obtenerlo |
|--------|-----------------|
| `SHINYAPPS_ACCOUNT` | Nombre de cuenta en shinyapps.io |
| `SHINYAPPS_TOKEN` | shinyapps.io → Account → Tokens → Show secret |
| `SHINYAPPS_SECRET` | Mismo lugar que el token |

---

## Cómo probar sin esperar el lunes

1. Ir a `github.com/FrancOcampo/IndiCES-Alpha`
2. **Actions → ETL semanal → Run workflow**
3. Seleccionar rama y confirmar

---

## Dependencias del workflow

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| `actions/checkout` | v4 | Clonar repo en la VM |
| `r-lib/actions/setup-r` | v2 | Instalar R |
| `r-lib/actions/setup-renv` | v2 | Restaurar dependencias R |
| `rsconnect` | — | Deploy a shinyapps.io |
