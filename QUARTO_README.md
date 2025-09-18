# Pepperweed Analysis - Interactive Quarto Website

This project creates an interactive Quarto website for analyzing and visualizing Lepidium latifolium (perennial pepperweed) populations in the Lower Owens River Project (LORP) area, comparing data between 2024 and 2025.

## Features

- **Interactive Leaflet Maps**: Split-screen comparison showing 2024 vs 2025 populations
- **Real-time Data**: Automatically fetches data from ArcGIS Online feature service
- **Comprehensive Analysis**: Population trends, abundance categories, and management recommendations
- **Responsive Design**: Works on desktop and mobile devices
- **Professional Styling**: Custom CSS for enhanced visual presentation

## Quick Start

### Prerequisites

1. **R** (version 4.0 or higher)
2. **Quarto** (install from [quarto.org](https://quarto.org/docs/get-started/))
3. **Internet connection** (for fetching data from ArcGIS)

### Installation

1. **Install R packages**:
   ```r
   # Run the setup script
   source("setup_r_packages.R")
   ```

   Or install manually:
   ```r
   install.packages(c("sf", "dplyr", "lubridate", "leaflet", "leaflet.extras2", "DT", "htmltools", "knitr", "tidyr", "ggplot2", "plotly", "officer", "flextable", "webshot2"))
   ```

2. **Render the documents**:
   
   **Option A: Use the rendering function (Recommended)**
   ```r
   source("render_pepperweed_report.R")
   quick_render()  # Renders both HTML and Word formats
   ```
   
   **Option B: Manual rendering**
   ```bash
   # HTML format
   quarto render pepperweed_analysis.qmd --to html
   
   # Word format
   quarto render pepperweed_analysis.qmd --to docx
   ```

3. **View the results**:
   - **HTML**: Open `pepperweed_analysis.html` in your web browser
   - **Word**: Open `pepperweed_analysis.docx` in Microsoft Word or compatible software

## Data Source

The analysis uses data from the [ArcGIS Online Noxious Weeds 2025 Feature Service](https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/Noxious_Weeds_2025_view/FeatureServer/0), which includes:

- **Species**: Lepidium latifolium (LELA2)
- **Fields**: Date, Abundance, Height, Notes, Location
- **Update Frequency**: Real-time (data updates automatically)

## File Structure

```
noxious-weeds/
├── pepperweed_analysis.qmd     # Main Quarto document
├── styles.css                  # Custom CSS styling
├── setup_r_packages.R          # R package installation script
├── render_pepperweed_report.R  # Rendering functions for both formats
├── create_reference_doc.R      # Word reference document creator
├── custom-reference.docx       # Custom Word template
├── r_requirements.txt          # R package requirements
├── QUARTO_README.md           # This file
├── pepperweed_analysis.html   # Generated HTML output
└── pepperweed_analysis.docx   # Generated Word output
```

## Key Components

### 1. Interactive Map Comparison
- **Layer controls**: Toggle between 2023 vs 2024 populations
- **Color coding**: Yellow (2023), Red (2024), Dark Red (new sites)
- **Size coding**: Marker size reflects abundance levels
- **Interactive popups**: Detailed information for each observation

### 2. Data Analysis
- **Population trends**: Year-over-year comparisons
- **Abundance categories**: Distribution analysis
- **Height analysis**: Plant maturity assessment
- **New sites identification**: Areas requiring immediate attention

### 3. Management Recommendations
- **Priority areas**: Based on abundance and recency
- **Treatment protocols**: Specific actions for different population levels
- **Monitoring schedules**: Follow-up requirements

## Customization

### Modifying the Data Source
To use a different ArcGIS feature service, update the URL in the `data-loading` chunk:

```r
base_url <- "https://services.arcgis.com/YOUR_ORG_ID/arcgis/rest/services/YOUR_SERVICE/FeatureServer/0/query?"
```

### Styling Changes
Edit `styles.css` to modify:
- Color scheme
- Typography
- Layout spacing
- Interactive elements

### Adding New Analysis
Add new R chunks to the Quarto document for:
- Additional statistical analysis
- Custom visualizations
- Export functionality

## Output Formats

### HTML Format
- **Interactive maps**: Full Leaflet functionality with layer controls
- **Responsive design**: Works on desktop and mobile
- **Self-contained**: All resources embedded in single file
- **Best for**: Web sharing, presentations, interactive analysis

### Word Format
- **Professional layout**: Custom reference document for consistent formatting
- **Static maps**: Interactive elements converted to static images
- **Print-ready**: Optimized for printing and traditional document sharing
- **Best for**: Reports, printed materials, stakeholders who prefer Word

### Rendering Functions

The `render_pepperweed_report.R` script provides several functions:

```r
# Load the rendering functions
source("render_pepperweed_report.R")

# Quick render both formats
quick_render()

# Custom render with options
render_pepperweed_report(
  render_html = TRUE,
  render_word = TRUE,
  open_output = TRUE  # Opens files after rendering
)

# Create custom Word template
create_word_reference_doc()
```

## Publishing Options

### HTML Publishing
- **GitHub Pages**: Push repository and enable Pages
- **Web hosting**: Upload HTML file to any web server
- **Local sharing**: Self-contained file works offline

### Word Publishing
- **Email sharing**: Attach Word document to emails
- **Print distribution**: Print copies for stakeholders
- **Document management**: Store in SharePoint or similar systems

## Troubleshooting

### Common Issues

1. **Package installation errors**:
   ```r
   # Try installing from CRAN
   install.packages("package_name", dependencies = TRUE)
   
   # Or from GitHub if needed
   devtools::install_github("username/package_name")
   ```

2. **Quarto not found**:
   - Ensure Quarto is in your system PATH
   - Restart your terminal/R session after installation

3. **Data loading errors**:
   - Check internet connection
   - Verify ArcGIS service URL is accessible
   - Check if the service requires authentication

4. **Map not displaying**:
   - Ensure `leaflet.extras2` package is installed
   - Check browser console for JavaScript errors
   - Try a different web browser

### Performance Tips

- **Large datasets**: Add server-side filtering to the ArcGIS query
- **Slow rendering**: Use `freeze: auto` in YAML header for caching
- **Memory issues**: Process data in smaller chunks

## Data Updates

The analysis automatically updates when new data is added to the ArcGIS feature service. No manual intervention is required - simply re-render the document to get the latest data.

## Support

For technical issues:
1. Check the troubleshooting section above
2. Review Quarto documentation: [quarto.org/docs](https://quarto.org/docs/)
3. Check R package documentation for specific functions

For data-related questions, contact the Noxious Weeds Monitoring Program.

## License

This project is part of the noxious-weeds monitoring program. See the main repository LICENSE file for details.
