#!/usr/bin/env Rscript
# Export east/west bank survey-gap LINES for Field Maps / Quarto map.
#
# Logic:
#   1. River-mile markers → corridor centerline (RM 0–60)
#   2. Assign each pepperweed detection to East / West of centerline
#      (corridor filter 250 m so off-channel points don't occupy a mile)
#   3. Bin corridor into 0.1-mi segments; mark segment×bank occupied if
#      any detection on that bank
#   4. Dissolve contiguous empty segment×bank runs into polylines
#   5. Keep runs with along-channel length ≥ MIN_GAP_M (400 m)
#   6. Offset lines parallel to the centerline (East = left, West = right)
#
# Styling (ADA / colorblind-safe — color + pattern, not color alone):
#   East: solid sky blue   (#0077BB)  LineStyle = "solid"
#   West: dashed orange    (#EE7733)  LineStyle = "dashed"
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
CORRIDOR_M <- 250      # detections farther than this from centerline ignored
OFFSET_M <- 50         # parallel line distance from centerline
SEG_MI <- 0.1          # segment length (miles)
MIN_GAP_M <- 400       # drop short gap runs
MI_TO_M <- 1609.344

RIVER_URL <- "https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/owens_river_feature/FeatureServer/0/query?where=1=1&outFields=*&f=geojson&outSR=4326"

cat("Loading river channels, pepperweed, river miles...\n")
river <- st_read(RIVER_URL, quiet = TRUE)
pepper_path <- file.path(ROOT, "pepperweed_data.geojson")
if (!file.exists(pepper_path)) {
  stop("Missing pepperweed_data.geojson — render index.qmd once or export the feature service.")
}
pepper <- st_read(pepper_path, quiet = TRUE)
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

rm_utm <- st_transform(rivermiles, UTM) %>% arrange(RiverMile)
pepper_utm <- st_transform(pepper, UTM)
river_utm <- st_transform(river, UTM)

# ── Centerline from ordered mile markers ───────────────────────────────────────
xy <- st_coordinates(rm_utm)[, 1:2, drop = FALSE]
keep <- c(TRUE, rowSums(abs(diff(xy))) > 1e-3)
xy <- xy[keep, , drop = FALSE]
# Attach approximate river-mile at each vertex (interpolated by index)
rm_vals <- rivermiles$RiverMile[keep]
if (length(rm_vals) != nrow(xy)) {
  rm_vals <- approx(
    x = seq_len(length(rivermiles$RiverMile)),
    y = rivermiles$RiverMile,
    xout = seq(1, length(rivermiles$RiverMile), length.out = nrow(xy))
  )$y
}
centerline <- st_sf(geometry = st_sfc(st_linestring(xy), crs = UTM))
cl_len_m <- as.numeric(st_length(centerline))
cat(sprintf("Centerline length: %.1f km (%d vertices)\n", cl_len_m / 1000, nrow(xy)))

# Cumulative distance along centerline vertices
seg_d <- sqrt(rowSums(diff(xy)^2))
cum_m <- c(0, cumsum(seg_d))

# Interpolate point at distance d along centerline
point_at <- function(d) {
  d <- max(0, min(d, cum_m[length(cum_m)]))
  i <- max(1L, which.max(cum_m >= d) - 1L)
  if (i >= length(cum_m)) return(xy[nrow(xy), ])
  t <- if (cum_m[i + 1] > cum_m[i]) (d - cum_m[i]) / (cum_m[i + 1] - cum_m[i]) else 0
  xy[i, ] + t * (xy[i + 1, ] - xy[i, ])
}

# Unit left-normal at distance d (downstream = increasing RM)
normal_at <- function(d) {
  d <- max(0, min(d, cum_m[length(cum_m)] - 1e-3))
  i <- max(1L, which.max(cum_m >= d) - 1L)
  i <- min(i, nrow(xy) - 1L)
  tx <- xy[i + 1, 1] - xy[i, 1]
  ty <- xy[i + 1, 2] - xy[i, 2]
  len <- sqrt(tx^2 + ty^2)
  if (len < 1e-6) return(c(0, 0))
  c(-ty / len, tx / len)  # left normal
}

# River mile at distance d (linear in vertex RM)
rm_at <- function(d) {
  d <- max(0, min(d, cum_m[length(cum_m)]))
  i <- max(1L, which.max(cum_m >= d) - 1L)
  if (i >= length(cum_m)) return(rm_vals[length(rm_vals)])
  t <- if (cum_m[i + 1] > cum_m[i]) (d - cum_m[i]) / (cum_m[i + 1] - cum_m[i]) else 0
  rm_vals[i] + t * (rm_vals[i + 1] - rm_vals[i])
}

# Distance along centerline for a point (nearest sample on line)
dist_along <- function(pts) {
  n_samp <- max(500L, ceiling(cl_len_m / 20))
  samp_d <- seq(0, cl_len_m, length.out = n_samp)
  samp_xy <- t(vapply(samp_d, point_at, numeric(2)))
  samp_pts <- st_sfc(lapply(seq_len(nrow(samp_xy)), function(i) st_point(samp_xy[i, ])), crs = UTM)
  idx <- st_nearest_feature(pts, samp_pts)
  samp_d[idx]
}

# ── Bank assignment for detections ─────────────────────────────────────────────
cat("Assigning detections to East/West banks...\n")
nn_cl <- st_nearest_feature(pepper_utm, centerline)
d_to_cl <- as.numeric(st_distance(pepper_utm, centerline[nn_cl, ], by_element = TRUE))
pepper_cor <- pepper_utm[d_to_cl <= CORRIDOR_M, ]
d_to_cl <- d_to_cl[d_to_cl <= CORRIDOR_M]
cat(sprintf("Corridor detections (≤%d m): %d / %d\n", CORRIDOR_M, nrow(pepper_cor), nrow(pepper_utm)))

along <- dist_along(pepper_cor)
pc <- st_coordinates(pepper_cor)
bank <- character(nrow(pepper_cor))
for (i in seq_len(nrow(pepper_cor))) {
  p0 <- point_at(along[i])
  nrm <- normal_at(along[i])
  # projection onto left normal: >0 = East (left of downstream)
  cross <- sum((pc[i, ] - p0) * nrm)
  bank[i] <- if (cross > 0) "East" else "West"
}
pepper_cor$Bank <- bank
pepper_cor$Along_m <- along
pepper_cor$Seg <- floor(along / (SEG_MI * MI_TO_M))

# ── 0.1-mi segments along corridor ─────────────────────────────────────────────
n_seg <- ceiling(cl_len_m / (SEG_MI * MI_TO_M))
seg_ids <- 0:(n_seg - 1)

occupied <- pepper_cor %>%
  st_drop_geometry() %>%
  distinct(Seg, Bank)

# Empty segment×bank
grid <- expand.grid(Seg = seg_ids, Bank = c("East", "West"), stringsAsFactors = FALSE) %>%
  anti_join(occupied, by = c("Seg", "Bank"))

# Contiguous runs per bank
group_runs <- function(segs) {
  if (length(segs) == 0) return(data.frame())
  segs <- sort(unique(segs))
  brk <- c(0, which(diff(segs) > 1), length(segs))
  data.frame(
    Seg_Start = segs[brk[-length(brk)] + 1],
    Seg_End = segs[brk[-1]]
  )
}

runs <- bind_rows(lapply(c("East", "West"), function(bk) {
  r <- group_runs(grid$Seg[grid$Bank == bk])
  if (nrow(r) == 0) return(NULL)
  r$Bank <- bk
  r
}))

if (is.null(runs) || nrow(runs) == 0) {
  stop("No empty bank segments found.")
}

# Length of each run (m) and filter
runs <- runs %>%
  mutate(
    Start_m = Seg_Start * SEG_MI * MI_TO_M,
    End_m = pmin((Seg_End + 1) * SEG_MI * MI_TO_M, cl_len_m),
    Length_m = End_m - Start_m
  ) %>%
  filter(Length_m >= MIN_GAP_M)

cat(sprintf("Gap runs ≥ %d m: %d (East %d, West %d)\n",
            MIN_GAP_M, nrow(runs),
            sum(runs$Bank == "East"), sum(runs$Bank == "West")))

# ── Build offset polylines for each run ────────────────────────────────────────
build_offset_line <- function(start_m, end_m, bank, step_m = 25) {
  ds <- seq(start_m, end_m, by = step_m)
  if (tail(ds, 1) < end_m - 1e-6) ds <- c(ds, end_m)
  sign <- if (bank == "East") 1 else -1
  coords <- t(vapply(ds, function(d) {
    point_at(d) + sign * OFFSET_M * normal_at(d)
  }, numeric(2)))
  st_linestring(coords)
}

get_reach <- function(mile) {
  if (is.null(reaches) || length(mile) == 0 || is.na(mile)) return(NA_character_)
  idx <- which.min(abs(rivermiles$RiverMile - mile))
  mk <- rivermiles[idx, ]
  r <- st_join(st_transform(mk, 4326), reaches %>% select(Name), join = st_nearest_feature)
  gsub("LORP Reach ", "R", r$Name[1])
}

geoms <- st_sfc(lapply(seq_len(nrow(runs)), function(i) {
  build_offset_line(runs$Start_m[i], runs$End_m[i], runs$Bank[i])
}), crs = UTM)

rm_start <- vapply(runs$Start_m, rm_at, numeric(1))
rm_end <- vapply(runs$End_m, rm_at, numeric(1))

nav_utm <- st_sf(
  SurveyID = paste0(
    "RAS2026_GAP_", sprintf("%02d", round(rm_start)), "_",
    ifelse(runs$Bank == "East", "E", "W")
  ),
  Year = 2026L,
  Bank = runs$Bank,
  LineStyle = ifelse(runs$Bank == "East", "solid", "dashed"),
  ColorHex = ifelse(runs$Bank == "East", "#0077BB", "#EE7733"),
  ColorName = ifelse(runs$Bank == "East", "sky blue", "orange"),
  RM_Start = round(rm_start, 1),
  RM_End = round(rm_end, 1),
  RM_Label = ifelse(
    round(rm_start, 1) == round(rm_end, 1),
    paste0("RM ", round(rm_start, 1)),
    paste0("RM ", round(pmin(rm_start, rm_end), 1), "–", round(pmax(rm_start, rm_end), 1))
  ),
  Length_m = round(runs$Length_m, 0),
  Length_mi = round(runs$Length_m / MI_TO_M, 2),
  Offset_m = OFFSET_M,
  Reach = vapply((rm_start + rm_end) / 2, get_reach, character(1)),
  SurveyType = "NoDetectionGapLine",
  Notes = paste0(
    runs$Bank, " bank gap (≥", MIN_GAP_M, " m) with no corridor pepperweed detections; ",
    "parallel to mainstem at ", OFFSET_M, " m. Walk this side; opposite bank may have detections."
  ),
  geometry = geoms
) %>%
  arrange(Bank, RM_Start)

nav <- st_transform(nav_utm, 4326)

# Reference layers
river_out <- st_transform(river_utm, 4326)
cl_out <- st_transform(centerline, 4326) %>%
  mutate(Layer = "RiverMileCenterline")

# ── Write ──────────────────────────────────────────────────────────────────────
write_gj <- function(obj, path) {
  if (file.exists(path)) file.remove(path)
  st_write(obj, path, driver = "GeoJSON", quiet = TRUE)
}

gj_path <- file.path(OUT_DIR, "ras_2026_survey_nav.geojson")
write_gj(nav, gj_path)
write_gj(river_out, file.path(OUT_DIR, "owens_river_channels.geojson"))
write_gj(cl_out, file.path(OUT_DIR, "lorp_rivermile_centerline.geojson"))

# Keep empty placeholders removed — drop obsolete polygon products if present
obsolete <- c(
  "lorp_highwater_floodplain.geojson",
  "ras_2026_banks_with_detections.geojson",
  "ras_2026_unsearched_near_channel.geojson"
)
for (f in obsolete) {
  p <- file.path(OUT_DIR, f)
  if (file.exists(p)) file.remove(p)
}

nav_shp <- nav %>%
  mutate(
    SurvID = SurveyID,
    RMStart = RM_Start,
    RMEnd = RM_End,
    RMLabel = RM_Label,
    SurvType = SurveyType,
    Len_m = Length_m,
    Len_mi = Length_mi,
    Style = LineStyle,
    Color = ColorHex
  ) %>%
  select(SurvID, Year, Bank, Style, Color, RMStart, RMEnd, RMLabel,
         Len_m, Len_mi, Reach, SurvType, Notes)

shp_path <- file.path(OUT_DIR, "ras_2026_survey_nav.shp")
st_write(nav_shp, shp_path, delete_dsn = TRUE, quiet = TRUE)
zip_path <- file.path(OUT_DIR, "ras_2026_survey_nav_shp.zip")
if (file.exists(zip_path)) file.remove(zip_path)
shp_files <- list.files(OUT_DIR, pattern = "^ras_2026_survey_nav\\.(shp|shx|dbf|prj|cpg)$", full.names = TRUE)
utils::zip(zip_path, files = shp_files, flags = "-j -q")
unlink(shp_files)

cat("\n=== East/West gap survey lines ===\n")
cat(sprintf("Lines: %d  |  Total length: %.1f mi\n", nrow(nav), sum(nav$Length_mi)))
cat("By bank:\n")
print(as.data.frame(nav %>% st_drop_geometry() %>%
                      group_by(Bank) %>%
                      summarise(n = n(), mi = round(sum(Length_mi), 1), .groups = "drop")))
cat("\nLongest gaps:\n")
print(as.data.frame(nav %>% st_drop_geometry() %>%
                      arrange(desc(Length_mi)) %>%
                      select(SurveyID, Bank, RM_Label, Length_mi, LineStyle, ColorName) %>%
                      head(12)))
cat("\nADA styling: East = solid sky blue (#0077BB); West = dashed orange (#EE7733)\n")
cat("Wrote:\n ", gj_path, "\n ", zip_path, "\n")
