import streamlit as st
import pandas as pd
import geopandas as gpd
from arcgis.gis import GIS
from arcgis.features import FeatureLayer
import folium
from shapely.geometry import Point
from streamlit_folium import folium_static
import matplotlib.pyplot as plt

# Streamlit app title
st.title("Lepidium latifolium Distribution")

# Sidebar for date filtering
st.sidebar.header("Filter by Date")
date_filter = st.sidebar.date_input("Select Date", value=pd.to_datetime("2023-09-01"))

# Connect to the GIS and fetch feature layer (ArcGIS only for connection)
gis = GIS()
feature_service_url_layer = "https://services.arcgis.com/0jRlQ17Qmni5zEMr/arcgis/rest/services/Noxious_Weeds_view/FeatureServer/0"
feature_layer = FeatureLayer(feature_service_url_layer)

# Query data (ArcGIS part is still used here)
features = feature_layer.query(where="1=1", out_fields="*")

# Extract the attributes and geometries into a pandas DataFrame
# You must use .get_value() to access fields and geometry
attributes = [f.attributes for f in features.features]
geometry = [f.geometry for f in features.features]

# Create the pandas DataFrame from attributes
data = pd.DataFrame(attributes)

# Add the geometries (x and y) to the dataframe
data['x'] = [geom['x'] for geom in geometry]
data['y'] = [geom['y'] for geom in geometry]

# Convert 'CreationDate' to datetime format
data['Date'] = pd.to_datetime(data['CreationDate'], unit='ms')

# Filter data for date selection (2023-09-01 and after)
filtered_data = data[data['Date'] >= pd.to_datetime(date_filter)]

# Create geometry column and convert to GeoDataFrame in EPSG:3857 (Web Mercator)
geometry_points = [Point(xy) for xy in zip(filtered_data['x'], filtered_data['y'])]
gdf = gpd.GeoDataFrame(filtered_data, geometry=geometry_points, crs="EPSG:3857")

# Convert the GeoDataFrame to EPSG:4326 (latitude/longitude)
gdf = gdf.to_crs(epsg=4326)


# Sidebar - symbology date input
date_threshold = st.sidebar.date_input("Symbology Date Break: yellow before, red after", pd.to_datetime("2024-09-01"))
date_threshold = pd.to_datetime(date_threshold)

# Ensure 'CreationDate' is in datetime format
gdf['CreationDate'] = pd.to_datetime(gdf['CreationDate'], unit='ms')

# Filter and sort data
gdf_sorted = gdf[gdf['geometry'].notnull()].sort_values(by='CreationDate', ascending=False)

# Filter points before and after the threshold
gdf_before = gdf_sorted[gdf_sorted['CreationDate'] < date_threshold]
gdf_after = gdf_sorted[gdf_sorted['CreationDate'] >= date_threshold]

#st.write(gdf[['x', 'y', 'geometry']].head())

# Create a larger folium map
m = folium.Map(location=[36.832208, -118.143997], zoom_start=10, width="100%", height="700px")

# Plot red points (after the date)
for idx, row in gdf_after.iterrows():
    folium.CircleMarker(
        location=[row['geometry'].y, row['geometry'].x],
        radius=5,  # Size of the marker
        color='red',  # Border color
        fill=True,
        fill_color='red',  # Fill color
        fill_opacity=0.8,
        popup=(f"CreationDate: {row['CreationDate']}<br>"
               f"Species: {row['Species']}<br>"
               f"Abundance: {row['Abundance']}<br>"
               f"Notes: {row['Notes']}<br>"),
    ).add_to(m)

# Plot yellow points (before the date)
for idx, row in gdf_before.iterrows():
    folium.CircleMarker(
        location=[row['geometry'].y, row['geometry'].x],
        radius=5,  # Size of the marker
        color='yellow',  # Border color
        fill=True,
        fill_color='yellow',  # Fill color
        fill_opacity=0.8,
        popup=(f"CreationDate: {row['CreationDate']}<br>"
               f"Species: {row['Species']}<br>"
               f"Abundance: {row['Abundance']}<br>"
               f"Notes: {row['Notes']}<br>"),
    ).add_to(m)

# Display the map larger
folium_static(m)



