# sea_sidewalks
Analysis and visualization of City of Seattle sidewalk condition data
This project uses data on sidewalk surface conditions collected during a citywide asset audit during Summer 2017. 

[Link to the application](https://gngu.shinyapps.io/seattle_sidewalks/)

## Goal: 
* To allow people of various qualities ranging from worker to government official to access and understand a majority of sidewalk issues in the City of Seattle organized by severity of problems and proximity to important locations.
* To be an open source tool for further data to be extracted from and apply to. 
## Functions: 
* Allow users to locate top sidewalks organized by issue priority in neighborhoods, issue type, or a **Point of Interest**
* Points of Interest can be categorized as _Government Buildings_, _Transportation_, _Hospitals_, _Public Accommodations (commercial/business zones)_, _Employment Facilities_, _Residential Neighborhoods_ based on ADA Act Priority Scores.
* From a point of interest, a 1-2 block radius search is generated showing sidewalks with **Verified Issues**. 


## Sidewalks 
* Sidewalks are generated through a public [Sidewalk Observations](https://data.seattle.gov/dataset/SidewalkObservations/q37p-ync7) data sheet. Each sidewalk is one block long. 
* Sidewalks carry verified issues. taken from [Sidewalk Verifications](https://data.seattle.gov/dataset/SidewalkVerifications/dtqr-7xpd). Each issue is one point with x&y coordinates. Sidewalks can have multiple verified issues. 

## Future Possibilities
* Determine cost of repairing sidewalks from point of interest
* Determine ownership of sidewalks from point of interest - There are seven government districts  that can contribute to payment for a sidewalk. However, if a sidewalk is on private property, responsibility can fall upon the property owner to pay for damages. 
* Determine demographic data for sidewalks.


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


## Data sources:
* [Sidewalk observations](https://data.seattle.gov/dataset/SidewalkObservations/q37p-ync7)
* [Sidewalk verifications](https://data.seattle.gov/dataset/SidewalkVerifications/dtqr-7xpd)
* [Cultural Spaces Seattle](https://data.seattle.gov/dataset/data-seattle-gov-GIS-shapefile-datasets/f7tb-rnup/data)

* [My Neighborhood Maps Data.Seattle.Gov](https://data.seattle.gov/Community/My-Neighborhood-Map/82su-5fxf/data)
* [Bus Stops King County](https://gis-kingcounty.opendata.arcgis.com/datasets?t=transportation_OpenData)

* [Street Network](https://data.seattle.gov/dataset/Street-Network-Database/afip-2mzr)
