#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 11 15:22:39 2019
Dividing all grids to 7 - 1.5 - 1.5 for train - validate - test
Only train 1 random forest (not sub sampling in train, not run multiple models, not remove some selected regions)
* Adjust 08/04/2019
--- Add option for Area: Entire or Land --> Land is remove Water pixelin the map 
--- Store training time
* Adjust 02/05/2019
--- Add option to remove Pop_2015 features (Pop density) --> default is 'remove'\
--- Save variable importance ranking in csv (to plot later)
@author: duynguyen
"""

import warnings
warnings.filterwarnings('ignore')
import os
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
import pickle
import time
import sys
from collections import Counter

def MyRsq(predict, actual):
    dif = predict - actual
    dif = dif ** 2
    mse = np.mean(dif)
    rsq = 1 - mse / np.var(actual)
    return rsq

np.random.seed(5) # set seed to regenerate the same random result

Typemodel = 'Full_Cov' # if Full Cov model
#Typemodel = 'Only_Bio' # if only bio model 

#Area = 'Entire'
Area = 'Land'

Train_Portion = 0.7 # Portion of Train - Validate - Test
Sampling_Portion = 0.7 # Portion of sampling in Train set
Validate_Portion = (1 - Train_Portion) / 2
resolution_grid = 400

Name_Grid_File = 'Grid_' + str(resolution_grid) + '_' + str(resolution_grid) + '.csv'

print('[Type Model] You have chosen ' + Typemodel)

CurDir = os.getcwd()
Data_All = CurDir + '/Data/' + Area + '/AllDF_EM_WP_rescale_Full_Cov_Imputed_Land.csv'
Grid = CurDir + '/Data/' + Area + '/' + Name_Grid_File
Data_EndemicDF = CurDir + '/Data/' + Area + '/EndemicDF_WP_Full_Cov_Imputed_Land.csv'

# Read csv and store in dataframe in pandas
AllData = pd.read_csv(Data_All)
Grid = pd.read_csv(Grid)  
EndemicDF = pd.read_csv(Data_EndemicDF)
EndemicDF = EndemicDF.drop(['FOI'], axis = 1) # remove FOI column (if it has)

# Remove Pop_2015 density (if wanted, since already have Pop_Count people)
AllData = AllData.drop(['Pop_2015'], axis = 1)
EndemicDF = EndemicDF.drop(['Pop_2015'], axis = 1)

# Check if matching coordinator
if (len(AllData.iloc[:, :2].merge(Grid.iloc[:, :2])) == len(AllData.iloc[:, :2])):
    print('[Checking Calibration] Matched Coordinators')
    # Recreate grid to match with AllData in case of nrow of 2 dataframe is different
    t = pd.merge(AllData.iloc[:, : 2].reset_index(), Grid.iloc[:, : 2].reset_index(), on=['x','y'], suffixes=['_1','_2'])
    Grid = Grid.iloc[t['index_2'], :]
    del t
else:
    sys.exit('[Stop Program] Grid and Data File do not match coordinators --> Check again')

# Count freq of pix in each grid
Grid_column = Grid.iloc[:, 2]
Grid_column = np.array(Grid_column)
d = Counter(Grid_column)
grid_freq = np.array(list(d.values())) # number of pix in each grid_numb (belowed)
grid_numb = np.array(list(d.keys()))
del d

# ----- Preprocessing for Sampling train and validate -----
idx_grid_numb_less = np.where(grid_freq < 100)[0] # find idx of grid containing less than 100 pix --> these grids will be automaticly in training set
idx_grid_numb_high = np.where(grid_freq >= 100)[0] # find idx of grid containing more than 100 pix --> these grids will be randomly chosen for training

grid_numb_train_1 = grid_numb[idx_grid_numb_less]
grid_numb_sample = grid_numb[idx_grid_numb_high]

ngrid_train_2 = round(len(grid_numb_sample)*0.7) # 70% train --- 30% test (validate)
ngrid_validate = round(len(grid_numb_sample)*0.15)
ngrid_test = len(grid_numb_sample) - ngrid_train_2 - ngrid_validate
ngrid_train = len(grid_numb_train_1) + ngrid_train_2

print('[Sampling Grid] Training Grids: ' + str(ngrid_train) + ' ----- Validating Grids: ' + str(ngrid_validate) + ' ----- Testing Grids: ' + str(ngrid_test))

print('===== Sampling Model =====')    
grid_numb_sample_shuffle = np.copy(grid_numb_sample)
np.random.shuffle(grid_numb_sample_shuffle)
grid_numb_train_2 = grid_numb_sample_shuffle[:ngrid_train_2]
grid_numb_validate = grid_numb_sample_shuffle[ngrid_train_2:(ngrid_train_2 + ngrid_validate)]
grid_numb_test = grid_numb_sample_shuffle[(ngrid_train_2 + ngrid_validate):]
grid_numb_train = np.append(grid_numb_train_1, grid_numb_train_2)
del grid_numb_sample_shuffle, grid_numb_train_2

# ----- Take index of pixel for each sub-dataset
idx_train = np.where(np.in1d(Grid_column, grid_numb_train))[0]
idx_validate = np.where(np.in1d(Grid_column, grid_numb_validate))[0]
idx_test = np.where(np.in1d(Grid_column, grid_numb_test))[0]

Type = np.zeros(AllData.shape[0])
Type[idx_train] = 1 # index 1 for train
Type[idx_validate] = 2 # index 2 for validate
Type[idx_test] = 3 # index 3 for validate

Coor_Grid_Index = AllData.iloc[:, 0:2]
Coor_Grid_Index = Coor_Grid_Index.assign(Type = pd.Series(Type).values)
print('[Saving] Save Grid Index')
Coor_Grid_Index.to_csv('Grid_Index.csv', sep='\t', encoding='utf-8')
print('[Saving] Done Saving Grid Index')

# ===== Prepare Train =====
Train = AllData.iloc[idx_train, :]
row_na = Train.isnull().any(1) # check whether a row contains NA or not
idx_row_na = row_na.nonzero()[0] # find index of row containing NA
print('[Preprocessing] Total Training containing NA: ' + str(len(idx_row_na)) + ' / ' + str(len(Train)) + ' ----- ' + 
      str(round(len(idx_row_na) / len(Train) * 100, 2)) + '%')
Train_Non_NA = Train.drop(Train.index[idx_row_na]) # remove row containing NA
# ----- Extract Features for model -----
if (Typemodel == 'Full_Cov'):
    # Full Covariates (excluding Pop, Children, UR)
    X_train = Train_Non_NA.drop(['x', 'y', 'FOI'], axis = 1)
else:
    # Only Bio Covariates (excluding Pop, Children, UR)
    X_train = Train_Non_NA.drop(['x', 'y', 'DG_000_014bt_dens', 'Elv', 'Pigs', 'Pop_Count_WP_SEDAC_2015', 'Rice', 'UR', 'VD', 'FOI'], axis = 1)        
Y_train = Train_Non_NA.FOI
Y_train = np.array(Y_train)

# ===== Prepare Validate =====
Validate = AllData.iloc[idx_validate, :]
row_na = Validate.isnull().any(1) # check whether a row contains NA or not
idx_row_na = row_na.nonzero()[0] # find index of row containing NA
print('[Preprocessing] Total Validating containing NA: ' + str(len(idx_row_na)) + ' / ' + str(len(Validate)) + ' ----- ' + 
      str(round(len(idx_row_na) / len(Validate) * 100, 2)) + '%')
Validate_Non_NA = Validate.drop(Validate.index[idx_row_na]) # remove row containing NA
# ----- Extract Features for model -----
if (Typemodel == 'Full_Cov'):
    # Full Covariates (excluding Pop, Children, UR)
    X_validate = Validate_Non_NA.drop(['x', 'y', 'FOI'], axis = 1)
else:
    # Only Bio Covariates (excluding Pop, Children, UR)
    X_validate = Validate_Non_NA.drop(['x', 'y', 'DG_000_014bt_dens', 'Elv', 'Pigs', 'Pop_Count_WP_SEDAC_2015', 'Rice', 'UR', 'VD', 'FOI'], axis = 1)        
Y_validate = Validate_Non_NA.FOI
Y_validate = np.array(Y_validate)

# ===== Prepare EndemicDF =====
row_na = EndemicDF.isnull().any(1) # check whether a row contains NA or not
idx_row_na = row_na.nonzero()[0] # find index of row containing NA
print('[Preprocessing] Total EndemicDF containing NA: ' + str(len(idx_row_na)) + ' / ' + str(len(EndemicDF)) + ' ----- ' + 
      str(round(len(idx_row_na) / len(EndemicDF) * 100, 2)) + '%')
EndemicDF_Non_NA = EndemicDF.drop(EndemicDF.index[idx_row_na]) # remove row containing NA
# ----- Extract Features for model -----
if (Typemodel == 'Full_Cov'):
    # Full Covariates (excluding Pop, Children, UR)
    X_endemic = EndemicDF_Non_NA.drop(['x', 'y'], axis = 1)
else:
    # Only Bio Covariates (excluding Pop, Children, UR)
    X_endemic = EndemicDF_Non_NA.drop(['x', 'y', 'DG_000_014bt_dens', 'Elv', 'Pigs', 'Pop_Count_WP_SEDAC_2015', 'Rice', 'UR', 'VD'], axis = 1)        

# ----- Find max_ft for randomforest regression = numft / 3 -----
num_ft = np.floor(X_train.shape[1]/3)
if (num_ft != X_train.shape[1]/3):
    num_ft = num_ft + 1
num_ft = int(num_ft)

# ----- Training -----
print('[Training] Start training')
regr = RandomForestRegressor(random_state = 0, n_estimators = 500, max_features = num_ft, n_jobs = -1) # create model
start_time = time.time()
regr.fit(X_train, Y_train) # train model
end_time = time.time()
print('[Training] Finish training')
training_time = round(end_time - start_time, 5) # seconds
print('Training Time: ' + str(training_time) + ' seconds')

# ----- Evaluating -----
Y_Predict_Train = np.asarray(regr.predict(X_train))
Y_Predict_Validate = np.asarray(regr.predict(X_validate))
Y_Predict_Endemic = np.asarray(regr.predict(X_endemic))

result_train = MyRsq(Y_Predict_Train, Y_train)
result_validate = MyRsq(Y_Predict_Validate, Y_validate)
print('R Squared on Training: ' + str(round(result_train, 5)))
print('R Squared on Validating: ' + str(round(result_validate, 5)))

 # ----- Saving -----
if (Typemodel == 'Full_Cov'):
    filename = 'Full_Cov_TVT_' + Area  + '_' + str(resolution_grid) + '.sav'
else:
    filename = 'Only_Bio_TVT_' + Area  + '_' + str(resolution_grid) + '.sav'
        
print('[Saving] Save training model')
pickle.dump(regr, open('/home/ubuntu/data/PythonResult/TrainedModels/EMRescaleTVT_Regions_Bio/' + filename, 'wb'))

# ----- Export csv of rsq
print('[Saving] Save Rsquare evaluation')        
Result_pd = pd.DataFrame(data = {'rsq_train':[result_train], 'rsq_validate':[result_validate], 'time_train':[training_time]})   

if (Typemodel == 'Full_Cov'):
    filename_csv = 'Rsq_Full_Cov_TVT_' + Area  + '_' + str(resolution_grid) + '.csv'
else:
    filename_csv = 'Rsq_Only_Bio_TVT_' + Area  + '_' + str(resolution_grid) + '.csv'
Result_pd.to_csv(filename_csv, sep='\t', encoding='utf-8')

# ----- Export csv of EndemicDF (Coor and result)
print('[Saving] Save predicted FOI with coords')
Coor = EndemicDF_Non_NA.iloc[:, 0: 2]
Coor = Coor.assign(Predict = pd.Series(Y_Predict_Endemic).values)

if (Typemodel == 'Full_Cov'):
    filename_csv = 'Endemic_result_Full_Cov_TVT_' + Area  + '_' + str(resolution_grid) + '.csv'
else:
    filename_csv = 'Endemic_result_Only_Bio_TVT_' + Area  + '_' + str(resolution_grid) + '.csv'
Coor.to_csv(filename_csv, sep='\t', encoding='utf-8')

# ----- Create variable importance dataframe to plot later -----
print('[Saving] Save variable importance ranking')
importance = regr.feature_importances_
data = {'Name': X_endemic.columns, 'Importance': importance}
importance_df = pd.DataFrame(data)
importance_df["Std"] = np.std([tree.feature_importances_ for tree in regr.estimators_], axis=0)
importance_df = importance_df.sort_values(by = 'Importance', ascending = False)

if (Typemodel == 'Full_Cov'):
    filename_csv = 'Varimp_Full_Cov_TVT_' + Area  + '_' + str(resolution_grid) + '.csv'
else:
    filename_csv = 'Varimp_Only_Bio_TVT_' + Area  + '_' + str(resolution_grid) + '.csv'
importance_df.to_csv(filename_csv, sep='\t', encoding='utf-8')

