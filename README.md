# Perennial Pepperweed Mapping

## Overview

This repository contains an interactive Quarto website for mapping and analyzing perennial pepperweed sites within the Lower Owens River Project (LORP) area in Owens Valley, California. The analysis focuses on monitoring noxious weeds from 2018-2025 and into the future, with particular emphasis on identifying new satellite sites that require management attention.

## Features

- **Interactive Leaflet Maps**: Compare pepperweed sites across years (2018-2025)
- **Dynamic Data Loading**: Real-time data from ArcGIS Online feature services
- **LORP Area Focus**: Automatically filters data to the LORP study area
- **Abundance Analysis**: Histograms and statistics for site distribution
- **Priority Site Identification**: Highlights recent high-priority sites requiring attention
- **Field Documentation**: Up to 40 field photos with metadata
- **Data Downloads**: GeoJSON and KML exports for further analysis
- **Multi-Format Output**: HTML website and Word document generation

## Project Structure

```
noxious-weeds/
├── index.qmd                 # Main Quarto document
├── _quarto.yml              # Quarto website configuration
├── styles.css               # Custom CSS styling
├── docs/                    # Generated website files (GitHub Pages)
│   ├── index.html           # Main website
│   ├── index.docx           # Word document
│   ├── pepperweed_data.geojson
│   └── pepperweed_data.kml
├── custom-reference.docx    # Word template
├── inyo_logo.png           # County logo
├── setup_r_packages.R      # R package installation
├── create_reference_doc.R  # Word template creation
├── render_pepperweed_report.R # Automated rendering
├── update_year.R           # Year parameter update script
├── r_requirements.txt      # R package dependencies
└── requirements.txt        # Python dependencies
```

## Data Source

The analysis uses data from the Inyo County ArcGIS Online feature service:
- **Service**: Noxious Weeds 2025 View
- **URL**: `https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/Noxious_Weeds_2025_view/FeatureServer/0`
- **Update Frequency**: Real-time (data updates automatically when new observations are added)

## Setup and Installation

### Prerequisites

- R (version 4.0 or higher)
- Python (for Quarto)
- Quarto CLI

### R Package Installation

Run the setup script to install all required R packages:

```r
source("setup_r_packages.R")
```

Or install manually:

```r
install.packages(c(
  "sf", "dplyr", "leaflet", "leaflet.extras2", "lubridate", 
  "htmltools", "knitr", "DT", "tidyr", "ggplot2", "plotly", 
  "officer", "flextable", "webshot2", "httr", "scales"
))
```

### Python Dependencies

```bash
pip install -r requirements.txt
```

## Usage

### Generate the Report

#### Option 1: Manual Rendering
```bash
quarto render index.qmd
```

#### Option 2: Automated Rendering (HTML + Word)
```r
source("render_pepperweed_report.R")
```

### Update for New Year

To update the report for a new year (e.g., 2026):

```bash
Rscript update_year.R 2026
quarto render index.qmd
```

### Create Word Template

If you need to regenerate the Word template:

```r
source("create_reference_doc.R")
```

## Output Formats

### HTML Website (`docs/index.html`)
- Interactive Leaflet maps
- Downloadable data files (GeoJSON, KML)
- Responsive design optimized for web viewing
- GitHub Pages compatible

### Word Document (`docs/index.docx`)
- Static maps (screenshots of interactive elements)
- Professional formatting for reports
- Suitable for printing and sharing

## Key Analysis Components

### 1. LORP Area Filtering
The analysis automatically filters data to focus on the LORP study area by:
- Identifying the northernmost 2025 observation
- Filtering all data to points south of this latitude
- Ensuring analysis focuses on the relevant geographic extent

### 2. Site Abundance Analysis
- Histogram showing distribution of site sizes
- Statistics for small (≤100) and large (>100) sites
- Focus on identifying new satellite sites

### 3. Priority Site Identification
- Recent high-priority sites (2024-2025)
- Sorted by abundance to prioritize small, new sites
- Management recommendations for containment

### 4. Temporal Analysis
- Year-over-year site changes
- Identification of new sites requiring attention
- Long-term monitoring trends (2018-2025)

## Data Downloads

The generated website includes downloadable data files:
- **GeoJSON**: For GIS analysis and mapping
- **KML**: For Google Earth visualization
- **Spatial Extent**: Bounding box coordinates for the study area

## Customization

### Parameters
The report uses Quarto parameters for easy customization:
- `current_year`: Current analysis year (default: 2025)
- `start_year`: Starting year for analysis (default: 2018)

### Styling
- Custom CSS in `styles.css`
- Matches Inyo County branding
- Responsive design for various screen sizes

## Deployment

### GitHub Pages
1. Push repository to GitHub
2. Enable GitHub Pages in repository settings
3. Set source to `docs` folder
4. Website will be available at `https://username.github.io/noxious-weeds`

### Local Server
```bash
cd docs
python -m http.server 8000
# Access at http://localhost:8000
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test rendering with `quarto render index.qmd`
5. Submit a pull request

## License

This project is licensed under the terms specified in the LICENSE file.

## Contact

For questions about this analysis or the LORP monitoring program, contact the Inyo County Water Department.

## Technical Notes

- **Data Processing**: Unix timestamps are converted to POSIXct for proper date handling
- **Fallback Dates**: Uses `CreationDate` when `Date_Observed` is not available
- **Spatial Filtering**: Dynamic LORP area filtering based on current year data
- **Performance**: Optimized for datasets with 1000+ observations
- **Compatibility**: Works with R 4.0+, Quarto 1.4+, modern web browsers