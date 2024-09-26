import streamlit as st
import duckdb
import geopandas as gpd
from shapely import wkb
import pandas as pd
import folium
from streamlit_folium import folium_static
import os

# Access the token from Streamlit Secrets
#motherduck_token = st.secrets["motherduck"]["token"]

# Set the token as an environment variable
#os.environ['motherduck_token'] = motherduck_token

# Fetch the MotherDuck token from Streamlit secrets
os.environ['motherduck_token'] = st.secrets["motherduck_token"]


# Connect to DuckDB
#con = duckdb.connect('noxious_weeds.duckdb', read_only=True)

# Connect to MotherDuck in read-only mode
con_cloud = duckdb.connect('md:_share/duckdb_share_092624/79ce19e5-1e8a-4205-838a-84260250166f', read_only=True)
# Load data from MotherDuck
data = con_cloud.execute('SELECT * FROM lela2_data').fetchdf()

# Close the connection to free up the database
con_cloud.close()

# Load data
#data = con.execute('SELECT * FROM lela2_data').fetchdf()

# Close the connection to free up the database
#con.close()

# Convert the WKB back to geometry
data['geometry'] = data['geometry_wkb'].apply(lambda wkb_data: wkb.loads(bytes.fromhex(wkb_data)))

# Drop WKB column as we now have geometry
gdf = gpd.GeoDataFrame(data, geometry='geometry', crs="EPSG:4326")

# Ensure 'Date' column is properly converted to datetime
gdf['Date'] = pd.to_datetime(gdf['CreationDate'], unit='ms')

# Streamlit app title
st.title("Lepidium latifolium Distribution")

# Sidebar for date filtering
st.sidebar.header("Filter by Date")
date_filter = pd.to_datetime(st.sidebar.date_input("Start Date", value=pd.to_datetime("2023-09-01")))

# Sidebar - symbology date input
date_threshold = pd.to_datetime(st.sidebar.date_input("Symbology Date Break", pd.to_datetime("2024-09-01")))

# Filter and process the data based on user input
filtered_data = gdf[gdf['Date'] >= date_filter]

# Extract the latest creation date from the records
latest_date = filtered_data['Date'].max()

# Display the latest data update information
if pd.notnull(latest_date):
    st.markdown(f"**Last Data Update: {latest_date.strftime('%m/%d/%Y')}**")
else:
    st.markdown(f"**Last Data Update: No records available**")

# Sort the data by creation date and filter before/after threshold
gdf_sorted = filtered_data.sort_values(by='Date', ascending=False)
gdf_before = gdf_sorted[gdf_sorted['Date'] < date_threshold]
gdf_after = gdf_sorted[gdf_sorted['Date'] >= date_threshold]

# Create a folium map
m = folium.Map(location=[36.832208, -118.143997], zoom_start=10, width="100%", height="700px")

# Plot red points (after the date threshold)
for idx, row in gdf_after.iterrows():
    folium.CircleMarker(
        location=[row['geometry'].y, row['geometry'].x],
        radius=5,
        color='red',
        fill=True,
        fill_color='red',
        fill_opacity=0.8,
        popup=(f"CreationDate: {row['Date']}<br>Species: {row['Species']}<br>Abundance: {row['Abundance']}<br>Notes: {row['Notes']}<br>")
    ).add_to(m)

# Plot yellow points (before the date threshold)
for idx, row in gdf_before.iterrows():
    folium.CircleMarker(
        location=[row['geometry'].y, row['geometry'].x],
        radius=5,
        color='yellow',
        fill=True,
        fill_color='yellow',
        fill_opacity=0.8,
        popup=(f"CreationDate: {row['Date']}<br>Species: {row['Species']}<br>Abundance: {row['Abundance']}<br>Notes: {row['Notes']}<br>")
    ).add_to(m)

# Display the map
folium_static(m)

# Display the full interactive table below the map
st.subheader("Observations Table")
st.dataframe(filtered_data[['Species', 'Date', 'Abundance', 'Notes']])
