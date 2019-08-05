# JERFOUCRU INSTRUCTION

## SUMMARY
The entire project is divided into 3 parts
1. [**Training Random Forest**](#part-1-training-random-forest): This part includes functions to preprocess data (adjust CRS, calibrate coordinates, ...), create train-validate-test set, perform Overlay and EM disaggregate, training model (on python), and other supporting functions to visualize
2. [**Generate Cases**](#part-2-generate-cases): This part includes functions to generate cases at pixel levels and country-wide levels. It also contains functions to adjust the population data (from the mapping to match with UN data)
3. [**Comparing with WHO Incidence Grouping (WHO-IG)**](#part-3-comparing-with-who-incidence-grouping): The last part comprises functions visualizing the cases (or population, etc) between RF and WHO-IG data

Each folder will have similar structure:
1. **Script** files: Code
2. **_Data_** folder: containing all of needed data in order to be able to run the scripts
3. **_Generate_** folder: containing the results after running the scipts (if they produce and save something)

#### SUPPORTING LIBRARY [R]
Need to install the following libraries: sp, raster, rgdal, tidyverse, ggplot2, dplyr, tidyr, rgeos, grid, gridExtra, rprodlim, corrplot, randomForestSRC 
<br/>Optional: Rcpp, rasterVis, latticeExtra

#### SUPPORTING LIBRARY [Python]
Need to install the following libraries: warning, os, numpy, pandas, pickle, time, sys, collection, sklearn (Some of them are basic libraries and already installed)


## PART 1. TRAINING RANDOM FOREST
Because the downloaded data as well as some other intensive data are difficult to upload to Github, I have run almost the code for you. You can run from Step 8.

### Work Flow
0. Download TIF file from the internet and convert FOI shapefile to raster map
1. Crop the downloaded file (within the boundary of a shapefile, e.g Endemic shapefile). [(Go to Step 1)](#step-1-crop-boundary-of-downloaded-tif-files)
2. Calibrate the cropped file. [(Go to Step 2)](#step-2-reprojectaggregateresample-cropped-tif-files)
<br/>2.1: Reproject to the specific CRS and convert to corresponding resolution in the new CRS
<br/>2.2: Aggregate to the specific resolution (e.g from 1x1km aggregate to 5x5km)
<br/>2.3: Resample to ensure all files share same coordinates (need to decide which file is the reference map)
3. Gather all calibrated maps to create dataframe including features and outcome (FOI) columns. [(Go to Step 3)](#step-3-create-a-dataframe-including-all-information-of-calibrated-tif-files)
4. Run randomForestSRC to impute the missing values in the dataframe. [(Go to Step 4)](#step-4-use-randomforestsrc-to-run-the-imputation-random-forest-not-the-prediction-model)
5. Perform Overlay Adjustment to find out the exactly mean FOI values of the non-overlay regions. [(Go to Step 5)](#step-5-perform-overlay-adjustment-in-foi)
6. Perform EM to disaggregate data. [(Go to Step 6)](#step-6-perform-em-to-disaggregate-foi-values)
7. Create Train-Validate-Test subset by building a 400x400km grids (or other resolutions). [(Go to Step 7)](#step-7-create-grids-to-divide-dataset-into-3-subset-train-validate-test)
8. Train the model and save the result. **(Run on Python)** [(Go to Step 8)](#step-8-train-the-random-forest-model)
9. Plot the feature importance. [(Go to Step 9)](#step-9-plot-the-feature-importance)

### Core Functions 
#### Step 0: Convert FOI Shapefile to FOI raster map
Here we used QGIS software to convert shapefile to raster (TIF) file. The original FOI shapefile (created by fitting catalytic model to age-stratified cases data) is located in **_Data/Shapefile_FOI/_**. Below is how we can convert it to the TIF file (Click the GIF to have better resolutions). The result will be a raster map with the resolution of 1x1km (based on the option in QGIS) and it is stored in **_Data/Original_FOI_Map/_** folder.
![QGIS-instruction](https://user-images.githubusercontent.com/15571804/62196660-a07dfe00-b3a8-11e9-8bf6-7040ba36de82.gif)

#### Step 1: Crop boundary of downloaded TIF files
Data downloaded from the internet usually is entire map. We need to crop it within the endemic area.

**Input**
<br/>In order to run this step, we will need the boundary shapefile file and put it in **_Data/Shapefile_Endemic_** folder (We can copy from [Part 2](#part-2-generate-cases) folder **_Generate_Cases/Data/Shapefile_Endemic_**). Besides, the downloaded TIF files should be in the respective subfolders in **_Data/Downloaded_Data/_** folder.

**Output**
<br/>The cropped maps will be in **_Generate/Cropped_** folder.

**Functions**
- **Crop_Boundary_Single_File**: Simple script for cropping a single TIF file. It is suitable when you want to try the cropping process to a random TIF file.
- **Crop_Boundary_All_Files**: Perform cropping process to entire covariate files (bioclimate, demography, pigs, ...). Note that before using this script, you need to have the well-organized folders containing these covariate files.

#### Step 2: Reproject/Aggregate/Resample CROPPED TIF files
Note: These steps will extrapolate values at each new coordinate by using 2 given methods:
- **‘bilinear’** : for continuous values 
- **‘ngb’**/nearest neighbor : for categorical values
- **'sum'**: self-created function which is suitable for population variable (pop in large pixel = sum of all pop in small pixels inside the large pixel)

The Calibrate process consists of 3 following steps:
1. Reproject: reproject to the same CRS, and also convert to the corresponding resolution (Ex: 30 seconds resolution = 1x1km = 0.00833 deg) → need to check manually about this number then run the code.
2. Aggregate: aggregate from small resolution to higher (Ex: from 1x1 to 5x5km): can create new method (called **sum**) for the cases population at 5x5 is the sum of all pixel at 1x1 resolution (not only bilinear or ngb)
3. Resample: sample in order to match the same coordinates with a reference TIF file

**Input**
<br/>Before running this script, we need to re-organize the cropped TIF files a bit. We should put the above cropped maps in respective subfolders of them. (Ex: create a subfolder **_Pigs_** in **_Cropped_** folder and move the __Cropped_Pigs.tif__ to **_Pigs_** folder). The input of this script is the above cropped maps. Besides, we also need a reference map to match other maps to the reference coordinates → Run **Create_Reference_For_Calibrate** first (I have run it for you).

**Output**
<br/>The calibrated maps will be in **_Generate/Calibrated_** folder.

**Functions**
- **Create_Reference_For_Calibrate**: Create a reference map which will be used for Calibrate function. I suggest to use FOI map to be the reference map. This script will use the original FOI map from [Step 0](#step-0-convert-foi-shapefile-to-foi-raster-map). I have run it and saved to **_Generate/Calibrated/FOI_**.
- **Calibrate_Raster_Single_Files**: Simple script for calibrating a single TIF file. It is suitable when you want to try the calibrating process to a random TIF file.
- **Calibrate_Raster_All_Files**: Perform calibrating process to entire [**CROPPED**](#step-1-crop-boundary-of-downloaded-tif-files) covariate files (bioclimate, demography, pigs, ...). Note that before using this script, you need to have the well-organized folders containing these covariate files.

#### Step 3: Create a dataframe including all information of calibrated TIF files
Extract all features values from calibrated maps at each coordinates and gather into 1 dataframe.

**Input**
<br/> The main input is calibrated maps created as above. Besides, we also need to choose 1 calibrated map to become a reference map. The reference map is the map that have least missing values, hence it will have full of coordinates in the endemic areas. The reference should be one of Bioclimatic features (as they almost do not have missing values). Then we only keep the Land-pixels only (since we do not consider water-pixels). The Land-Water classification is also one of downloaded maps. Land-pixels will have the values of 0 in that feature column.

**Output**
<br/> Dataframe named **Original_Features_Endemic.Rds** will be created at **_Generate/Gather_DF/_** folder. We also saved the full dataframe (including Land and Water pixels) named **Original_Features_Endemic_Land_Water.Rds** (but maybe we won't use it).

**Functions** 
- **Gather_Features_Dataframe**: Gather all values of calibrated TIF files and create a dataframe containing pixel coordinates and its values for each feature. You also need to rename the column names in the gathered dataframe because the original column names will be messy. Note that before using this script, you need to have the well-organized folders containing the calibrated covariate files.

#### Step 4: Use randomForestSRC to run the imputation random forest (not the prediction model)
Random Forest also provide the imputation algorithm. To make it independent with the FOI, we can remove the FOI column in the dataframe created in [Step 3](#step-3-create-a-dataframe-including-all-information-of-calibrated-tif-files), then run the imputation random forest. Note that this step requires a large amount of RAM (since R is not a good choice for these kind of techniques) and it will take a long time to finish. I have run this (long time ago), hence we can use this data instead of running this again. We can run this script again when we have new data. 
<br/>It will be the best if we can adjust population data after the imputation step. The adjust population process will be described in [Part 2](#part-2-generate-cases). After we run the imputation RF model, we can run **Adjust_Pop_To_Match_UN** function and match their result values to the imputed dataframe. Here we have matched it for you.
<br/>After we imputed missing values for the dataframe representing entire endemic areas, we extracted Study Catchment Area dataframe. This Study dataframe only contains pixels that have FOI values, which were obtained by fitting catalytic model to age-stratified cases data. 

**Input**
<br/> We will use Random Forest to impute the missing values in the gathered dataframe from Step 3. Note that we will remove the FOI column during the imputation step to make features not bias to the FOI values.

**Output**
<br/> The imputed dataframe named **Imputed_Features_Endemic.Rds**, and **Imputed_Features_Study.Rds** will be created at **_Generate/Imputed_DF/_** folder.

**Functions**
- **Imputation_RF**: Run the imputation Random Forest Model to impute missing values in each features **_(Not yet included)_**
- **Evaluate_Imputation**: Try to evaluate the imputation of RF by creating pseudo-NA data. Some of non-NA positions at each feature will be assigned NA, then run the RF to impute these values again. We will use R-squared to evaluate the accuracy of the imputation RF. **_(Not yet included)_**
- **Extract_Study_Dataframe**: Extract Study Catchment Area dataframe from imputed Endemic data frame.

#### Step 5: Perform Overlay adjustment in FOI
This step is one of the most complicated steps. This step will use the Study Catchment Area dataframe. There is an issue (called **_Overlay_** issue) in a calibrated FOI TIF file. The Overlay issue is the case that some catchment areas lie inside other catchment areas. In this case, we assume that the catalytic modelled FOI value of the big catchment area will be the mean of FOI values of all pixels that lie in the big regions (including pixels that lie in smaller catchment areas but belong to the bigger one). Therefore, the FOI values of pixels that are in the big catchment area but not inside smaller catchment areas need to be adjusted to constrain with the assumption.

**Input**
<br/> This script will use **Imputed_Feature_Studies.Rds**. We will perform Overlay adjustment in the Study dataframe.
<br/> For complicated Overlay problems in India and Nepal, we will need the their shapefiles, which indicate the boundaries of subregions in the countries. We put the shapefiles in **_Data/Shapefile_Overlay/_** folder.

**Output**
<br/> **Assign_Regions_For_Adjust_Overlay** will create a dataframe **Coordinates_Index_Study.Rds** (in **_Generate/Overlay_DF/_** folder) and list of TIF files (in **_Generate/Overlay_TIF/_** folder). The dataframe includes coordinates of pixels and their corresponding study indexes. These indexes are visualized through the list of TIF files.
<br/>**Adjust_Overlay** will create the overlay adjusted dataframe, which is the main result, named **Adjusted_Overlay_Study.Rds** (in **_Generate/Overlay_DF/_** folder). This dataframe includes 4 columns: x-y coordinates, adjusted overlay FOI values, and study indexes.

**Functions**
- **Assign_Regions_For_Adjust_Overlay**: Assign index for pixels having the same FOI values (which means these pixels will belong in the same regions). These indexes will be used to check which regions are overlay or non-overlay. (This checking part is done manually by viewing on QGIS with the highest level of carefulness)
- **Regions_Index_Information**: This script just provides information about indexes generated by **Assign_Regions_For_Adjust_Overlay**. By looking at this script, we will know how the regions affect others. And use this information to run **Adjust_Overlay**. This script is created manually by doing analysis and observing regions on QGIS.
- **Adjust_Overlay**: Only run after you did run **Assign_Regions_For_Adjust_Overlay**. Run the overlay adjustment after you knew which regions are overlay and non-overlay. You need to know how the regions overlay (e.g. which region indexes are inside other indexes)

#### Step 6: Perform EM to disaggregate FOI values
Run EM to disaggregate FOI values to each pixels. The constrain is that the FOI value at 1 region will be the mean of FOI of all pixels belong to that region. Here we implemented EM algorithm based from **_flowerdew1992_** article. We need 2 extra features related to FOI. 1 of 2 features need to have a positive correlation with the FOI. By plotting correlationship graph, we choose Bio_15 is the positive correlation feature. The second feature is Bio_04, which is the most important features after running Random Forest (imputing). 

**Input**
<br/> We will need the Overlay Adjusted FOI values and Study Index from **Adjusted_Overlay_Study.Rds** [(Step 5)](#step-5-perform-overlay-adjustment-in-foi) and Imputed Features from **Imputed_Features_Study.Rds** [(Step 4)](#step-4-use-randomforestsrc-to-run-the-imputation-random-forest-not-the-prediction-model). We will need to check whether 2 coordinates columns from 2 dataframes match or not.

**Output**
<br/> This script will create a dataframe **EM_Imputed_Features_Study.Rds** in **_Generate/EM_DF/_** folder. This dataframe contains coordinates of all Study Catchment Area pixels and their imputed features values along with EM Disaggregated FOI values.

**Function**
- **EM_Disaggregate**: Perform EM and save dataframe to Rds.

#### Step 7: Create Grids to divide dataset into 3 subset: Train-Validate-Test
Create Sampling Grids (with large resolution: 200, 300, 400, 500km). One of these Grids will be used for sampling 3 subsets: Training, Validating, and Testing (in Python.

**Input**
<br/> This script requires Calibrated FOI TIF map ([Step 2](#step-2-reprojectaggregateresample-cropped-tif-files)) and **EM_Imputed_Features_Study.Rds** ([Step 6](#step-6-perform-em-to-disaggregate-foi-values)). We need the extent CRS from the TIF and the coordinates of pixels from the Study dataframe.

**Output**
<br/> Grids CSV, named as **Grid_[resolution]_[resolution].csv**, will be created in **_Generate/Grids_CSV/_** folder. This CSV will have 3 columns: x-y coordinates, and the Grid index of each pixel. Grid index indicates which Grid in which the pixel lies.

**Function**
- **Create_Sampling_Grids**: This script will need the extent (coordinates limitation) of a calibrated FOI map and the coordinates of all pixels in that map. The result will be a dataframe containing 3 columns: x, y (coordinates), and grids index. 

#### Step 8: Train the Random Forest Model
This step need to be done by Python. Comparing with R, Python can train the RF model much faster and requires less memory than R. Since this step will run on Python, **_all of the input data need to be converted to CSV files_**. You can use the supporting function [**Dataframe_To_CSV**](#supporting-functions) to convert Rds files into CSV files. Default setting will store the result in **_Generate/Python_CSV/_** folder.
 
**Input**
<br/> This step requires Sampling Grid csv file, **EM_Imputed_Features_Study.Rds** from [step 7](#step-7-create-grids-to-divide-dataset-into-3-subset-train-validate-test), and **Imputed_Features_Endemic.Rds** from [step 4](#step-4-use-randomforestsrc-to-run-the-imputation-random-forest-not-the-prediction-model). You have to convert 2 Rds files into CSV format before running the training script.

**Output**
<br/> All the result files will be saved at **_Generate/Python_Export/_** folder. The result includes **Model**, **Grid index** indicating which pixels will be in Training-Validating-Testing set, **R-squared result** on Training and Validating set, **Endemic FOI** predicted by the model, **Variable important** of each feature. 

**Function**
- **Train_Model_RandomForest.py**: Sample which sampling grids will be used for training, validating, and testing. Then it will train the RF model and save the result, accuracy, variable importance, ... to CSV files (We can use R to plot these files later). 

#### Step 9: Plot the feature importance
Basically, this is not a complicated step. Based on your wishes, you can plot the generated files from the above steps (EM, RF model, variable importance, ...). Here I just provided a simple example to plot feature importance produced after running Random Forest ([Step 8](#step-8-train-the-random-forest-model)).

**Input**
<br/> This script will read the **Variable important** produced in [Step 8](#step-8-train-the-random-forest-model) and plot 2 figures. The first figure is about feature importance values and their standard deviation. The second figure is about feature importance and their IQR range. 

**Output**
<br/> 2 Figures named **Feature_Importance_Std.png** and **Feature_Importance_IQR.png** will be saved in **_Generate/Python_Export/Figures/_** 

**Function**
- **Plot_Feature_Importance**: reads the Variable important csv file and saves 2 figures.

### Supporting Functions  
- **Create_Raster_From_Dataframe**: This simple script provides a way how to create a raster (map) as a TIF file from a dataframe (RDS, or CSV). The dataframe has 3 columns: x, y (coordinates of a pixel), values (values that we want to visualize in a map).
- **Calculate_Missing_Portion_Features**: Find the missing portion of each column in a dataframe (can use this to find missing portion of each feature in the original dataframe, original means before imputing step)
- **Dataframe_To_CSV**: This simple script provides a way how to convert Rds (dataframe) to csv files so that Python can read the data to run Random Forest.
- **Plot_Correlation_Matrix**: Plot the correlation coefficient between features and the FOI values. Can use this for choosing a feature that have strong positive (negative) relationship with FOI and use that feature in [**EM_Disaggregation**](#step-6-perform-em-to-disaggregate-foi-values). The input can plot the correlation matrix based on Overlay Adjustment dataframe (main reason), or based on EM Disaggregation dataframe. The second option can only run after you ran the [EM Step](#step-6-perform-em-to-disaggregate-foi-values).
- **Sampling_Many Grids.py**: This script will generate Train-Validate-Test sets many times, which will be used to train many random forest models. But in this scope, we only train 1 random forest model. **_Therefore we will not use this function_**.

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
1. Find the population of each country (extract from the map). Do this by creating Country Index for each pixel on the map indicating which countries that a pixel belongs to → Run **Assign_Endemic_Regions** (This will take a while to finish, so I have run it for you. Dont need to run it again. Dont run this file unless you want or there is something change about the endemic map)
2. Adjust the population data to match with UN data and Quan subnation data (PAK, RUS, AUS). Adjust on country level first, then find the ratio and adjust on pixel level → Run **Adjust_Pop_To_Match_UN**
3. Extract age-distribution population based from VIMC (Quan data) → Run **Extract_Age_Distribution_Population**
4. Generate cases at each pixel (Now we have FOI and age-distribution population at each pixel)→ Run **Generate** script

### Functions
- **Assign_Endemic_Regions**: assign a country index for each pixel to indicate which countries that the pixel belongs to → The results will be saved as 2 files: **_Coord_Regions_Final.Rds_** and **_Country_Index.Rds_** (These 2 files will be used in **_COMPARING WITH WHO-IG_** Part also)
- **Adjust_Pop_To_Match_UN**: Calibrate population data from map (store in a dataframe of RF) to match with the UN population. Note that for countries that endemic areas are entire countries, we will match with the UN data, however for countries that endemic areas are a part of their countries we will match with the Quan’s subnational data (PAK, RUS, AUS) → The result will be saved as **_Adjusted_Pop_Map.Rds_**
- **Extract_Age_Distribution_Population**: Take the age distribution population data from Quan data and only keep data in the year 2015. Meanwhile, also remove some regions that Quan did not use to generate cases
- **Generate_Cases_Dataframe**: Generate cases at each pixel at each ages from 0 to 99 → The result will be 101 Rds files. Each file is the cases at 1 age, the last file is the total cases of all age group (Sum of 100 previous files)
- **Generate_Cases_Map**: Convert above 101 Rds files into 101 raster maps (but we should only plot the total cases of all ages at each pixel). This function is just the same as **Create_Raster_From_Dataframe** but more specific to plot a Rds file.
- **Generate_Cases_Map_Country**: Plot the shapefile map (not raster) in which values representing for each country is the total cases of entire country

## PART 3. COMPARING WITH WHO INCIDENCE GROUPING
**_Please note that you only run this COMPARING part after you did run the GENERATE CASES part._**
<br/>Most of the data used for this part is from the **_GENERATE CASES_** part. Therefore there is no Data folder in this part. However there is a **_Quan_Result folder_**, which contains the generated cases WHO-IG did by Quan.

### Work Flow
Most of this part is for visualizing the comparison between RF and WHO-IG (Population, FOI distribution, Cases). These following script is independent to each other, hence you can run it seperately.

### Functions
- **Extract_Cases_Country**: Take the cases file (dataframe containing cases at each coordinates) which was produced after GENERATE CASES step, then compare with the (original) cases file that was generated from Quan by doing as WHO Incidence Grouping (WHO-IG). Also plot the bar chart.
- **Extract_FOI_Country**: Compare FOI distribution of a country between RF and WHO-IG (from Quan result)
- **Extract_Pop_Country**: Compare Population of a country between RF and WHO-IG (from Quan result)
- **Extract_Cases_Country_RF**: Plot the cases generated by RF (produced after GENERATE CASES step)
- **Quan_Cases**: generate cases originally based from Quan code (exactly the same code as Quan's). This file is just a backup of Quan generating code. We will use this file if we want to reproduce cases of WHO-IG when we have different population data.