#!/usr/bin/env Rscript
# Export "area without RAS detections" for Field Maps / Quarto map.
#
# Logic:
#   1. June 2023 high-water polygons = floodplain bound
#   2. Split floodplain into East / West of the river (mile-marker centerline)
#   3. Slice by whole river mile
#   4. Negative space = high water − bank sides that already have detections
#      in that mile (keep only mile×bank cells with zero RAS detections)
#
# Also writes floodplain + multithreaded channel layers for the map.
#
# Usage: Rscript export_survey_nav.R

suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
})

ROOT <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) getwd())
if (is.null(ROOT) || !nzchar(ROOT)) ROOT <- getwd()
setwd(ROOT)

OUT_DIR <- file.path(ROOT, "exports", "survey_nav_2026")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

UTM <- 32611
HALF_WIDTH_M <- 2500   # half-plane width to cover floodplain when splitting banks
MIN_HW_ACRE <- 0.1
MIN_UNIT_ACRE <- 0.5

HW_SOUTH <- "https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/highwaterline_south/FeatureServer/0/query?where=1=1&outFields=*&f=geojson&outSR=4326"
HW_NORTH <- "https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/highwaterline_north/FeatureServer/0/query?where=1=1&outFields=*&f=geojson&outSR=4326"
RIVER_URL <- "https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/owens_river_feature/FeatureServer/0/query?where=1=1&outFields=*&f=geojson&outSR=4326"

cat("Loading high-water floodplain, river channels, pepperweed, river miles...\n")
hw_south <- st_read(HW_SOUTH, quiet = TRUE)
hw_north <- st_read(HW_NORTH, quiet = TRUE)
river <- st_read(RIVER_URL, quiet = TRUE)
pepper <- st_read(file.path(ROOT, "pepperweed_data.geojson"), quiet = TRUE)
rivermiles <- st_read(file.path(ROOT, "data", "LORP_RiverMiles_revised.shp"), quiet = TRUE) %>%
  mutate(RiverMile = as.numeric(NAME)) %>%
  st_transform(4326) %>%
  arrange(RiverMile)

reach_url <- "https://inyocounty.maps.arcgis.com/sharing/rest/content/items/90e5870bd5914a928bd97b023f07b807/data"
reaches <- tryCatch({
  st_read(reach_url, quiet = TRUE) %>%
    filter(Name %in% paste0("LORP Reach ", 1:6)) %>%
    st_transform(4326)
}, error = function(e) NULL)

# ── Floodplain ─────────────────────────────────────────────────────────────────
hw <- bind_rows(
  hw_south %>% mutate(Section = "south"),
  hw_north %>% mutate(Section = "north")
) %>%
  st_make_valid() %>%
  st_transform(UTM)
hw$acres <- as.numeric(st_area(hw)) / 4046.8564224
hw <- hw %>% filter(acres >= MIN_HW_ACRE)

fp <- hw %>%
  summarise(geometry = st_union(geometry), .groups = "drop") %>%
  st_make_valid()
fp_acres <- as.numeric(st_area(fp)) / 4046.8564224
cat(sprintf("Floodplain: %.0f acres (June 2023 high water)\n", fp_acres))

rm_utm <- st_transform(rivermiles, UTM) %>% arrange(RiverMile)
river_utm <- st_transform(river, UTM)
pepper_utm <- st_transform(pepper, UTM)

# Centerline from ordered river-mile markers (for bank split + mile slices)
xy <- st_coordinates(rm_utm)[, 1:2, drop = FALSE]
keep <- c(TRUE, rowSums(abs(diff(xy))) > 1e-3)
xy <- xy[keep, , drop = FALSE]
centerline <- st_sf(geometry = st_sfc(st_linestring(xy), crs = UTM))

# ── East / West half-planes along centerline ───────────────────────────────────
# Left of downstream (increasing RM) = East; right = West (LORP flows ~south)
build_bank_poly <- function(coords, side = c("East", "West"), half_w = HALF_WIDTH_M) {
  side <- match.arg(side)
  n <- nrow(coords)
  off <- matrix(NA_real_, n, 2)
  for (i in seq_len(n)) {
    if (i < n) {
      tx <- coords[i + 1, 1] - coords[i, 1]
      ty <- coords[i + 1, 2] - coords[i, 2]
    } else {
      tx <- coords[i, 1] - coords[i - 1, 1]
      ty <- coords[i, 2] - coords[i - 1, 2]
    }
    len <- sqrt(tx^2 + ty^2)
    if (len < 1e-6) {
      nx <- 0; ny <- 0
    } else {
      tx <- tx / len; ty <- ty / len
      nx <- -ty; ny <- tx  # left normal
    }
    sign <- if (side == "East") 1 else -1
    off[i, ] <- coords[i, ] + sign * half_w * c(nx, ny)
  }
  ring <- rbind(coords, off[n:1, , drop = FALSE], coords[1, , drop = FALSE])
  st_sfc(st_make_valid(st_polygon(list(ring))), crs = UTM)
}

east_strip <- st_sf(Bank = "East", geometry = build_bank_poly(xy, "East"))
west_strip <- st_sf(Bank = "West", geometry = build_bank_poly(xy, "West"))

cat("Splitting floodplain into East / West banks...\n")
fp_east <- suppressWarnings(st_intersection(fp, east_strip)) %>% st_make_valid()
fp_west <- suppressWarnings(st_intersection(fp, west_strip)) %>% st_make_valid()
fp_east$Bank <- "East"
fp_west$Bank <- "West"
fp_banks <- bind_rows(
  fp_east %>% select(Bank, geometry),
  fp_west %>% select(Bank, geometry)
)

# ── Mile bands: Voronoi of mile markers clipped to floodplain ──────────────────
cat("Slicing floodplain by river mile...\n")
# Use integer mile markers 0..60 where available
mile_pts <- rm_utm %>%
  mutate(Mile = floor(RiverMile)) %>%
  group_by(Mile) %>%
  slice(1) %>%
  ungroup() %>%
  filter(Mile >= 0, Mile <= 60)

# Voronoi within floodplain bbox
bb <- st_as_sfc(st_bbox(fp))
vor <- st_voronoi(st_union(st_geometry(mile_pts)), envelope = bb)
vor <- st_sf(geometry = st_collection_extract(vor))
# Match each voronoi cell to nearest mile point
vor_cents <- st_centroid(vor)
nn <- st_nearest_feature(vor_cents, mile_pts)
vor$Mile <- mile_pts$Mile[nn]
vor <- suppressWarnings(st_intersection(vor, fp)) %>% st_make_valid()

# Mile × bank cells
cat("Building mile × bank cells...\n")
cells <- suppressWarnings(st_intersection(vor, fp_banks)) %>%
  st_make_valid()
cells <- cells %>%
  filter(!st_is_empty(geometry)) %>%
  mutate(acres = as.numeric(st_area(geometry)) / 4046.8564224) %>%
  filter(acres >= MIN_UNIT_ACRE)

# ── Detections by mile × bank (inside floodplain) ──────────────────────────────
pepper_fp <- pepper_utm[lengths(st_intersects(pepper_utm, fp)) > 0, ]
cat(sprintf("Pepperweed in floodplain: %d / %d\n", nrow(pepper_fp), nrow(pepper_utm)))

# Assign mile + bank to each detection
nn_m <- st_nearest_feature(pepper_fp, mile_pts)
pepper_fp$Mile <- mile_pts$Mile[nn_m]

rm_xy <- mile_pts %>%
  mutate(x = st_coordinates(geometry)[, 1], y = st_coordinates(geometry)[, 2]) %>%
  st_drop_geometry() %>%
  arrange(Mile)

get_bank_pt <- function(x, y, mile) {
  idx <- which(rm_xy$Mile == mile)
  if (length(idx) == 0) idx <- which.min(abs(rm_xy$Mile - mile))
  idx <- idx[1]
  if (idx < nrow(rm_xy)) {
    dx <- rm_xy$x[idx + 1] - rm_xy$x[idx]
    dy <- rm_xy$y[idx + 1] - rm_xy$y[idx]
  } else {
    dx <- rm_xy$x[idx] - rm_xy$x[idx - 1]
    dy <- rm_xy$y[idx] - rm_xy$y[idx - 1]
  }
  cross <- dx * (y - rm_xy$y[idx]) - dy * (x - rm_xy$x[idx])
  ifelse(cross > 0, "East", "West")
}
pc <- st_coordinates(pepper_fp)
pepper_fp$Bank <- mapply(get_bank_pt, pc[, 1], pc[, 2], pepper_fp$Mile)

det_counts <- pepper_fp %>%
  st_drop_geometry() %>%
  count(Mile, Bank, name = "n_det")

# ── Negative space: cells with zero detections on that bank ────────────────────
# = high water minus the bank side that already has detections for that mile
cells <- cells %>%
  left_join(det_counts, by = c("Mile", "Bank")) %>%
  mutate(n_det = ifelse(is.na(n_det), 0L, n_det))

neg <- cells %>% filter(n_det == 0L)

# Reach labels
get_reach <- function(mile) {
  if (is.null(reaches) || length(mile) == 0 || is.na(mile)) return(NA_character_)
  idx <- which.min(abs(rivermiles$RiverMile - mile))
  mk <- rivermiles[idx, ]
  r <- st_join(mk, reaches %>% select(Name), join = st_nearest_feature)
  gsub("LORP Reach ", "R", r$Name[1])
}

# Miles with no detections on either bank (full gap)
miles_either <- unique(det_counts$Mile)
full_gap_miles <- setdiff(unique(neg$Mile), miles_either)

neg <- neg %>%
  mutate(
    SurveyType = "NoRASDetections",
    Priority = case_when(
      Mile %in% full_gap_miles & acres >= 10 ~ "High",
      Mile %in% full_gap_miles ~ "Medium",
      acres >= 25 ~ "Medium",
      TRUE ~ "Low"
    ),
    RM_Label = paste0("RM ", Mile),
    Reach = vapply(Mile, get_reach, character(1)),
    Notes = paste0(
      "High-water floodplain on ", Bank, " bank at ", RM_Label,
      " with no RAS pepperweed detections. ",
      ifelse(Mile %in% full_gap_miles, "Neither bank has detections this mile.",
             "Opposite bank has detections; this side is the gap.")
    ),
    SurveyID = paste0("RAS2026_NOD_", sprintf("%02d", Mile), "_",
                      ifelse(Bank == "East", "E", "W")),
    Year = 2026L,
    Acres = round(acres, 1),
    RM_Start = Mile,
    RM_End = Mile
  )

# Dissolve multiparts per mile×bank
nav_utm <- neg %>%
  group_by(SurveyID, Year, RM_Start, RM_End, RM_Label, Reach, Bank,
           Priority, SurveyType, Notes) %>%
  summarise(Acres = round(sum(acres), 1), .groups = "drop")

nav <- st_transform(nav_utm, 4326)

# Reference layers
fp_out <- st_transform(fp, 4326) %>%
  mutate(Layer = "June2023_HighWater", Acres = round(fp_acres, 1))
river_out <- st_transform(river, 4326)

# Detected bank sides (for optional map context — the parts we subtracted)
detected_sides <- cells %>%
  filter(n_det > 0) %>%
  group_by(Mile, Bank) %>%
  summarise(Acres = round(sum(acres), 1), n_det = sum(n_det), .groups = "drop") %>%
  mutate(
    Layer = "BankWithDetections",
    RM_Label = paste0("RM ", Mile)
  )
detected_out <- st_transform(detected_sides, 4326)

# ── Write ──────────────────────────────────────────────────────────────────────
write_gj <- function(obj, path) {
  if (file.exists(path)) file.remove(path)
  st_write(obj, path, driver = "GeoJSON", quiet = TRUE)
}

gj_path <- file.path(OUT_DIR, "ras_2026_survey_nav.geojson")
write_gj(nav, gj_path)
write_gj(fp_out, file.path(OUT_DIR, "lorp_highwater_floodplain.geojson"))
write_gj(river_out, file.path(OUT_DIR, "owens_river_channels.geojson"))
write_gj(detected_out, file.path(OUT_DIR, "ras_2026_banks_with_detections.geojson"))

nav_shp <- nav %>%
  rename(
    SurvID = SurveyID, RMStart = RM_Start, RMEnd = RM_End, RMLabel = RM_Label,
    SurvType = SurveyType
  )
shp_path <- file.path(OUT_DIR, "ras_2026_survey_nav.shp")
st_write(nav_shp, shp_path, delete_dsn = TRUE, quiet = TRUE)
zip_path <- file.path(OUT_DIR, "ras_2026_survey_nav_shp.zip")
if (file.exists(zip_path)) file.remove(zip_path)
shp_files <- list.files(OUT_DIR, pattern = "^ras_2026_survey_nav\\.(shp|shx|dbf|prj|cpg)$", full.names = TRUE)
utils::zip(zip_path, files = shp_files, flags = "-j -q")
unlink(shp_files)  # keep zip only; sidecars are gitignored intermediates

cat("\n=== Area without RAS detections ===\n")
cat(sprintf("Units: %d  |  Acres: %.0f\n", nrow(nav), sum(nav$Acres)))
cat("By priority × bank:\n")
print(as.data.frame(nav %>% st_drop_geometry() %>% count(Priority, Bank)))
cat("\nTop units:\n")
print(as.data.frame(nav %>% st_drop_geometry() %>%
                      arrange(desc(Acres)) %>%
                      select(SurveyID, RM_Label, Bank, Priority, Acres) %>%
                      head(12)))
cat("\nWrote:\n ", gj_path, "\n ", zip_path, "\n")
