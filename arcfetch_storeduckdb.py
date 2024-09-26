import duckdb
import geopandas as gpd
from arcgis.gis import GIS
from arcgis.features import FeatureLayer
import pandas as pd
from shapely.geometry import Point

# Connect to the GIS and fetch feature layer
gis = GIS()
feature_service_url_layer = "https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/Noxious_Weeds_view/FeatureServer/0"
feature_layer = FeatureLayer(feature_service_url_layer)

# Query data
features = feature_layer.query(where="1=1", out_fields="*")
data = pd.DataFrame([f.attributes for f in features.features])

# Extract geometry (x and y coordinates)
geometry = [f.geometry for f in features.features]
data['x'] = [geom['x'] for geom in geometry]
data['y'] = [geom['y'] for geom in geometry]

# Convert to GeoDataFrame using x and y columns to create the 'geometry' column
gdf = gpd.GeoDataFrame(data, geometry=gpd.points_from_xy(data['x'], data['y']))

# Check if the GeoDataFrame has the geometry column
if 'geometry' not in gdf.columns:
    print("Error: 'geometry' column not found in GeoDataFrame!")
else:
    print("GeoDataFrame created successfully with 'geometry' column")

# Step 1: Set CRS to EPSG:3857 (Web Mercator) if not already set
if gdf.crs is None:
    gdf.set_crs(epsg=3857, inplace=True)

# Step 2: Convert to EPSG:4326 (latitude/longitude)
gdf = gdf.to_crs(epsg=4326)

# Convert geometry to WKB for DuckDB
gdf['geometry_wkb'] = gdf['geometry'].apply(lambda geom: geom.wkb_hex)
gdf.drop(columns=['geometry'], inplace=True)

# Connect to DuckDB and store data
con = duckdb.connect('noxious_weeds.duckdb')
con.execute('CREATE OR REPLACE TABLE lela2_data AS SELECT * FROM gdf')
con.close()

print("Data successfully stored in DuckDB with proper CRS")
