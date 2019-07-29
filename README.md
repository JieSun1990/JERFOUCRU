# JERFOUCRU INSTRUCTION

## SUMMARY
The entire project is divided into 3 parts
1. **Training Random Forest**: This part includes functions to preprocess data (adjust CRS, calibrate coordinates, ...), create train-validate-test set, perform Overlay and EM disaggregate, training model (on python), and other supporting functions to visualize
2. **Generate Cases**: This part includes functions to generate cases at pixel levels and country-wide levels. It also contains functions to adjust the population data (from the mapping to match with UN data)
3. **Comparing with WHO Incidence Grouping (WHO-IG)**: The last part comprises functions visualizing the cases (or population, etc) between RF and WHO-IG data

Each folder will have similar structure:
1. **Script** files: Code
2. **_Data_** folder: containing all of needed data in order to be able to run the scripts
3. **_Generate_** folder: containing the results after running the scipts (if they produce and save something)

#### SUPPORTED LIBRARY
Need to install the following libraries: sp, raster, rgdal, tidyverse, ggplot2, dplyr, tidyr, Rcpp (this is optional), rgeos, grid, gridExtra, rprodlim

## PART 1. TRAINING RANDOM FOREST

### Work Flow 
0. Download TIF file from the internet
1. Crop the downloaded file (within the boundary of a shapefile, e.g Endemic shapefile)_
2. Calibrate the cropped file
<br/>2.1: Reproject to the specific CRS and convert to corresponding resolution in the new CRS
<br/>2.2: Aggregate to the specific resolution (e.g from 1x1km aggregate to 5x5km)
<br/>2.3: Resample to ensure all files share same coordinates (need to decide which file is the reference map)
3. Gather all calibrated maps to create dataframe including features and outcome (FOI) columns
4. Perform Overlay Adjustment to find out the exactly mean FOI values of the non-overlay regions
5. Perform EM to disaggregate data
6. Create Train-Validate-Test subset by building a 400x400km grids (or other resolutions)
7. Train the model and save the result
8. Plot the variable importance

### Core Functions 
#### Step 1: Crop boundary of downloaded TIF files
- **Crop_Boundary_Single_File**: Simple script for cropping a single TIF file. It is suitable when you want to try the cropping process to a random TIF file.
- **Crop_Boundary_All_Files**: Perform cropping process to entire covariate files (bioclimate, demography, pigs, ...). Note that before using this script, you need to have the well-organized folders containing these covariate files.

#### Step 2: Reproject/Aggregate/Resample CROPPED TIF files
Note: These steps will extrapolate values at each new coordinate by using 2 given methods:
- **‘bilinear’** : for continuous values 
- **‘ngb’**/nearest neighbor : for categorical values
The Calibrate process consists of 3 following steps:
1. Reproject: reproject to the same CRS, and also convert to the corresponding resolution (Ex: 30 seconds resolution = 1x1km = 0.00833 deg) → need to check manually about this number then run the code.
2. Aggregate: aggregate from small resolution to higher (Ex: from 1x1 to 5x5km): can create new method (called **sum**) for the cases population at 5x5 is the sum of all pixel at 1x1 resolution (not only bilinear or ngb)
3. Resample: sample in order to match the same coordinates with a reference TIF file
- **Calibrate_Raster_Single_Files**: Simple script for calibrating a single TIF file. It is suitable when you want to try the calibrating process to a random TIF file.
- **Calibrate_Raster_All_Files**: Perform calibrating process to entire **CROPPED** covariate files (bioclimate, demography, pigs, ...). Note that before using this script, you need to have the well-organized folders containing these covariate files.

#### Step 3: Create a dataframe including all information of calibrated TIF files 
- **Gather_Features_Dataframe**: Gather all values of calibrated TIF files and create a dataframe containing pixel coordinates and its values for each feature. You also need to rename the column names in the gathered dataframe because the original column names will be messy. Note that before using this script, you need to have the well-organized folders containing the calibrated covariate files.

#### Step 4: Perform Overlay adjustment in FOI
This step is one of the most complicated steps. There is an issue (called Overlay issue) in a calibrated FOI TIF file. The Overlay issue is the case that some catchment areas lie inside other catchment areas. In this case, we assume that the catalytic modelled FOI value of the big catchment area will be the mean of FOI values of all pixels that lie in the big regions (including pixels that lie in smaller catchment areas but belong to the bigger one). Therefore, the FOI values of pixels that are not inside smaller catchment areas need to be adjusted to constrain with the assumption. 
- **Assign_Regions_For_Adjust_Overlay**: Assign index for pixels having the same FOI values (which means these pixels will belong in the same regions). These indexes will be used to check which regions are overlay or non-overlay. (This checking part is done manually by viewing on QGIS with the highest level of carefulness)
- **Regions_Index_Information**: This script just provides information about indexes generated by **Assign_Regions_For_Adjust_Overlay**. By looking at this script, we will know how the regions affect others. And use this information to run **Adjust_Overlay**. This script is created manually by doing analysis and observing regions on QGIS.
- **Adjust_Overlay**: Run the overlay adjustment after you knew which regions are overlay and non-overlay. You need to know how the regions overlay (e.g. which region indexes are inside other indexes)

### Supporting Functions  
- **Create_Raster_From_Dataframe**: Create a raster (map) as a TIF file from a dataframe in R. The dataframe has 3 columns: x, y (coordinates of a pixel), values (values that we want to visualize in a map).
- **Calculate_NA_Proportion**: Find the missing portion of each feature in the original dataframe (original means before imputing step)
- **Dataframe_To_CSV**: Convert Rds (dataframe) to csv files so that Python can read the data to run Random Forest

## PART 2. GENERATE CASES 
This folder includes scripts, Data folder and Generate folder.
1. **_Data_** folder includes data that is needed to run the scripts
- Modelled FOI distribution from MCMC (WHO-IG)
- WHO-IG Population (collected from UN and generated by Quan)
- Shapefile of endemic areas
- symptomatic rate (to generate cases, use the same with Quan in order to compare)
- mortality rate (just in case we want to generate deaths, use the same with Quan in order to compare)
- FOI dataframe generated by Random Forest
- (Imputed) Feature dataframe (to get Mapping Population)
2. **_Generate_** folder includes generated results after running scripts. It will generate 3 subfolders
- Cases: Dataframe contains cases at each pixel (levels by age group, or all age groups)
- Cases_TIF: Raster maps (TIF) in which each pixel is a cases at each age group (or all age groups) 
- Cases_SHP: Vector maps (Shapfile) in which values at each country is the total cases of all age groups 

### Work Flow 
1. Find the population of each country (extract from the map). Do this by creating Country Index for each pixel on the map indicating which countries that a pixel belongs to → Run **Assign_Endemic_Regions** (This will take a while to finish. Dont run this file unless you want or there is something change about the endemic map)
2. Adjust the population data to match with UN data and Quan subnation data (PAK, RUS, AUS). Adjust on country level first, then find the ratio and adjust on pixel level → Run **Adjust_Pop_To_Match_UN**
3. Extract age-distribution population based from VIMC (Quan data) → Run **Extract_Age_Distribution_Population**
4. Generate cases at each pixel (Now we have FOI and age-distribution population at each pixel)→ Run **Generate** script

### Functions
- **Extract_Age_Distribution_Population**: Take the age distribution population data from Quan data and only keep data in the year 2015. Meanwhile, also remove some regions that Quan did not use to generate cases
- **Assign_Endemic_Regions**: assign a country index for each pixel to indicate which countries that the pixel belongs to → The results will be saved as 2 files: *Coord_Regions_Final.Rds* and *Country_Index.Rds* (These 2 files will be used in **_COMPARING WITH WHO-IG_** Part also)
- **Adjust_Pop_To_Match_UN**: Calibrate population data from map (store in a dataframe of RF) to match with the UN population. Note that for countries that endemic areas are entire countries, we will match with the UN data, however for countries that endemic areas are a part of their countries we will match with the Quan’s subnational data (PAK, RUS, AUS) → The result will be saved as *Adjusted_Pop_Map.Rds*
- **Generate_Cases_Dataframe**: Generate cases at each pixel at each ages from 0 to 99 → The result will be 101 Rds files. Each file is the cases at 1 age, the last file is the total cases of all age group (Sum of 100 previous files)
- **Generate_Cases_Map**: Convert above 101 Rds files into 101 raster maps (but we should only plot the total cases of all ages at each pixel). This function is just the same as **Create_Raster_From_Dataframe** but more specific to plot a Rds file.
- **Generate_Cases_Map_Country**: Plot the shapefile map (not raster) in which values representing for each country is the total cases of entire country

## PART 3. COMPARING WITH WHO INCIDENCE GROUPING
**_Please note that you can run this COMPARING part only after you did run the GENERATE CASES part._**
<br/>Most of the data used for this part is from the **_GENERATE CASES_** part. Therefore there is no Data folder in this part. However there is a **_Quan_Result folder_**, which contains the generated cases WHO-IG did by Quan.

### Work Flow
Most of this part is for visualizing the comparison between RF and WHO-IG (Population, FOI distribution, Cases). These following script is independent to each other, hence you can run it seperately.

### Functions
- **Extract_Cases_Country**: Take the cases file (dataframe containing cases at each coordinates) which was produced after GENERATE CASES step, then compare with the (original) cases file that was generated from Quan by doing as WHO Incidence Grouping (WHO-IG). Also plot the bar chart.
- **Extract_FOI_Country**: Compare FOI distribution of a country between RF and WHO-IG (from Quan result)
- **Extract_Pop_Country**: Compare Population of a country between RF and WHO-IG (from Quan result)
- **Extract_Cases_Country_RF**: Plot the cases generated by RF (produced after GENERATE CASES step)
- **Quan_Cases**: generate cases originally based from Quan code (exactly the same code as Quan's). This file is just a backup of Quan generating code. We will use this file if we want to reproduce cases of WHO-IG when we have different population data.