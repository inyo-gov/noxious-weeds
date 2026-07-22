# LORP perennial pepperweed occupancy

Technical Quarto data report on cumulative known occupancy and corridor-scale discovery of perennial pepperweed (*Lepidium latifolium*) along the Lower Owens River Project (LORP), Owens Valley, California.

**Live site:** [inyo-gov.github.io/noxious-weeds](https://inyo-gov.github.io/noxious-weeds)  
**Workplan:** [FY 2026–2027 LORP Work Plan and Budget (PDF)](https://inyowater.org/wp-content/uploads/2026/06/2026-2027-LORP-Work-Plan-and-Budget_draft_062226.pdf)

## What’s in the report

- **Abstract / introduction / methods** — academic framing of estimands (cumulative known occupancy; herbicide out of scope)
- **Interactive Leaflet map** — detections by year (`2018`–`current_year`), river channels, 2026 east/west gap lines
- **Abundance, reach, and river-mile analyses** — LORP Reaches 1–6 and mile summaries
- **Occupancy & cumulative discovery** — forecasts toward corridor saturation (linear / asymptotic / logistic / recent-trajectory) plus **fast vs low step-pulse** scenarios
- **0.1-mi cumulative heatmap** — corridor discovery geography (white = never detected; persists after first detection)
- **2026 RAS applications** — unoccupied river miles (250 m corridor filter), bank notes, Field Maps gap-line exports
- **References** — cited ecology and LORP sources
- **Downloads** — GeoJSON / KML of mapped sites

Output formats: HTML (`docs/`) for GitHub Pages and Word (`docs/index.docx`).

## Data sources


| Layer                 | Source                                                                                                                                                                                                                      |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pepperweed sites      | [Noxious Weeds 2025 View](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/Noxious_Weeds_2025_view/FeatureServer/0)                                                                                        |
| High-water floodplain | [north](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/highwaterline_north/FeatureServer) / [south](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/highwaterline_south/FeatureServer) |
| River channels        | [owens_river_feature](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/owens_river_feature/FeatureServer)                                                                                                  |
| River miles           | `data/LORP_RiverMiles_revised.shp`                                                                                                                                                                                          |
| Reaches               | AGOL LORP reach polygons (Reaches 1–6)                                                                                                                                                                                      |


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

Optional scripts (not required for the HTML report): `lepidium_app.py`, `arcfetch_storeduckdb.py`.

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

**Caveat (through end of July 2026):** treat gap lines as a **draft** for Field Maps; confirm against the river-mile recommendation tables before field use.

`export_survey_nav.R` builds **east/west parallel gap lines**:

1. River-mile centerline (RM 0–60)
2. Detections within 250 m assigned to East / West bank
3. Empty 0.1-mi segment×bank runs dissolved; keep stretches **≥400 m**
4. Offset polylines 50 m from centerline


| Bank | Color              | Pattern |
| ---- | ------------------ | ------- |
| East | Sky blue `#0077BB` | Solid   |
| West | Orange `#EE7733`   | Dashed  |


(Pattern differs so meaning is not color-only.) Outputs: `exports/survey_nav_2026/` → copied to `docs/exports/` on render.

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
- See `WORKLOG.md` for recent planning context and open follow-ups.



## Contact

Inyo County Water Department — LORP / noxious weeds monitoring.

## License

See [LICENSE](LICENSE).