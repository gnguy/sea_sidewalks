# sea_sidewalks
Analysis and visualization of City of Seattle sidewalk condition data

This project uses data on sidewalk surface conditions collected during a citywide asset audit during Summer 2017. 

## Functions: 
* Allow users to locate sidewalks with observable issues from a **Point of Interest**.
* Points of Interest can be categorized (from highest priority to lowest) as _Government Buildings_, _Transportation_, _Hospitals_, _Public Accommodations (commercial/business zones)_, _Employment Facilities_, _Residential Neighborhoods_ based on ADA Act Priority Scores.
* From a point of interest, a 1-2 block radius search is generated showings sidewalks with **Observable Issues**. 

## Sidewalks 
* Sidewalks are generated through a public [Sidewalk Observations](https://data.seattle.gov/dataset/SidewalkObservations/q37p-ync7) datasheet. Each sidewalk is one block long. 
* Sidewalks carry observable issues. taken from [Sidewalk Verifications](https://data.seattle.gov/dataset/SidewalkVerifications/dtqr-7xpd). 

Data sources:
* Sidewalk observations: https://data.seattle.gov/dataset/SidewalkObservations/q37p-ync7
* Sidewalk verifications: https://data.seattle.gov/dataset/SidewalkVerifications/dtqr-7xpd