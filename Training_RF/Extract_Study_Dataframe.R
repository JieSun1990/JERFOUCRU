# --- NOTE ---
# Extract Study Catchment Area dataframe from (imputed) Endemic dataframe
# ---------- #

cat('===== START [Extract_Study_Dataframe.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

# Read imputed Endemic dataframe
Endemic <- readRDS('Generate/Imputed_DF/Imputed_Features_Endemic.Rds')

# Find Study pixel index
idx_study <- which(!is.na(Endemic$FOI))

# Extract Study Dataframe
Study <- Endemic[idx_study, ]

# Save
saveRDS(Study, paste0('Generate/Imputed_DF/', 'Imputed_Features_Study.Rds'))

cat('===== FINISH [Extract_Study_Dataframe.R] =====\n')