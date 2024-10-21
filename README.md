# PRISM
## Bulk download PRISM data from OSU api.
### Travis Zalesky

### Download bulk data from Oregon State University (OSU) Climate Group Parameter-elevation Regressions on Independent Slopes Model (PRISM).

PRISM data is available for a variety of common climate variables such as min/max temperature, precipitation, dew point etc. which are extremely useful in a variety of research applications. These datasets can be conveniently accessed through the [PRISM website](https://prism.oregonstate.edu/recent/), or they can be accessed programmatically through the data api using the R package [prism](https://cran.r-project.org/web/packages/prism/prism.pdf).

While the prism R package is great, this script extends the prism package in an attempt to solve a common problem. PRISM data is delivered as a raster for the contiguous US (at 4Km or 800m resolution), when often only a much smaller extent is needed to answer the research question at hand. Depending on the project, storing a large number of rasters for the whole US may be unnecessary and could massively increase data storage costs. Originally developed for a research project covering the Phoenix Metro. area this script is designed to work with a shapefile defining the area of interest, and includes a variety of functions which will iteratively (1) download the requested data file from PRISM, (2) clip the data to the study area, and (3) save the output clipped raster, preserving all relevant metadata and file structure. The original (US extent) data files are then, optionally, deleted to save storage space.

This repository requires a Shapefile (not provided), and is not intended to be run top to bottom. Rather there are a few variables near the top that are to be updated based on the PRISM vars required by the users, the shapefile is loaded into the R environment, then the user should identify the correct code block to run based on the temporal resolution needed for their research.

Thanks to the people at OSU Climate Group, as well as Edmund M. Hart and Kendon Bell, authors of the prism R package.

Feel free to use or modify these scripts as you see fit. I would appreciate it if you acknowledged the source for any substantial portion of this code used in your project. Thank you.
