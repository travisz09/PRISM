# PRISM
# Travis Zalesky
# 10/30/2024
# V2.0.0

#Version History:
## V1.0.0 - Initial Commit: Derived from preliminary draft version "Z:/Documents/My Code/Sandbox - Explore New Packages and Trial Segments of Code/Prism"
## V1.0.1 - Bug Fix: Small edits to aid readability of figures.
## V1.1.0 - Feature: Add support for monthly, annual, and normals data download (in addition to daily)
## V1.1.1 - Bug Fix: Update "Shapefile" directory for vector data sets.
## V1.2.0 - Feature: Add solar radiation normals (sloped)
## V1.2.1 - Update project directories.
## V1.2.2 - Bug Fix: Expand study area extent to avoid clipping Messa.
## V1.2.3 - Scale up data collection. Improved data management.
## V2.0.0 - Major rewrite, move from project specific data collection requirements to generic tutorial format

# Abstract: PRISM data is available for a variety of common climate variables such as min/max
#   temperature, precipitation, dew point etc. which are extremely useful in a variety of 
#   research applications. These datasets can be conveniently accessed through the PRISM 
#   website, or they can be accessed programmatically through the data api using the R 
#   package prism.
#
# While the prism R package is great, this script extends the prism package in an attempt to 
#   solve a common problem. PRISM data is delivered as a raster for the contiguous US (at 4Km
#   or 800m resolution), when often only a much smaller extent is needed to answer the 
#   research question at hand. Depending on the project, storing a large number of rasters 
#   for the whole US may be unnecessary and could massively increase data storage costs. 
#   Originally developed for a research project covering the Phoenix Metro. area this script 
#   is designed to work with a shapefile defining the area of interest, and includes a 
#   variety of functions which will iteratively (1) download the requested data file from 
#   PRISM, (2) clip the data to the study area, and (3) save the output clipped raster, 
#   preserving all relevant metadata and file structure. The original (US extent) data files 
#   are then, optionally, deleted to save storage space.

# Objectives: 
## Bulk download data from Prism.oregonstate.edu
## Crop data to a given study area using a shapefile.
## Save cropped data sets, preserve file metadata and .bil format
## Delete raw data

# WARNING!
## Repeated downloading of files from the PRISM api may result in sanctions, including
##  blocking your IP address. Please be respectfull of these resources.

# Setup ----
# Packages
# Check if packages are installed, if not downlowad
# PRISM api package 'prism'
if(!require('prism')) {  # if package is not available, require() returns FALSE
  install.packages('prism')  # install the package
  library(prism)  # Attach the package
}
# Working with dates 'lubridate', required for year() function
if(!require('lubridate')) {  # if package is not available, require() returns FALSE
  install.packages('lubridate')  # install the package
  library(lubridate)  # Attach the package
}
# if package was installed previously it should have been loaded automatically

# Set Working Directory (wd)
dir.string <- getwd()  # Update with directory string as needed!
setwd(dir.string)
getwd()  # Check wd

# Create Data folder in wd
dir.create("Data")  # Ignore warning if dir already exists

# Assign prism download directory
# Use the paste() function to concatenate the full file path
# Use full directory path for more rhobust code (less error prone)
prism_set_dl_dir(paste(dir.string, "Data", sep = "/"))

# Define date range
min.Date <- "2020-01-01"
max.Date <- "2022-12-31"
# For most up to date data available, use max.Date <- lubridate::today()
# Optional: list of months to download for the get_prism_monthlies() function
months <- c(4:7)  # Numeric list, not strings!

# Define temporal resolution
# tRes must be one of "dailys", "monthlys", "annual", "normals"
tRes <- "monthlys"

# Define data variables
# Must be one (or several) of "ppt", "tmean", "tmin", "tmax", "tdmean", "vpdmin", "vpdmax"
# Use c("var1", "var2", etc...) for multiple variables
prismVars <- c("ppt", "tdmean")
# Missing variables not available through the PRISM api = 
#   "Soltotal", "Solslope", "Solclear", "Soltrans"

# Download The Data ----
# Check if temporal resolution (tRes) is set correctly.
# If tRes not in list
if (tRes != "dailys" & tRes != "monthlys" & tRes != "annual" & tRes != "normals") {
  # Print a custom error message
  stop('tRes must be one of "dailys", "monthlys", "annual", or "normals". Please ensure your variable is set correctly.')
}

# If tRes is "dailys"
# Dailys ----
if (tRes == "dailys") {
  system.time({ #Timing function.
    # For each prism climactic variable in list of prismVars
    for (prismVar in prismVars) {
      print(prismVar)  # Print the current variable
      # Use the prism::get_prism_dailys() function to connect to the PRISM api
      get_prism_dailys(type = prismVar,  # dataset to be downloaded
                       minDate = min.Date, maxDate = max.Date,  # date range
                       keepZip = F,  # delete zip folders
                       # skips download if folder already exists in download directory.
                       check = "internal") 
      
    } # end for prismVar in prismVars
  }) # end system.time
}

# If tRes is "monthlys"
# Monthlies ----
if (tRes == "monthlys") {
  system.time({ #Timing function.
    # Check if var "months" is defined
    if (exists("months")) {
      # If exists() = TRUE
      months <- months  # Use months as defined
    } else {
      months <- c(1:12) # else, default to all months of the year.
    }
    # For each prism climactic variable in list of prismVars
    for (prismVar in prismVars) {
      print(prismVar)  # Print the current variable
      # Use the prism::get_prism_monthlys() function to connect to the PRISM api
      get_prism_monthlys(type = prismVar, # dataset to be downloaded
                         # Date range
                         # Use lubridate::years() function to extract the year from the min/max date vars
                         # Generate a regular sequence from min year to max year
                         years = year(seq(as.Date(min.Date), as.Date(max.Date), by="years")),
                         mon = months,  # Months to download
                         keepZip = F) #delete zip folders
      
    } # end for prismVar in prismVars
  }) # end system.time
}

# If tRes is "annual"
# Annual ----
if (tRes == "annual") {
  system.time({ #Timing function
    # For each prism climactic variable in list of prismVars
    for (prismVar in prismVars) {
      print(prismVar)  # Print the current variable
      get_prism_annual(type = prismVar, # dataset to be downloaded
                         # Date range
                         # Use lubridate::years() function to extract the year from the min/max date vars
                         # Generate a regular sequence from min year to max year
                         years = year(seq(as.Date(min.Date), as.Date(max.Date), by="years")),
                         keepZip = F) # delete zip folders
      
    } # end for prismVar in prismVars
  }) # end system.time
}

# If tRes is "normals"
##Normals ----
if (tRes == "normals") {
  system.time({ #Timing function
    # Check if var "months" is defined
    if (exists("months")) {
      # if exists = TRUE
      months <- months  # Use months as defined
    } else {
      months <- c(1:12) # else, default to all months of the year.
    }
    # For each prism climactic variable in list of prismVars
    for (prismVar in prismVars) {
      print(prismVar)  # Print the current variable
      get_prism_normals(type = prismVar, # dataset to be downloaded
                        resolution = "800m", # also available in "4km" resolution 
                        mon = months,  # Months to download
                        annual = T,  # for 30 year annual averages.
                       keepZip = F) # delete zip folders  
    } # end for prismVar in prismVars
  }) # end system.time
}

# Optional: Check size of downloaded data
dir_size <- function(path, recursive = TRUE) {
  stopifnot(is.character(path))
  files <- list.files(path, full.names = T, recursive = recursive)
  vect_size <- sapply(files, function(x) file.size(x))
  size_files <- sum(vect_size)
  size_files  # return file size in bytes
}
rawDataSize <- dir_size("Data")/10**6  # bytes to MB
# Print statement
cat(paste("Data folder size on disk =", rawDataSize, "MB", sep = " "))

# Explore Data ----
# Packages
# "terra" package for working with geospatial datasets
if(!require('terra')) {  # if package is not available, require() returns FALSE
  install.packages('terra')  # install the package
  library(terra)  # Attach the package
}

# Locate Raster files, "bil" extension.
folder1 <- list.files("Data")[1] # Select first data folder in download directory
file1 <- list.files(paste("Data", folder1, sep = "/"), 
                    # pattern = regex, literal "bil.bil" at end of string.
                    pattern = "bil.bil$",
                    # Full file path 
                    full.names = T)
# There should only be one .bil file per data folder
# Get file name from file path
# Use length() function to return the last item in the list (i.e. index = length(list))
name <- strsplit(file1, split = "/")[[1]][length(strsplit(file1, split = "/")[[1]])]  

# Load raster data, plot
rast1 <- rast(file1)  # terra spatRaster object
plot(rast1, main = name)  # Check if data loaded correctly

# Load shapefile for clipping data extent
# Example = Maricopa county, AZ
shp_path <- list.files("Shapefile",  # Relative file path
                      # pattern = regex, ".shp" at end of string.
                      pattern = ".shp$",  
                      # Full file path
                      full.names = T)
shp <- vect(shp_path)  # terra spatVector object
plot(shp)  # Check if data loaded correctly

# Project Data
# IMPORTANT!
# Data projections control the planar (2d) shape of your map, projected from a spherical
#   (3d) space. Projections are very important for distance and area geospatial calculations
#   and will vary based on project and study area. Additionally, projections between data
#   layers must match so that they will correctly align when plotting. Terra will not 
#   perform "on the fly" projections.
# You can check your data layer projections using the terra::crs() function.
crs(rast1)  # PRISM raster(s) projection
crs(shp)  # Projection of your shapefile
# You can ignore most of the projection information here, but notice that the projections
#   do not match.
setequal(crs(rast), crs(shp))  # check if objects are equal
# For this tutorial, I will use AZ State Planes, Central projection, which is appropriate
#   for Maricopa County, AZ (EPSG:2223). Consult your PI or GIS technician for help selecting
#   the appropriate projection for your research.
projection = "EPSG:2223"
# For additional help with projections see:
#   https://epsg.io/

# Reproject data
# Reproject shp using EPSG code, overwrite shp
shp <- project(shp, projection)  # AZ State Plane, Central (ft)
# Reproject raster 1 to match with shp, overwrite rast1
rast1 <- project(rast1, crs(shp))
# Check projections
crs(shp)
crs(rast1)
# setequal(shp, rast1)  # I am not sure why this is returning F, but the projections are matching...

# Check projections and layer alignment
plot(rast1, main = name)  # USA will look skewed in "Arizona Central" projection
plot(shp, add = T)  # Shape will appear small on USA map, position should be correct
# If the position of your shapefile is incorrect, or if the shapefile does not appear on
#   the map, please double check your projection and try again.
# Depending on the background color and size of your study area your shapefile may be 
#   difficult to see at this stage.

# Define study area extent, plot
e <- ext(shp)  # extent of your shapefile
# Plot PRISM raster with limited extent
plot(rast1, ext = e, main = name)
plot(shp, add = T)
# Your shapefile should be visible as a thin outline.

#Crop raster, plot
rast_crop <- crop(rast1, 1.05 * e)  # Add 5% margin to extent to avoid clipping vertices
plot(rast_crop, main = name)
plot(shp, add = T)

#Create directory for modified outputs
dir.create("Output", recursive = T)  # Ignore warning if dir already exists
writeRaster(rast_crop, filename = "Output/Monthlies_test_case.tif",
            overwrite = T)

# Crop all Datasets ----
# Now that we have explored our data and tested our algorithm we can automate the cropping
#   of all the remaining files.
# Setup
# list directories
dirs <- list.dirs("Data", recursive = F)
dirs

# # Required inputs - can skip if already loaded
# projection = "EPSG:2223"
# shp_path <- list.files("Shapefile",  # Relative file path
#                       # pattern = regex, ".shp" at end of string.
#                       pattern = ".shp$",  
#                       # Full file path
#                       full.names = T)
# shp <- project(vect(shp_path), projection)  # terra spatVector object
# e <- 1.05 * ext(shp) # same ext as above

# Optional vars
retainRaw <- F  # Keep raw data (full USA extent)?

system.time({  # Timing function
  # Load, crop, save, looping function
  # For directory in list of directories
  for(dir in dirs) {
    i <- which(dirs == dir) # Get index number in dirs using pattern matching
    # Progress Statement
    print(paste("Processing file #", i, " of ", length(dirs), ".", sep = ""))
    
    # Explore dir
    files <- list.files(path = dir)  # Get dir contents
    # Drop extension from file, for output dir
    name <- strsplit(files[1], split = "\\.")[[1]][1]  # Split sting on literal "."
    # Create output directory
    dir.create(paste("Output/", name, sep = "/"), recursive = T)
   
    # For each file in list of files
    for (file in files) {
      # If file is .bil (raster data)
      if (grepl("bil.bil$", file) == T) {
        # Process raster data
        r <- rast(paste(dir, file, sep = "/")) # load raster data
        r_proj <- project(r, projection) # project
        r_crop <- crop(r_proj, ext(1.05 * ext(shp))) # crop

        # Write cropped raster data
        # Preserve file structure and naming conventions from PRISM
        writeRaster(r_crop, 
          filename = paste("Output/", name, "/", name, ".bil", sep = ""), 
          filetype = "EHdr",
          overwrite = T)  # Enable overwriteing
      } else {  # File metadata
        metadataFile = list.files(dir, pattern = file, full.names = T)
        # Copy metadata into output dir)
        file.copy(metadataFile,
          paste("Output/", name, sep = ""))
      }
    }  # end for file in files

    if (retainRaw == F) {
      # Delete raw data
      unlink(dir, recursive = T)
    }
  }  # end for dir in dirs
})  # end sys.time

# Optional: Check size of Output files
croppedDataSize <- dir_size("Output")/10**6
cat(paste("Output folder size on disk =", croppedDataSize , "MB", sep = " "))
storageSaved <- rawDataSize - croppedDataSize
cat(paste("Space saved on disk by cropping files =", storageSaved, "MB", sep = " "))
