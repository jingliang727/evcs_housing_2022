#####################################################################################
#  Building a simple hedonic dataset from ZTRAX
#   The purpose of this code is to demonstrate the structure and some of the nuance
#   of the ZTRAX dataset. Ultimately, individual researchers are responsible
#   for all data cleaning and the subsequent results using ZTRAX. See the detailed ZTRAX
#   documentation for all available variables and variable descriptions. 
#
#  Skylar Olsen, PhD
#  Zillow Senior Economist 
#  2016-03-05
#####################################################################
### this one is for sale price; sale date

## Preliminaries
rm(list=ls())

## This function will check if a package is installed, and if not, install it
pkgTest <- function(x) {
  if (!require(x, character.only = TRUE))
  {
    install.packages(x, dep = TRUE)
    if(!require(x, character.only = TRUE)) stop("Package not found")
  }
}

## These lines load the required packages
packages <- c("readxl", "data.table")
lapply(packages, pkgTest)
library(foreign)

## These lines set several options
options(scipen = 999) # Do not print scientific notation
options(stringsAsFactors = FALSE) ## Do not load strings as factors

# Change directory to where you've stored ZTRAX
dir <- "C:/Users/yqiu16/Desktop/EVCS_housing/data/06"


#  Pull in layout information
layoutZAsmt <- read_excel(file.path(dir, 'layout.xlsx'), sheet = 1)
layoutZTrans <- read_excel(file.path(dir, 'layout.xlsx'), 
                           sheet = 2,
                           col_types = c("text", "text", "numeric", "text", "text"))



#############################################################################################################
#############################################################################################################
### IMPORTANT: These files are very large. While prototyping, limit the number of rows you load.
###            When ready, change prototyping to FALSE.
#############################################################################################################
#############################################################################################################

prototyping <- FALSE

if(prototyping){
  rows2load <- 1000
 }else{
  rows2load <- NULL
}


######################################################################
###  Create property attribute table
#    Need 3 tables
#    1) Main table in assessor database
#    2) Building table
#    3) BuildingAreas
col_namesProperty <- layoutZTrans[layoutZTrans$TableName == 'utPropertyInfo', 'FieldName']

col_namesBldg <- layoutZAsmt[layoutZAsmt$TableName == 'utBuilding', 'FieldName']
col_namesBldgA <- layoutZAsmt[layoutZAsmt$TableName == 'utBuildingAreas', 'FieldName']
col_namesLand <- layoutZAsmt[layoutZAsmt$TableName == 'utBuildingAreas', 'FieldName']
col_namesMain <- layoutZTrans[layoutZTrans$TableName == 'utMain', 'FieldName']
col_namesAsmtMain <- layoutZAsmt[layoutZAsmt$TableName == 'utMain', 'FieldName']


base <- read.table(file.path(dir, "./ZTrans/PropertyInfo.txt"),
                   #nrows = rows2load,                    
                   sep = '|',
                   header = FALSE,
                   stringsAsFactors = FALSE,             
                   skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                   comment.char="",                           # tells R not to read any symbol as a comment
                   quote = "",                                # this tells R not to read quotation marks as a special symbol
                   #col.names = col_namesMain
) 
col_namesPropertyInfo.t <- t(col_namesProperty)
names(base)<-paste(col_namesPropertyInfo.t)
base <- as.data.table(base)

base <- base[ , list(TransId,FIPS,PropertySequenceNumber,ImportParcelID,
                     PropertyAddressLatitude,PropertyAddressLongitude,LoadID,PropertyZip
)]


######################################################################
# Pull address, geographic, lot size, and tax data from main table

base1 <- read.table(file.path(dir, "./ZTrans/Main.txt"),
                   #nrows = rows2load,                    
                   sep = '|',
                   header = FALSE,
                   stringsAsFactors = FALSE,             
                   skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                   comment.char="",                           # tells R not to read any symbol as a comment
                   quote = "",                                # this tells R not to read quotation marks as a special symbol
                   #col.names = col_namesMain
) 
 
col_namesMain.t <- t(col_namesMain)
names(base1)<-paste(col_namesMain.t)
base1 <- as.data.table(base1)

base1 <- base1[ , list(TransId,SalesPriceAmount,FIPS,DocumentDate,County,LoadID,RecordingDate
                                   )] 
# 
# library(foreign)
# for (colname in names(base1)) {
#   if (is.character(base1[[colname]])) {
#     base1[[colname]] <- as.factor(base1[[colname]])
#   }
# }

######################################################################
#### Load most property attributes

bldg <- read.table(file.path(dir, "./ZAsmt/Building.txt"),
                  # nrows = rows2load,                    # this is set just to test it out. Remove when code runs smoothly.
                   sep = '|',
                   header = FALSE,
                   stringsAsFactors = FALSE,             
                   skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                   comment.char="",                           # tells R not to read any symbol as a comment
                   quote = "",                                # this tells R not to read quotation marks as a special symbol
                   #col.names = col_namesBldg
                   ) 

col_namesBldg.t <- t(col_namesBldg)
names(bldg)<-paste(col_namesBldg.t)
bldg <- as.data.table(bldg)

bldg <- bldg[ , list(RowID, BuildingOrImprovementNumber, 
                     YearBuilt, YearRemodeled,
                     NoOfStories, TotalRooms, TotalBedrooms, 
                     FIPS,PropertyLandUseStndCode)]


#  Reduce bldg dataset to Single-Family Residence, Condo's, Co-opts (or similar)

bldg <- bldg[PropertyLandUseStndCode %in% c('RR101',  # SFR
                                            'RR999',  # Inferred SFR
                                          # 'RR102',  # Rural Residence   (includes farm/productive land?)
                                            'RR104',  # Townhouse
                                            'RR105',  # Cluster Home
                                            'RR106',  # Condominium
                                            'RR107',  # Cooperative
                                            'RR108',  # Row House
                                            'RR109',  # Planned Unit Development
                                            'RR113',  # Bungalow
                                            'RR116',  # Patio Home
                                            'RR119',  # Garden Home
                                            'RR120'), # Landominium
             ]

######################################################################
#### Load building squarefoot data

sqft <- read.table(file.path(dir, "./ZAsmt/BuildingAreas.txt"),
                  # nrows = rows2load,                    # this is set just to test it out. Remove when code runs smoothly.
                   sep = '|',
                   header = FALSE,
                   stringsAsFactors = FALSE,             
                   skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                   comment.char="",                           # tells R not to read any symbol as a comment
                   quote = "",                                # this tells R not to read quotation marks as a special symbol
                  # col.names = col_namesBldgA
)

col_namesBldgA.t <- t(col_namesBldgA)
names(sqft)<-paste(col_namesBldgA.t)
sqft <- as.data.table(sqft)

# Counties report different breakdowns of building square footage and/or call similar concepts by different names.
# The structure of this table is to keep all entries reported by the county as they are given. See 'Bldg Area' table in documentation.
# The goal of this code is to determine the total square footage of each property. 
# We assume a simple logic to apply across all counties here. Different logic may be as or more valid.
# The logic which generates square footage reported on our sites is more complex, sometimes county specific, and often influenced by user interaction and update. 

sqft <- sqft[BuildingAreaStndCode %in% c('BAL',  # Building Area Living
                                         'BAF',  # Building Area Finished
                                         'BAE',  # Effective Building Area
                                         'BAG',  # Gross Building Area
                                         'BAJ',  # Building Area Adjusted
                                         'BAT',  # Building Area Total
                                         'BLF'), # Building Area Finished Living
             ]

table(sqft$BuildingOrImprovementNumber)  # BuildingOrImprovementNumber > 1  refers to additional buildings on the parcel. 

sqft <- sqft[ , list(sqfeet = max(BuildingAreaSqFt, na.rm = T)), by = c("RowID", "BuildingOrImprovementNumber","BatchID")]


#### value
col_namesLandValue <- layoutZAsmt[layoutZAsmt$TableName == 'utValue', 'FieldName']

landvalue <- read.table(file.path(dir, "./ZAsmt/Value.txt"),
                   # nrows = rows2load,                    # this is set just to test it out. Remove when code runs smoothly.
                   sep = '|',
                   header = FALSE,
                   stringsAsFactors = FALSE,             
                   skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                   comment.char="",                           # tells R not to read any symbol as a comment
                   quote = "",                                # this tells R not to read quotation marks as a special symbol
                   # col.names = col_namesBldgA
)

col_namesLandValue.t <- t(col_namesLandValue)
names(landvalue)<-paste(col_namesLandValue.t)
landvalue <- as.data.table(landvalue)

landvalue <- landvalue[ , list(RowID, LandAssessedValue
                     )]
sqft <- merge(sqft, landvalue, by = c("RowID"))



#### asmt main data to merge trans and asmt


AsmtMain <- read.table(file.path(dir, "./ZAsmt/Main.txt"),
                   # nrows = rows2load,                    # this is set just to test it out. Remove when code runs smoothly.
                   sep = '|',
                   header = FALSE,
                   stringsAsFactors = FALSE,             
                   skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                   comment.char="",                           # tells R not to read any symbol as a comment
                   quote = "",                                # this tells R not to read quotation marks as a special symbol
                   # col.names = col_namesBldgA
)

col_namesAsmtMain.t <- t(col_namesAsmtMain)
names(AsmtMain)<-paste(col_namesAsmtMain.t)
AsmtMain <- as.data.table(AsmtMain)

AsmtMain <- AsmtMain[ , list(RowID, FIPS,BatchID,
                     ImportParcelID
)]


###############################################################################
#   Merge previous three datasets together to form attribute table

#write.dta(base, "C:/Users/yqiu16/Desktop/EVCS_housing/data/property.dta") 
write.dta(base, "C:/Users/yqiu16/OneDrive - Princeton University/evcs_housing/property.dta") 



for (colname in names(base1)) {
  if (is.character(base1[[colname]])) {
    base1[[colname]] <- as.factor(base1[[colname]])
  }
}
write.dta(base1, "C:/Users/yqiu16/OneDrive - Princeton University/evcs_housing/saleprice_1101.dta") 

for (colname in names(attr2)) {
  if (is.character(attr2[[colname]])) {
    attr2[[colname]] <- as.factor(attr2[[colname]])
  }
}

write.dta(attr2, "C:/Users/yqiu16/OneDrive - Princeton University/evcs_housing/data/attr.dta") 

###### save merged files to stata
#property price and property parcelId (trans)
saleprice<-merge(base,base1, by = c("TransId","FIPS"))

# builidng attr and sqt (asmt) using rowid 
attr1 <- merge(bldg, sqft, by = c("RowID", "BuildingOrImprovementNumber"))
attr2 <- merge(attr1,AsmtMain , by = c("RowID", "BatchID"))

#salepricenew<-merge(saleprice,AsmtMain, by = c("ImportParcelID","FIPS"))
#attr_final <- merge(salepricenew, attr1, by= c ("RowID","BuildingOrImprovementNumber"))


for (colname in names(attr1)) {
  if (is.character(attr1[[colname]])) {
    attr1[[colname]] <- as.factor(attr1[[colname]])
  }
}

write.dta(attr1, "C:/Users/yqiu16/Desktop/EVCS_housing/data/ca6_attr.dta") 


for (colname in names(salepricenew)) {
  if (is.character(salepricenew[[colname]])) {
    salepricenew[[colname]] <- as.factor(salepricenew[[colname]])
  }
}
write.dta(salepricenew, "C:/Users/yqiu16/Desktop/EVCS_housing/data/ca6_saleprice.dta") 


#### save seperate files to stata


###############################################################################
###############################################################################
#  Load transaction dataset.
#     Need two tables
#      1) PropertyInfo table provided ImportParcelID to match transaction to assessor data loaded above
#      2) Main table in Ztrans database provides information on real estate events

col_namesProp <- layoutZTrans[layoutZTrans$TableName == 'utPropertyInfo', 'FieldName']
col_namesMainTr <- layoutZTrans[layoutZTrans$TableName == 'utMain', 'FieldName']


###############################################################################
#   Load PropertyInfo table for later merge

propTrans <- read.table(file.path(dir, "53/ZTrans/PropertyInfo.txt"),
                        nrows = rows2load,                    # this is set just to test it out. Remove when code runs smoothly.
                        sep = '|',
                        header = FALSE,
                        stringsAsFactors = FALSE,             
                        skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                        comment.char="",                           # tells R not to read any symbol as a comment
                        quote = "",                                # this tells R not to read quotation marks as a special symbol
                        col.names = col_namesProp
)

propTrans <- as.data.table(propTrans)

propTrans <- propTrans[ , list(TransId, PropertySequenceNumber, LoadID, ImportParcelID)]

# Keep only one record for each TransID and PropertySequenceNumber. 
# TransID is the unique identifier of a transaction, which could have multiple properties sequenced by PropertySequenceNumber. 
# Multiple entries for the same TransID and PropertySequenceNumber are due to updated records.
# The most recent record is identified by the greatest LoadID. 
#   **** This step may not be necessary for the published dataset as we intend to only publish most updated record. 

setkeyv(propTrans, c("TransId", "PropertySequenceNumber", "LoadID"))
keepRows <- propTrans[ ,.I[.N], by = c("TransId", "PropertySequenceNumber")]
propTrans <- propTrans[keepRows[[2]], ]
propTrans[ , LoadID:= NULL]

# Drop transactions of multiple parcels (transIDs associated with PropertySequenceNumber > 1)

dropTrans <- unique(propTrans[PropertySequenceNumber > 1, TransId])
propTrans <- propTrans[!(TransId %in% dropTrans), ]   # ! is "not"

#######################################################################################
#  Load main table in Ztrans database, which provides information on real estate events

trans <- read.table(file.path(dir, "53/ZTrans/Main.txt"),
                        nrows = rows2load,                    # this is set just to test it out. Remove when code runs smoothly.
                        sep = '|',
                        header = FALSE,
                        stringsAsFactors = FALSE,             
                        skipNul = TRUE,                            # tells R to treat two ajacent delimiters as dividing a column 
                        comment.char="",                           # tells R not to read any symbol as a comment
                        quote = "",                                # this tells R not to read quotation marks as a special symbol
                        col.names = col_namesMainTr
)

trans <- as.data.table(trans)

trans <- trans[ , list(TransId, LoadID,
                       RecordingDate, DocumentDate, SignatureDate, EffectiveDate,
                       SalesPriceAmount, LoanAmount,
                       SalesPriceAmountStndCode, LoanAmountStndCode,
                       # These remaining variables may be helpful to, although possibly not sufficient for, data cleaning. See documentation for all possible variables.
                       DataClassStndCode, DocumentTypeStndCode,      
                       PartialInterestTransferStndCode, IntraFamilyTransferFlag, TransferTaxExemptFlag,
                       PropertyUseStndCode, AssessmentLandUseStndCode,
                       OccupancyStatusStndCode)]

# Keep only one record for each TransID. 
# TransID is the unique identifier of a transaction. 
# Multiple entries for the same TransID are due to updated records.
# The most recent record is identified by the greatest LoadID. 
#   **** This step may not be necessary for the published dataset as we intend to only publish most updated record. 

setkeyv(trans, c("TransId", "LoadID"))
keepRows <- trans[ ,.I[.N], by = "TransId"]
trans <- trans[keepRows[[2]], ]
trans[ , LoadID:= NULL]

#  Keep only events which are deed transfers (excludes mortgage records, foreclosures, etc. See documentation.)

trans <- trans[DataClassStndCode %in% c('D', 'H'), ]

###############################################################################
#   Merge previous two datasets together to form transaction table

transComplete <- merge(propTrans, trans, by = "TransId")



