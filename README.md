JERFOUCRU --- README FIRST

$$ SUMMARY $$
The entire project is divided into 3 parts
1. Training Random Forest: This part includes functions to preprocess data (adjust CRS, calibrate coordinates, ...), create train-validate-test set, perform Overlay and EM disaggregate, training model (on python), and other supporting functions to visualize
2. Generate Cases: This part includes functions to generate cases at pixel levels and country-wide levels. It also contains functions to adjust the population data (from the mapping to match with UN data)
3. Comparing with WHO Incidence Grouping (WHO-IG): The last part comprises functions visualizing the cases (or population, etc) between RF and WHO-IG data

$$ SUPPORTED LIBRARY $$
Need to install the following libraries: sp, raster, rgdal, tidyverse, ggplot2

~~~~~~~~~~~~~~~~~~~~~~~ TRAINING RANDOM FOREST ~~~~~~~~~~~~~~~~~~~~~~~

========== Work Flow ==========
1. Download TIF file from the internet
2. Crop the downloaded file (within the boundary of a shapefile, e.g Endemic shapefile)_
3. Calibrate the cropped file
3.1: Reproject to the specific CRS and convert to corresponding resolution in the new CRS
3.2: Aggregate to the specific resolution (e.g from 1x1km aggregate to 5x5km)
3.3: Resample to ensure all files share same coordinates (need to decide which file is the reference map)
4. Gather all calibrated maps to create dataframe including features and outcome (FOI) columns
5. Perform Overlay Adjustment to find out the exactly mean FOI values of the non-overlay regions
6. Perform EM to disaggregate data

========== Core Functions ==========
*** Step 1: Crop boundary of downloaded TIF file  ***
- Crop_Boundary_Single_File
- Crop_Boundary_All_Files

*** Step 2: Reproject/Aggregate/Resample cropped TIF File  ***
Note: These steps will extrapolate values at each new coordinate by using 2 given methods:
    • ‘bilinear’ : for continuous values 
    • ‘ngb’/nearest neighbor : for categorical values
1. Reproject: reproject to the same CRS, and also convert to the corresponding resolution (Ex: 30 seconds resolution = 1x1km = 0.00833 deg) → need to check manually about this number then run the code.
2. Aggregate: aggregate from small resolution to higher (Ex: from 1x1 to 5x5km): can create new method for the cases population at 5x5 is the sum of all pixel at 1x1 resolution (not only bilinear or ngb)
3. Resample: sample in order to match the same coordinates with a reference TIF file
- Calibrate_Raster.R



========== Supporting Functions ========== 
- Create_Raster_From_Dataframe


~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GENERATE CASES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

========== Work Flow ==========
1. Find the population of each country (extract from the map). Do this by creating Country Index for each pixel on the map indicating which countries that a pixel belongs to
2. Adjust the population data to match with UN data and Quan subnation data (PAK, RUS, AUS). Adjust on country level first, then find the ratio and adjust on pixel level
3. Extract age-distribution population based from VIMC (Quan data)
4. Generate cases at each pixel (Now we have FOI and age-distribution population at each pixel)

========== Functions ==========
- Extract_Age_Distribution_Population: Take the age distribution population data from Quan data and only keep data in the year 2015. Meanwhile, also remove some regions that Quan did not use to generate cases
- Assign_Endemic_Regions: assign a country index for each pixel to indicate which countries that the pixel belongs to → The results will be saved as 2 files: Coord_Regions_Final.Rds and Country_Index.Rds
- Adjust_Pop_To_Match_UN: Calibrate population data from map (store in a dataframe of RF) to match with the UN population. Note that for countries that endemic areas are entire countries, we will match with the UN data, however for countries that endemic areas are a part of their countries we will match with the Quan’s subnational data (PAK, RUS, AUS) → The result will be saved as Adjusted_Pop_Map.Rds
- Generate_Cases_Dataframe: Generate cases at each pixel at each ages from 0 to 99 → The result will be 101 Rds files. Each file is the cases at 1 age, the last file is the total cases of all age group (Sum of 100 previous files)
- Generate_Cases_Map: Convert above 101 Rds files into 101 raster maps (but we should only plot the total cases of all ages at each pixel). This function is just the same as <Create_Raster_From_Dataframe> but more specific to plot a Rds file.
- Generate_Cases_Map_Country: Plot the shapefile map (not raster) in which values representing for each country is the total cases of entire country

~~~~~~~~~~~~~~ COMPARING WITH WHO INCIDENCE GROUPING ~~~~~~~~~~~~~~

- Extract_Cases_Country: Take the cases file (dataframe containing cases at each coordinates) which was produced after GENERATE CASES step, then compare with the (original) cases file that was generated from Quan by doing as WHO Incidence Grouping (WHO-IG). Also plot the bar chart.
- Extract_FOI_Country: Compare FOI of a country distribution between RF and WHO-IG (from Quan result)
- Extract_Cases_Country_RF: Plot the cases generated by RF (produced after GENERATE CASES step)
- Quan_Cases: generate cases originally based from Quan code (exactly the same code)