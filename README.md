# Perennial Pepperweed Mapping

Interactive Quarto report for perennial pepperweed (`Lepidium latifolium`) monitoring along the Lower Owens River Project (LORP) corridor, Owens Valley, California.

**Live site:** [inyo-gov.github.io/noxious-weeds](https://inyo-gov.github.io/noxious-weeds)  
**Workplan:** [FY 2026–2027 LORP Work Plan and Budget (PDF)](https://inyowater.org/wp-content/uploads/2026/06/2026-2027-LORP-Work-Plan-and-Budget_draft_062226.pdf)

## What’s in the report

- **Interactive Leaflet map** — detections by year (`2018`–`current_year`), high-water floodplain, and river channels
- **Abundance analysis** — field classes `5 / 15 / 25 / 100 / 200+` (200 = ≥200 plants; may be thousands)
- **Reach and river-mile analysis** — LORP Reaches 1–6 and whole-mile summaries
- **Occupancy & cumulative discovery** — annual occupancy plus forecasts toward corridor saturation (linear / asymptotic / logistic / recent-trajectory)
- **2026 RAS recommendations** — unoccupied river miles (250 m corridor filter), east/west bank planning notes, suggested survey sequence (**tables + text are the source of truth**; see caveat below)
- **Field Maps exports** — draft floodplain “area without RAS detections” layers (not yet field-ready)
- **Field photos** — recent AGOL attachments with metadata
- **Downloads** — GeoJSON / KML of mapped sites

Output formats: HTML (`docs/`) for GitHub Pages and Word (`docs/index.docx`).

## Data sources

| Layer | Source |
| --- | --- |
| Pepperweed sites | [Noxious Weeds 2025 View](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/Noxious_Weeds_2025_view/FeatureServer/0) |
| High-water floodplain | [north](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/highwaterline_north/FeatureServer) / [south](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/highwaterline_south/FeatureServer) |
| River channels | [owens_river_feature](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/owens_river_feature/FeatureServer) |
| River miles | `data/LORP_RiverMiles_revised.shp` |
| Reaches | AGOL LORP reach polygons (Reaches 1–6) |

Pepperweed and reference layers are pulled live at render time. River miles ship with the repo.

## Project layout

```
noxious-weeds/
├── index.qmd                 # Main report
├── _quarto.yml               # Website config → docs/
├── styles.css
├── export_survey_nav.R       # Field Maps / floodplain negative-space export
├── render_pepperweed_report.R
├── update_year.R             # Bump params$current_year
├── setup_r_packages.R
├── data/                     # River-mile shapefile
├── exports/survey_nav_2026/  # GeoJSON + shapefile zip for Field Maps
└── docs/                     # Rendered site (GitHub Pages)
```

Optional scripts (not required for the HTML report): `lorp_om_map.py`, `lepidium_app.py`, `arcfetch_storeduckdb.py`.

## Setup

**Prerequisites:** R ≥ 4.0, Quarto CLI, network access to ArcGIS Online.

```r
source("setup_r_packages.R")
```

Or install from `r_requirements.txt` / the packages listed in `setup_r_packages.R`.

Python deps in `requirements.txt` are only needed for optional utilities (not Quarto HTML).

## Render

```bash
quarto render index.qmd
```

Or both HTML and Word:

```r
source("render_pepperweed_report.R")
```

Refresh Field Maps navigation layers (also runs from the report if the script is present):

```bash
Rscript export_survey_nav.R
```

### Update for a new survey year

```bash
Rscript update_year.R 2026
quarto render index.qmd
```

Parameters in `index.qmd`:

- `current_year` — latest survey year (default `2025`)
- `start_year` — start of time series (default `2018`)

## Survey navigation exports

**Caveat (through end of July 2026):** the recommended monitoring polygons are **not currently accurate** for field use. Plan from the **river-mile recommendation tables and narrative** in the report (Priority Survey Areas, bank notes, survey sequence). Do not treat the GeoJSON/shapefile exports as final navigation units yet.

**Deadline:** revise and ship corrected Field Maps polygons by **end of July 2026** (~2 weeks from mid-July).

`export_survey_nav.R` builds a first-pass “area without RAS detections” layer:

1. June 2023 high-water polygons as floodplain extent  
2. Split east / west of the river by mile  
3. Keep mile×bank cells with **zero** pepperweed detections  

Outputs land in `exports/survey_nav_2026/` and are copied to `docs/exports/` on render. Use those files only after the July update unless you are developing the polygon fix.

## Deployment

GitHub Pages is configured for the `docs/` folder → [inyo-gov.github.io/noxious-weeds](https://inyo-gov.github.io/noxious-weeds).

Local preview:

```bash
cd docs && python -m http.server 8000
```

## Notes

- Sites more than **250 m** from a river-mile marker are excluded from corridor occupancy so off-channel ditch/field points do not falsely occupy a mile.
- Abundance class **200** means **≥200** (dense patches are not stem-counted).
- Occupancy forecasts are descriptive discovery models, not biological invasion rates; more RAS effort in empty miles raises known occupancy even without new colonization.
- See `WORKLOG.md` for recent planning context and open follow-ups (tracklog overlays, TG purpose text, etc.).

## Contact

Inyo County Water Department — LORP / noxious weeds monitoring.

## License

See [LICENSE](LICENSE).
