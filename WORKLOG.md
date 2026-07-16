---
repo: noxious-weeds
updated: 2026-07-10
period_focus: FY 2026–27 pepperweed RAS — unoccupied corridor planning
tags: [lorp, pepperweed, ras, survey-nav, forecasting]
---

# Noxious weeds — work log

Perennial pepperweed (`Lepidium latifolium`) mapping and **2026 RAS** survey planning for the LORP corridor. GitHub Pages: [inyo-gov/noxious-weeds](https://github.com/inyo-gov/noxious-weeds).

**Approved workplan:** [FY 2026–2027 LORP Work Plan and Budget (PDF)](https://inyowater.org/wp-content/uploads/2026/06/2026-2027-LORP-Work-Plan-and-Budget_draft_062226.pdf) — crosswalk and study-design gaps in [`lorp-pia-completion/docs/11_fy2627_approved_workplan_reference.md`](../lorp-pia-completion/docs/11_fy2627_approved_workplan_reference.md).

---

## Workspace summary

**2026 RAS planning (Jul 2026):** Workplan directs summer RAS to areas **without known pepperweed populations**. Built **unoccupied-mile** and **opposite-bank** survey units; exported `ras_2026_survey_nav` (GeoJSON + shapefile zip) for Field Maps. Interactive map layer **2026 Survey Gaps** (cyan corridors) on Quarto site.

**Saturation forecasting:** Cumulative discovery models on 2018–2025 corridor data (linear, asymptotic, logistic) — milestone years for 50%/75%/90%/95% **known occupancy** along RM 0–60. Descriptive projections only; accelerated RAS in gap miles will raise discovery rate.

**Gaps (purpose / significance / AM triggers):** See Doc **11** template — pepperweed line partially populated; formal purpose/significance paragraphs still needed for TG record.

---

## Detailed log

### 2026-07-10 — workplan reference + RAS planning log

**Time:** 4 h

- Linked approved [2026–2027 LORP workplan PDF](https://inyowater.org/wp-content/uploads/2026/06/2026-2027-LORP-Work-Plan-and-Budget_draft_062226.pdf) via `lorp-pia-completion` Doc 11.
- Documented study-design template population vs gaps (purpose, objectives, significance, hypotheses).
- **Unoccupied areas:** `export_survey_nav.R` — corridor filter 250 m; priority segments Reach 6 (RM 43–48, 51–52, 54–60), Reach 3 gaps (RM 21–22, 24).
- **Saturation year:** milestone table in `index.qmd` § Cumulative Discovery and Occupancy Forecasts — re-render to refresh projected years.

### 2026-07-07 — unoccupied-mile nav export + Reach 6 priority

**Time:** 4 h

- Ran `export_survey_nav.R` for 2026 corridor gaps; validated 250 m filter and opposite-bank units.
- Priority miles Reach 6 (RM 43–48, 51–52, 54–60) for Field Maps handoff.

### Prior — pepperweed report scaffold

- `index.qmd` — AGOL Noxious Weeds 2025 service, LORP filter, river-mile occupancy, monitoring recommendations.
- `lorp_om_map.py` — O&M context map (referenced from `lorp-pia-completion/STATUS.md`).

---

## Refresh

```bash
Rscript export_survey_nav.R    # navigation polygons
quarto render index.qmd        # report + forecasts + gap map
```

---

## Open

- [ ] Paste workplan **line item #** for pepperweed RAS into Doc 11 when PDF archived locally
- [ ] Draft **purpose / significance** paragraphs for TG (template gaps in Doc 11)
- [ ] Overlay historical RAS tracklogs on gap polygons (day-sheet planning)
- [ ] `update_year.R 2026` when 2026 field season data arrive
