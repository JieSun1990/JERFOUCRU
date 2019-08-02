# --- NOTE ---
# This script is used to give the information about regions index (after running Assign_Regions_For_Adjust_Overlay.R)
# This script is created by doing analysis and observing on QGIS
# The information is about how the regions connected with other overlay regions
# We can also use this information to extract interested countries (or regions) dataframe
#
#
# If we change anything in the Data/Shapefile_FOI folder (add or remove studies) --> this file might be not correct anymore!
# ---------- #

cat('===== START [Regions_Index_Information.R] =====\n')

# ---------- China ----------
# QGIS Extract Code:
# "Region" = 'China' OR 
# "Region" = 'guigang' OR 
# "Region" = 'guizhou' OR 
# "Region" = 'jinan' OR
# "Region" = 'longnan' OR
# "Region" = 'shijiazhuang' OR
# "Region" = 'yichang' OR
# "Region" = 'baoji' OR
# "Region" = '28.dist.ende' OR 
# "Region" = '3counties.Tibet'
# Overlay Note:
# 2 --> 1, 12 (2 is overlayed by 1 and 12 - 2 is belowed, then 1 and 12 are aboved)
# 1 --> 4, 7, 9, 10, 11, 16, 34

China.region <- c(1, 2, 4, 7, 9, 10, 11, 12, 16, 34)

# ---------- Taiwan (entirely overlayed) ----------
# QGIS Extract Code:
# "Region" = 'Taiwan' OR 
# "Region" = 'Taipei' OR 
# "Region" = 'Kaoping' OR 
# "Region" = 'Northern' OR 
# "Region" = 'Southern' OR 
# "Region" = 'Eastern' OR 
# "Region" = 'Central'
# Overlay Note: 
# All sub regions of Taiwan do not overlay each other (If all sub regions are aggregated, they becomes 'Taiwan')

Taiwan.region <- c(29, 31, 32, 33, 35, 36)

# ---------- Cambodia ----------
# QGIS Extract Code:
# "Region" = 'Cambodia'
# Overlay Note: 
# All sub regions do not overlay each other

Cambodia.region <- c(43)

# ---------- Vietnam ----------
# QGIS Extract Code:
# "Region" = 'north' OR 
# "Region" = 'middle.south'
# Overlay Note: 
# All sub regions do not overlay each other

Vietnam.region <- c(37, 40)

# ---------- Japan ----------
# QGIS Extract Code:
# "Region" =  'Japan'
# Overlay Note: 
# All sub regions do not overlay each other

Japan.region <- c(3)

# ---------- SKorea ----------
# QGIS Extract Code:
# "Region" = 'seoul' OR 
# "Region" = 'South.Korea'
# Overlay Note: 
# 5 --> 6 (5 is belowed, 6 is aboved)

SKorea.region <- c(5, 6)

# ---------- Laos ----------
# QGIS Extract Code:
# "Region" = 'vientiane'
# Overlay Note: 
# All sub regions do not overlay each other

Laos.region <- c(39)

# ---------- Philippines ----------
# QGIS Extract Code:
# "Region" = 'Philippines'
# Overlay Note: 
# All sub regions do not overlay each other

Philippines.region <- c(38)

# ---------- Malaysia ----------
# QGIS Extract Code:
# "Region" = 'Malaysia'
# Overlay Note: 
# All sub regions do not overlay each other

Malaysia.region <- c(49)

# ---------- Thailand ----------
# QGIS Extract Code:
# "Region" = 'THA2cities'
# Overlay Note: 
# All sub regions do not overlay each other

Thailand.region <- c(44)

# ---------- India ----------
# QGIS Extract Code:
# "Region" = 'India' OR
# "Region" = 'assam' OR
# "Region" = 'dhemaji' OR
# "Region" = '7up.dist.assam' OR
# "Region" = 'pondicherry' OR
# "Region" = 'N.westbegal' OR
# "Region" = 'bellary.neighbor' OR
# "Region" = 'bellary' OR
# "Region" = 'tamilnadu' OR
# "Region" = 'cuddalore' OR
# "Region" = 'uttar' OR
# "Region" = 'N.uttar' OR
# "Region" = 'gorakhpur.div' OR
# "Region" = 'gorakhpur.dist' OR
# "Region" = 'kushinagar'
# Overlay Note: 
# 8: India
# 13: uttar
# 15: 7up.dist.assam
# 19: N.uttar
# 21: assam
# 23: dhemaji
# 25: gorakhpur.div
# 26: kushinagar
# 27: N.westbegal
# 28: gorakhpur.dist
# 41: bellary.neighbor
# 42: bellary
# 45: tamilnadu
# 46: pondicherry
# 47: cuddalor

# 8 --> 46, 27, 41, 45, 13, 25, 15, 21
# 41 --> 42
# 45 --> 47
# 13 --> 19, 25
# 19 --> 28
# 25 --> 26, 28
# 15 --> 21
# 21 --> 23

India.region <- c(8, 13, 15, 19, 21, 23, 25, 26, 27, 28, 41, 42, 45, 46, 47)

# ---------- Nepal (entirely overlayed) ----------
# QGIS Extract Code:
# "Region" = 'Nepal' OR
# "Region" = 'non.kathmandu' OR
# "Region" = 'kathmandu' OR
# "Region" = 'Chitwan' OR
# "Region" = 'Kosi.zone' OR
# "Region" = 'W.Terai' OR
# "Region" = 'non.W.Terai'
# Overlay Note: 
# 14: non.kathmandu
# 17: non.W.Terai
# 18: W.Terai
# 20: Kosi.zone
# 22: Chitwan
# 24: kathmandu

# Nepal --> 24, 14, 17, 18
# 14 --> 20
# 17 --> 20, 22

Nepal.region <- c(14, 17, 18, 20, 22, 24)

# ---------- Bangladesh ----------
# QGIS Extract Code:
# "Region" = 'BGD4.divs'
# Overlay Note: 
# none

Bangladesh.region <- c(30)

# ---------- SriLanka ----------
# QGIS Extract Code:
# "Region" = 'SriLanka'
# Overlay Note: 
# none

SriLanka.region <- c(48)

# ---------- Indonesia ----------
# QGIS Extract Code:
# "Region" = '6provinces'
# "Region" = 'bali'
# Overlay Note: 
# none

Indonesia.region <- c(50, 51)

# ---------- Example of Extract Countries of Interest as dataframe ------------
## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
# script.dir <- dirname(sys.frame(1)$ofile)
# script.dir <- paste0(script.dir, '/')
# setwd(script.dir)

# DataPath <- 'Generate/Overlay_DF/Coordinates_Index_Study.Rds'
# df.allregions <- readRDS(DataPath)
# name <- 'Indonesia'
# interest.region <- Indonesia.region
# 
# idx.region <- which(df.allregions$Region %in% interest.region)
# df.region <- df.allregions[idx.region,]
# 
# saveRDS(df.region, paste0(name, '_DF.Rds')) # Use this dataframe to create a TIF file

cat('===== FINISH [Regions_Index_Information.R] =====\n')