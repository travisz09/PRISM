###Travis Zalesky
#4/19/2024
#V1.2.3

#Version History:
## V1.0.0 - Initial Commit: Derived from preliminary draft version "Z:/Documents/My Code/Sandbox - Explore New Packages and Trial Segments of Code/Prism"
## V1.0.1 - Bug Fix: Small edits to aid readability of figures.
## V1.1.0 - Feature: Add support for monthly, annual, and normals data download (in addition to daily)
## V1.1.1 - Bug Fix: Update "Shapefile" directory for vector data sets.
## V1.2.0 - Feature: Add solar radiation normals (sloped)
## V1.2.1 - Update project directories.
## V1.2.2 - Bug Fix: Expand study area extent to avoid clipping Messa.
## V1.2.3 - Scale up data collection. Improved data management.

#Objectives: 
### Bulk download data from Prism.oregonstate.edu
### Crop data to Phoenix Metropolitan area.
### Save cropped data sets, preserve file metadata and .bil format


#Setup ----
#Packages
#install.packages("prism") #Run only if necessary, note out after installation.
library(prism) #Attach package

#Set Working Directory (wd)
dir.string <- "C:/GIS_Projects/UA_SRP/R/Prism"
setwd(dir.string)

#Create Data folder in wd
dir.create("Data/Monthlies")

#Assign prism download directory
prism_set_dl_dir(paste(dir.string, "Data/Monthlies", sep = "/"))

#Define date range
min.Date <- "2003-01-01"
max.Date <- lubridate::today()

#Define temporal resolution
#tRes must be one of "dailys", "monthlys", "annual", "normals"
tRes <- "monthlys"

#Define data variables
prismVars <- c("ppt", "tmean", "tmin", "tmax", "tdmean", "vpdmin", "vpdmax")
#Missing variables = "Soltotal", "Solslope", "Solclear", "Soltrans"

#Download Data ----
if (tRes != "dailys" & tRes != "monthlys" & tRes != "annual" & tRes != "normals") {
  cat('tRes must be one of "dailys", "monthlys", "annual", or "normals".')
}
##Dailys ----
if (tRes == "dailys") {
  system.time({ #Timing function. ~45 minutes.
    for (prismVar in prismVars) {
      print(prismVar)
      get_prism_dailys(type = prismVar, #dataset to be downloaded
                       minDate = min.Date, maxDate = max.Date, #date range
                       keepZip = F, #delete zip folders
                       check = "internal") #skips download if folder already exists in download directory.
      
    } #end for prismVar in prismVars
  }) #end system.time
}

##Monthlies ----
if (tRes == "monthlys") {
  library(lubridate) # Required for year() function.
  system.time({ #Timing function. ~45 minutes.
    for (prismVar in prismVars) {
      print(prismVar)
      get_prism_monthlys(type = prismVar, #dataset to be downloaded
                         years = year(seq(as.Date(min.Date), as.Date(max.Date), by="years")), #date range
                         mon = 1:12, #defaults to all monts in range of years.
                         keepZip = F) #delete zip folders
      
    } #end for prismVar in prismVars
  }) #end system.time
}

##Annual ----
if (tRes == "annual") {
  library(lubridate) # Required for year() function.
  system.time({ #Timing function. ~45 minutes.
    for (prismVar in prismVars) {
      print(prismVar)
      get_prism_annual(type = prismVar, #dataset to be downloaded
                         years = year(seq(as.Date(min.Date), as.Date(max.Date), by="years")), #date range
                         keepZip = F) #delete zip folders
      
    } #end for prismVar in prismVars
  }) #end system.time
}

##Normals ----
if (tRes == "normals") {
  library(lubridate) # Required for year() function.
  system.time({ #Timing function. ~45 minutes.
    for (prismVar in prismVars) {
      print(prismVar)
      get_prism_normals(type = prismVar, #dataset to be downloaded
                        resolution = "800m", #use "800m" for higher resolution
                        mon = 1:12,  # All months
                        annual = T,  # for 30 year annual averages.
                       keepZip = F) #delete zip folders
      
    } #end for prismVar in prismVars
  }) #end system.time
}
#Explore Data ----
#Packages
#install.packages("terra") #Run only if necessary, note out after installation.
library(terra) #Attach package

#Locate Raster files, "bil" extension.
folder1 <- list.files("Data/Monthlies")[1] #Select first data folder in download directory
file1 <- list.files(paste("Data/Monthlies", folder1, sep = "/"), 
                    pattern = "bil.bil$", full.names = T) #pattern = regex, literal "bil.bil" at end of string.
name <- strsplit(file1, split = "/")[[1]][3]

#Load raster data, plot
rast1 <- rast(file1)
plot(rast1, main = name)

#Load shapefile of Maricopa County for data extent
Maricopa <- vect("../../Shapefiles/Maricopa_County.shp")
plot(Maricopa)

#Load shapefile of Pheonix Metro Area
Phoenix <- vect("../../Shapefiles/Municipalities.shp")
plot(Phoenix)

#Merge projections, standardize to Maricopa = "NAD83, Arizona Central (ft)"
# Maricopa County shapefile projection got changed at some point.
# Reverting projection back to AZC, epsg = 2223
Maricopa <- project(Maricopa, "EPSG:2223")
rast1 <- project(rast1, Maricopa)
Phoenix <- project(Phoenix, Maricopa)

#Check projections and layer alignment
plot(rast1, main = name) #will look skewed in "Arizona Central" projection
plot(Maricopa, add = T) #Small
plot(Phoenix, add = T) #Very small

#Define Extent, plot
e <- ext(Maricopa)
plot(rast1, ext = e, main = name)
plot(Maricopa, add = T)
plot(Phoenix, add = T)

#Crop raster, plot
rast_crop <- crop(rast1, Maricopa)
plot(rast_crop, main = name)
plot(Maricopa, add = T)
plot(Phoenix, add = T)
plot(ext(Phoenix), add = T)

#Smaller, Municipality only
ext(Phoenix)
#extend cropping ext to fully contain all of Phoenix study area (avoid clipping Messa).
e <- ext(520000, 812805.5, 789401.5, 1075991.83334609)
rast_small <- crop(rast1, e)
plot(rast_small, main = name)
plot(Phoenix, add = T)
plot(ext(Phoenix), add = T)

#Create directory for modified outputs
dir.create("Output/Cropped_Rasters/Phoenix/temp", recursive = T)
writeRaster(rast_small, filename = "Output/Cropped_Rasters/Phoenix/temp/Monthlies_test_case.tif",
            overwrite = T)

#Crop all Datasets ----
#Setup
#list directories
dirs <- list.dirs("Data/Monthlies", recursive = F)

#Required inputs - skip if already loaded
Maricopa <- vect("../../Shapefiles/Maricopa/Maricopa.shp")
Phoenix <- project(vect("../../Shapefiles/Phoenix Metro/Municipalities.shp"), Maricopa)
e <- ext(520000, 812805.5, 789401.5, 1075991.83334609) #same ext as above
##Plotting will increase processing times.
plotData <- T 


system.time({ #Timing function, ~24 min (0.56 seconds per file).
  #Load, crop, save, looping function
  for(dir in dirs) {
    i <- which(dirs == dir) #get index number in dirs using pattern matching
    # Progress Statement
    print(paste("Processing file #", i, " of ", length(dirs), ".", sep = ""))
    
    #Explore dir
    files <- list.files(path = dir) #get dir contents
    file <- files[grep("bil.bil$", files)] #get raster filepath
    name <- strsplit(file, split = "\\.")[[1]][1] #drop extension from file, for output dir
    label_vars <- strsplit(name, split = "_")[[1]][c(2:5)]
    label_vars[4] <- gsub('^(.{4})(.*)$', '\\1-\\2', label_vars[4])  # Convert month num to month abbr
    
    #Process raster data
    r <- rast(paste(dir, file, sep = "/")) #load raster data
    r_proj <- project(r, Maricopa) #project
    r_crop <- crop(r_proj, e) #crop
    if (plotData == T) {
      plot(r_crop, main = paste(label_vars, collapse = " ")) 
      plot(Phoenix, add = T)
      plot(ext(Phoenix), add = T)
    }
    
    #Create output dir, write cropped raster data
    dir.create(paste("Output/Cropped_Rasters/Phoenix/Normals", name, "metadata", sep = "/"), recursive = T) #create output sub-directories
    writeRaster(r_crop, filename = paste("Output/Cropped_Rasters/Phoenix/Normals/", name, "/",
                                         name, ".bil", sep = ""), filetype = "EHdr",
                overwrite = T)
    
    #Get metadat files, copy to output dir
    txt <- paste(dir, files[grep("info.txt$", files)], sep = "/") #get textfile filepath
    csv <- paste(dir, files[grep(".csv$", files)], sep = "/") #get csv filepath
    xml <- paste(dir, files[grep("bil.xml$", files)], sep = "/") #get csv filepath
    meta <- c(txt, csv, xml) #list of metadata files to copy
    file.copy(meta, paste("Output/Cropped_Rasters/Phoenix/Normals/", name, "/", "metadata", 
                          sep = "")) #Copy metadata into output dir
  } #end for dir in dirs
})#end sys.time

# Solar radiation normals (sloped) -----
## NOTE: Solar radiation data from PRISM only includes monthly (or annual) normals (30-year ave.)
###       Solar radiation data downloads not supported by "prism" package.
###       Solar radiation normals manually downloaded for each month from https://prism.oregonstate.edu/normals/.
###       Downloaded data corrected for regional slope and aspect. Alternate "horizontal surface" data also available if required.

sol_Path <- "Normals_SolarRad/Data"
sol_Zips <- list.files(sol_Path)

#Unzip all folders
for (sol_Zip in sol_Zips) {
  dir <- strsplit(sol_Zip, "\\.")[[1]][1]
  unzip(paste(sol_Path, sol_Zip, sep = "/"), 
        exdir = paste(sol_Path, dir, sep = "/"))
  file.remove(paste(sol_Path, sol_Zip, sep = "/")) #remove zip folders
}

sol_Dirs <- list.files(sol_Path)

#Required inputs - skip if already loaded
Maricopa <- vect("../../Shapefiles/Maricopa/Maricopa.shp")
Phoenix <- project(vect("../../Shapefiles/Phoenix Metro/Municipalities.shp"), Maricopa)

system.time({ #Timing function, 
  #Load, crop, save, looping function
  for(sol_Dir in sol_Dirs) {
    i <- which(sol_Dirs == sol_Dir) #get index number in dirs using pattern matching
    # Progress Statement
    print(paste("Processing file #", i, " of ", length(sol_Dirs), ".", sep = ""))
    
    #Explore dir
    files <- list.files(path = paste(sol_Path, sol_Dir, sep = "/")) #get dir contents
    file <- files[grep("bil.bil$", files)] #get raster filepath
    name <- strsplit(file, split = "\\.")[[1]][1] #drop extension from file, for output dir
    
    #Process raster data
    r <- rast(paste(sol_Path, sol_Dir, file, sep = "/")) #load raster data
    r_proj <- project(r, Maricopa) #project
    r_crop <- crop(r_proj, Phoenix) #crop
    plot(r_crop) #optional
    
    #Create output dir, write cropped raster data
    dir.create(paste("Output/Cropped_Rasters/Phoenix", name, "metadata", sep = "/"), recursive = T) #create output sub-directories
    writeRaster(r_crop, filename = paste("Output/Cropped_Rasters/Phoenix/", name, "/",
                                         name, ".bil", sep = ""), filetype = "EHdr")
    
    #Get metadat files, copy to output dir
    txt <- paste(sol_Path, sol_Dir, files[grep("info.txt$", files)], sep = "/") #get textfile filepath
    #csv <- paste(sol_Dir, files[grep(".csv$", files)], sep = "/") #get csv filepath
    xml <- paste(sol_Path, sol_Dir, files[grep("bil.xml$", files)], sep = "/") #get csv filepath
    meta <- c(txt, xml) #list of metadata files to copy
    file.copy(meta, paste("Output/Cropped_Rasters/Phoenix/", name, "/", "metadata", 
                          sep = "")) #Copy metadata into output dir
  } #end for dir in dirs
})#end sys.time
    