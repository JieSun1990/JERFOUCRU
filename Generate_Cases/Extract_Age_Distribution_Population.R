### NOTE ###
# Convert format from Quan (30 regions) into countries (25 countries)
# The result will be age-distributed population in the year 2015 at each countries (total 25 countries)
### ---- ###

cat('===== START [Extract_Age_Distribution_Population.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!!
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)


##### Read pop from Quan Data (also from UN, but adjust to match subnational regions) ####
# pop_data1 <- readRDS("JE_model_Quan/data/population/Naive_pop_24ende_1950_2015.rds")
pop_data1 <- readRDS("Data/Naive_pop_24ende_1950_2015.rds") # Read Population data collected by Quan
pop_data1 <- pop_data1[ ,c(1, which(colnames(pop_data1) == 'X2015'))] # Take the year 2015
pop_data1$region <- as.character(pop_data1$region)
# foi_data1 <- readRDS("JE_model_Quan/results/areas_lambda/ende_24_regions_lambda_extr_or.rds")
foi_data1 <- readRDS("Data/ende_24_regions_lambda_extr_or.rds") # Read catalytic modelled FOI
select_region <- c(1:6, 11:15, 19:24, 28:30, 32:40, 48) # selected regions <-- Quan decision
select_region <- as.character(foi_data1$region[select_region])
pop_data1 <- pop_data1[which(pop_data1$region %in% select_region),]

select_country_name <- select_region # select_country is the country where region belongs to
select_country_name[29] <- 'TWN'
select_country_name[5:6] <- 'CHN'
select_country_name[7:8] <- 'IDN'
select_country_name[9:11] <- 'IND'
select_country_name[19:20] <- 'NPL'

countries_unique <- unique(select_country_name)

pop_convert <- data.frame(country_code = rep(countries_unique, each = 100),
                          age_from = 0:99, age_to = 0:99, X2015 = 0)

for (country in countries_unique){
    idx_in_select_country_name <- which(select_country_name == country)
    region_in_select_region <- select_region[idx_in_select_country_name]
    pop_temp <- rep(0, 100) # 100 elements for 100 years: 0 to 99
    for (region in region_in_select_region){
        idx_in_pop <- which(pop_data1$region == region)
        pop_temp <- pop_temp + pop_data1$X2015[idx_in_pop]
    }
    idx_in_pop_convert <- which(pop_convert$country_code == country)
    pop_convert$X2015[idx_in_pop_convert] <- pop_temp
}

saveRDS(pop_convert, 'Generate/Naive_pop_24ende_2015_Country.Rds')

cat('===== FINISH [Extract_Age_Distribution_Population.R] =====\n')