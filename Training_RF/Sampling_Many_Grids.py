#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov  9 11:56:42 2018
run sample grid and save training and test grid number for series models
also can choose to plot or to run sample
--- Update 11/01/2019
    + Add testing group (before is just training and validating)
@author: duynguyen
"""

import os
import numpy as np
import pickle
import pandas as pd
from collections import Counter

#Select_Mode = 'Sampling'
Select_Mode = 'Ploting'

CurDir = os.getcwd()
resolution_grid = 400
Grid = CurDir + '/Data/Grid_400_400.csv' # Sampling Grids
Grid = pd.read_csv(Grid)  

Number_of_model = 1

if (Select_Mode == 'Sampling'): # Sampling Mode --> Create pickle file of Grid number of training and validating Grid
    
    np.random.seed(5)
    
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
    
    train_grid = np.zeros([Number_of_model, ngrid_train]) # the first len(grid_numb_train_1) is the Grid Number of constant training Grid
    validate_grid = np.zeros([Number_of_model, ngrid_validate])
    test_grid = np.zeros([Number_of_model, ngrid_test])
    
    for i in range(1, Number_of_model + 1):
        print('===== Sampling Model: ' + str(i) + ' / ' + str(Number_of_model) + ' =====')    
        grid_numb_sample_shuffle = np.copy(grid_numb_sample)
        np.random.shuffle(grid_numb_sample_shuffle)
        grid_numb_train_2 = grid_numb_sample_shuffle[:ngrid_train_2]
        grid_numb_validate = grid_numb_sample_shuffle[ngrid_train_2:(ngrid_train_2 + ngrid_validate)]
        grid_numb_test = grid_numb_sample_shuffle[(ngrid_train_2 + ngrid_validate):]
        grid_numb_train = np.append(grid_numb_train_1, grid_numb_train_2)
        del grid_numb_sample_shuffle, grid_numb_train_2
        
        train_grid[i-1, :] = grid_numb_train
        validate_grid[i-1, :] = grid_numb_validate
        test_grid[i-1, :] = grid_numb_test
    
    # Saving the objects:
    with open('Grid_Data_' + str(resolution_grid) + '_' + str(resolution_grid) + '.pkl', 'wb') as f:  # Python 3: open(..., 'wb')
        pickle.dump([train_grid, validate_grid, test_grid], f)
        
else: # Ploting Mode --> Create series of csv files
    
    with open('Grid_Data_' + str(resolution_grid) + '_' + str(resolution_grid) + '.pkl', 'rb') as f:  # Python 3: open(..., 'rb')
        train_grid, validate_grid, test_grid = pickle.load(f)
        
    Coor = Grid.iloc[:, 0: 2]
    Grid_column = np.asarray(Grid.iloc[:, 2])
    
    for i in range(1, Number_of_model + 1):
        print('===== Ploting Model: ' + str(i) + ' / ' + str(Number_of_model) + ' =====')    
        t = train_grid[i - 1, :]
        v = validate_grid[i - 1, :]
        te = test_grid[i - 1, :]
        idx_train = np.where(np.in1d(Grid_column, t))[0]
        idx_validate = np.where(np.in1d(Grid_column, v))[0]
        idx_test = np.where(np.in1d(Grid_column, te))[0]
        
        Type = np.zeros(Coor.shape[0])
        Type[idx_train] = 1
        Type[idx_validate] = 2
        Type[idx_test] = 3
        M = Coor.assign(Type = pd.Series(Type).values)
        
        # ----- Saving -----
        
        if (i < 10):
            filename = 'Grid_Index_0' + str(i) + '.csv'    
        else:
            filename = 'Grid_Index_' + str(i) + '.csv'
            
        M.to_csv(filename, sep='\t', encoding='utf-8')
