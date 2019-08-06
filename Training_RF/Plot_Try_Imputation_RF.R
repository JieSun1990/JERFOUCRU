# --- NOTE ---
# This script is used to plot and compare Rsquared produced by Try_Imputatuon_RF functions
# Part 1 of this script is to plot 1 scenarios
# Part 2 of this script is to plot the comparison between 2 scenarios of missing (20% and 50% pseudo missing) (or whatever you want)
# ---------- #

library(ggplot2)
library(tidyr)
library(dplyr)

cat('===== START [Plot_Try_Imputation_RF.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Imputed_Figures/'), showWarnings = TRUE)
Savepath <- 'Generate/Imputed_Figures/'

## ================= PART 1: PLOT 1 SCENARIO =================

## ===== Read Rsq =====
Folder <- 'Generate/Imputed_DF/'
data <- readRDS(paste0(Folder, 'Rsq_Imputation_20.Rds'))

## ===== Plot Rsq =====
df.rsq.imputed.order <- data[ , c(1, 2)] %>%
    arrange(rsq) %>%
    mutate(name = factor(name, levels = .$name))

S <- summary(df.rsq.imputed.order$rsq)

p <- ggplot(data = df.rsq.imputed.order) + geom_hline(aes(yintercept = 0)) + geom_point(aes(x = name, y = rsq)) +
    geom_segment(aes(x = name, y = 0, xend = name, yend = rsq)) + coord_flip() +
    labs(x = "Covariate names", y = 'RSQ', title = 'RSQ in Imputed Observations') +
    theme(plot.title = element_text(hjust = 0.5), legend.position = c(0.85, 0.1))

p <- p + geom_hline(aes(yintercept = as.numeric(S[4]), linetype = 'Mean'), color = 'red', size = 0.85) +
    geom_hline(aes(yintercept = as.numeric(S[2]), linetype = 'IQR'), color = 'blue', size = 0.85) +
    geom_hline(aes(yintercept = as.numeric(S[5]), linetype = 'IQR'), color = 'blue', size = 0.85) +
    scale_linetype_manual(name = 'Summary', values = c(2,2),
                          guide = guide_legend(override.aes = list(color = c("blue", 'red'),
                                                                   size = 1.2)))
p

png(paste0(Savepath, 'Rsq_Imputation.png'), width = 850, height = 824)
p
dev.off()



## ================= PART 2: PLOT COMPARISON 2 SCENARIOS =================

## ===== Read Rsq =====
Folder <- 'Generate/Imputed_DF/'
data1 <- readRDS(paste0(Folder, 'Rsq_Imputation_20.Rds'))
data2 <- readRDS(paste0(Folder, 'Rsq_Imputation_50.Rds'))

## ===== Plot comparison =====
d <- data1[, c(1, 2)] # take the 1st (name of feature) and 2nd (Rsq of imputed values) columns
colnames(d) <- c('name', 'miss_20')
d$miss_50 <- data2$rsq

d = d %>% rowwise() %>% mutate( mymean = mean(c(miss_20, miss_50) )) %>% arrange(mymean) %>% mutate(name=factor(name, name))
p <- ggplot(d) +
    geom_segment(aes(x=name, xend=name, y=miss_20, yend=miss_50), color="grey50") +
    geom_point(aes(x=name, y=miss_20,colour = '20%'), alpha = 0.7, size=3) + # green
    geom_point(aes(x=name, y=miss_50,colour = '50%'), alpha = 0.7, size=3) + # red
    coord_flip()
p <- p + labs(x = "Covariates", y = 'R Squared',
              title = 'R-squared of Imputed Observations in 2 scenarios of missing', colour = "Missing Proportion") +
    theme(plot.title = element_text(hjust = 0.5),
          legend.position = c(0.9, 0.1))
p

png(paste0(Savepath, 'Comparison_Rsq_Imputation.png'), width = 850, height = 824)
p
dev.off()
cat('===== FINISH [Plot_Try_Imputation_RF.R] =====\n')