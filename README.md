# sea_sidewalks
Analysis and visualization of City of Seattle sidewalk condition data
This project uses data on sidewalk surface conditions collected during a citywide asset audit during Summer 2017. 

## Functions: 
* Allow users to locate sidewalks with verified issues from a **Point of Interest**.
* Points of Interest can be categorized (from highest priority to lowest) as _Government Buildings_, _Transportation_, _Hospitals_, _Public Accommodations (commercial/business zones)_, _Employment Facilities_, _Residential Neighborhoods_ based on ADA Act Priority Scores.
* From a point of interest, a 1-2 block radius search is generated showing sidewalks with **Verified Issues**. 
* Users are able to access a **Report Card** 

## Sidewalks 
* Sidewalks are generated through a public [Sidewalk Observations](https://data.seattle.gov/dataset/SidewalkObservations/q37p-ync7) data sheet. Each sidewalk is one block long. 
* Sidewalks carry verified issues. taken from [Sidewalk Verifications](https://data.seattle.gov/dataset/SidewalkVerifications/dtqr-7xpd). Each issue is one point with x&y coordinates. Sidewalks can have multiple verified issues. 
* Using this data, sidewalk repair priority can be categorized by _Low_, _Medium_, and _High_ priority repairs. This allows the user to determine which point of interest has the most sidewalks with pressing issues. 

## Future Features
* Determine cost of repairing sidewalks from point of interest
* Determine ownership of sidewalks from point of interest - There are seven government districts  that can contribute to payment for a sidewalk. However, if a sidewalk is on private property, responsibility can fall upon the property owner to pay for damages. 
* Determine demographic data for sidewalks

## Technology 
* [RShiny](https://shiny.rstudio.com/): What the web application is primarily built on. Making R the primary application language.  
* .gis and .shp file datasets 


## Contributors 
 * [Mitchell Hendee](https://github.com/kunomaclis) 
 * [Richard McGovern](https://github.com/richardwmcgovern)
 * [Grant Nguyen](https://github.com/gnguy)
 * [Kathryn Schelonka]()
 * [Mike G]()
 * [Steve Lewish](https://github.com/lordjoe)

##Data sources:
* [Sidewalk observations](https://data.seattle.gov/dataset/SidewalkObservations/q37p-ync7)
* [Sidewalk verifications](https://data.seattle.gov/dataset/SidewalkVerifications/dtqr-7xpd)
* [Cultural Spaces Seattle](https://data.seattle.gov/dataset/data-seattle-gov-GIS-shapefile-datasets/f7tb-rnup/data)

* [My Neighborhood Maps Data.Seattle.Gov](https://data.seattle.gov/Community/My-Neighborhood-Map/82su-5fxf/data)
* [Bus Stops King County](https://gis-kingcounty.opendata.arcgis.com/datasets?t=transportation_OpenData)

* [Street Network](https://data.seattle.gov/dataset/Street-Network-Database/afip-2mzr)