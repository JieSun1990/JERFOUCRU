# NOTE #
# plot variable important from csv (result after running Train_Model_RandomForest.py script)
# This script now readed the example of csv file --> Need to change to the exact file
# ---- #

library(ggplot2)
library(tidyr)
library(dplyr)

cat('===== START [Plot_Feature_Importance.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Python_Export/Figures/'), showWarnings = TRUE)
Savepath <- 'Generate/Python_Export/Figures/'

# read the Varimp csv files (Change the directory to the exact file)
varimp <- read.csv('Generate/Python_Export/Example_Varimp.csv', sep = '\t')

## If you want to show full name of covariates, uncomments belows
# varimp <- varimp[order(varimp$X), ]
## The following names is based on the order: Bio_01 --> Bio_19, DG_000_014bt_dens, Elv, Pigs, Rice, UR, VD, Pop_Count
# covname.full <- c('Annual Mean Temp', 'Mean Diurnal Range', 'Isothermality', 'Temp Seasonality',
#                   'Max Temp Warmest Month', 'Min Temp Coldest Month', 'Temp Annual Range', 'Mean Temp Wettest Quarter',
#                   'Mean Temp Driest Quarter', 'Mean Temp Warmest Quarter', 'Mean Temp Coldest Quarter', 'Annual Precip',
#                   'Precip Wettest Month', 'Precip Driest Month', 'Precip Seasonality', 'Precip Wettest Quarter',
#                   'Precip Driest Quarter', 'Precip Warmest Quarter', 'Precip Coldest Quarter', 'Children Density',
#                   'Elevation', 'Pigs Density', 'Rice Field Area', 'Urban/Rural', 'Vector Distribution', 'Population Count')
# varimp$Name <- covname.full
# varimp <- varimp[order(varimp$Importance, decreasing = TRUE), ]

## ===== Rearrange values =====
varimp$X <- NULL
varimp <- varimp %>% arrange(Importance) %>% mutate(Name = factor(Name, levels = .$Name))

## ===== Plot feature importance and its std values =====
p1 <- ggplot(data = varimp, aes(x = Name, y = Importance)) + geom_bar(stat = 'identity') + coord_flip()
p1 <- p1 + geom_errorbar(aes(ymin = Importance - Std, ymax = Importance + Std)) # show std (small std --> not good ft)

png(paste0(Savepath, 'Feature_Importance_Std.png'), width = 850, height = 824)
p1
dev.off()

## ===== Plot feature importance with their summary stat like mean and IQR =====
varimp.df <- data.frame(covname = varimp$Name, imp = varimp$Importance)

varimp.df <- varimp.df %>%
    arrange(imp) %>%
    mutate(covname = factor(covname, levels = .$covname))

S <- summary(varimp.df$imp)

p2 <- ggplot(data = varimp.df) + geom_hline(aes(yintercept = 0)) + geom_point(aes(x = covname, y = imp), size = 1.5) +
    geom_segment(aes(x = covname, y = 0, xend = covname, yend = imp)) + coord_flip() +
    labs(x = "Covariate Names", y = 'Importance Value') +
    theme(plot.title = element_text(hjust = 0.5), 
          legend.position = c(0.9, 0.5))

p2 <- p2 + geom_hline(aes(yintercept = as.numeric(S[4]), linetype = 'Mean'), color = 'red', size = 0.85) +
    geom_hline(aes(yintercept = as.numeric(S[2]), linetype = 'IQR'), color = 'blue', size = 0.85) +
    geom_hline(aes(yintercept = as.numeric(S[5]), linetype = 'IQR'), color = 'blue', size = 0.85) +
    scale_linetype_manual(name = 'Threshold', values = c(2,2),
                          guide = guide_legend(override.aes = list(color = c("blue", 'red'),
                                                                   size = 1.2)))

png(paste0(Savepath, 'Feature_Importance_IQR.png'), width = 850, height = 824)
p2
dev.off()


## ===== The following option is for exporting in large page (poster) =====
# p2 <- ggplot(data = varimp.df) + geom_hline(aes(yintercept = 0), size = 1.15) + geom_point(aes(x = covname, y = imp), size = 2) +
#     geom_segment(aes(x = covname, y = 0, xend = covname, yend = imp), size = 1.2) + coord_flip() +
#     labs(x = "Covariate Names", y = 'Importance Value') +
# theme(plot.title = element_text(hjust = 0.5), legend.position = c(0.9, 0.5),
#       axis.title = element_text(size = 45), axis.text = element_text(size = 43),
#       legend.text = element_text(size = 40), legend.title = element_text(size = 38))

# p2 <- p2 + geom_hline(aes(yintercept = as.numeric(S[4]), linetype = 'Mean'), color = 'red', size = 1.35) +
#     geom_hline(aes(yintercept = as.numeric(S[2]), linetype = 'IQR'), color = 'blue', size = 1.35) +
#     geom_hline(aes(yintercept = as.numeric(S[5]), linetype = 'IQR'), color = 'blue', size = 1.35) +
#     scale_linetype_manual(name = 'Threshold', values = c(2,2),
#                           guide = guide_legend(override.aes = list(color = c("blue", 'red'),
#                                                                    size = 3)))

cat('===== FINISH [Plot_Feature_Importance.R] =====\n')
