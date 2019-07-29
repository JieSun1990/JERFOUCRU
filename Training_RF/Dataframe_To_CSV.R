# --- NOTE ---
# This script is a supported script (not really important and not complicated)
# This script is used to convert Rds (dataframe) to csv files (Because Python can read csv, cannot read Rds file)
# ---------- #

Path_Rds <- 'Directory/to/your/Rds/files.Rds'
data <- readRDS(Path_Rds)

Path_csv <- 'Directory/to/save/csv/files.csv'
write.csv(data, Path_csv, row.names = FALSE)