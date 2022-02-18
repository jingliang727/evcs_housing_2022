

clear
capture log close
set more off
log using aw.smcl, replace
/*
global path "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
cd "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
global wd1 "C:\Users\jl3231\Desktop\EVCS_housing\"
*/

global path "C:\Users\yqiu16\OneDrive - Princeton University\evcs_housing\data"
cd "C:\Users\yqiu16\OneDrive - Princeton University\evcs_housing\data"
global wd1 "C:\Users\yqiu16\Desktop\EVCS_housing\"



clear
import delimited C:\Users\jl3231\Downloads\CAINC1\CAINC1_CA_1969_2019.csv

forval i=9/59 {
local j=1960+`i'
rename v`i' year`j'

}

drop in 1/3

drop in 175/178
replace geofips = subinstr(geofips, `"""',  "", .)

drop if linecode==1
drop indus*

keep if linecode==2
drop tablename*

forval i=1970/2019 {
local j=`i'-1
gen rate`i'=(year`i'-year`j')/year`j'

}
egen rate = rmean(rate1970 - rate2019)

gen year2020=year2019*(1+rate)
gen year2021=year2020*(1+rate)

 reshape long year,i(geofips) j(j)
 rename year pop
 rename j year
drop des* unit region linecode
capture drop _merge
save pop.dta,replace

clear
import delimited C:\Users\jl3231\Downloads\CAINC1\CAINC1_CA_1969_2019.csv

forval i=9/59 {
local j=1960+`i'
rename v`i' year`j'

}

drop in 1/3

drop in 175/178
replace geofips = subinstr(geofips, `"""',  "", .)

drop if linecode==1

keep if linecode==3

replace geoname = subinstr(geoname, ", CA", "",.)
merge 1:1 geoname using change
gen year2020=year2019*(1+change2/100)
gen change=(change1+change2)/2
gen year2021=year2020*(1+change/100)


 reshape long year,i(geofips) j(j)
 rename year incp
 rename j year
drop indus* tablename* des* unit region linecode

save incp.dta,replace

clear

use incp


drop _merge
merge 1:1 geofips year using pop.dta
drop _merge


rename geofips fips
destring fips,replace
merge m:1 fips using area.dta // area https://www.counties.org/pod/square-mileage-county
drop _merge
gen pop_intensity=pop/area
drop rate* change*

save pop_inc.dta,replace   //1969-2021


*** sales https://www.energy.ca.gov/files/zev-and-infrastructure-stats-data


drop if fuel_type=="Hydrogen"
capture drop make model fuel_type
replace county = subinstr(county, `" "',  "", .)
collapse (sum) numberofvehicles, by (datayear county)

gen state="California"
merge m:1 county state using "C:\Users\jl3231\OneDrive - Princeton University\county_fips.dta"
keep if _merge==3

rename datayear year
keep number* year fips
destring fips,replace
drop if numberofvehicles==.
save evsales.dta,replace

gen state="California"
replace county = subinstr(county, `" "',  "", .)
merge m:1 county state using "C:\Users\jl3231\OneDrive - Princeton University\county_fips.dta"

keep fips sale*
destring salesshare,ignore ("%") replace
replace salesshare=salesshare/100
destring fips,replace


save salesshare.dta,replace



*** price annual retail price by sector by state

*https://www.eia.gov/electricity/data.php

 keep if state=="CA"
 keep if industrysectorcategory=="Total Electric Industry"
drop commer* industri* tran* other
keep year residential
replace residential=residential/100
replace year = 2021 in 32
replace residential=0.2045 if year==2021

save ca_price.dta,replace

*** covariates 



clear
use pop_inc //6000

merge m:1 fips using awareness_1205
keep if _merge==3 //3000
drop _merge

sort fips year
merge 1:1 fips year using evsales.dta //1998-2021
drop if year<1998 //1300
replace numberofvehicles=0 if missing(numberofvehicles) 
drop _merge

merge m:1 fips using salesshare.dta //as of 2021/10 sales and salesshare

drop _merge
merge m:1 year using ca_price
drop if _merge==2
drop _merge
save hetero_covariates.dta,replace

clear
* share data from website
use hetero_covariates.dta
merge m:1 fips using hispanic_share_0212
drop _merge
save hetero_covariates.dta,replace

* white and black
clear
use "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data\hetero_covariates.dta"
merge 1:1 fips year using "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data\white_black.dta"

drop _merge
save,replace



***

* hispanic share
* https://www.census.gov/quickfacts/fact/table/buttecountycalifornia/RHI725219

use hispanic_share,clear
replace county = subinstr(county, " ", "", .)

merge 1:m county using  ca_county_fips

keep fips hispanic_share
destring fips,replace
save hispanic_share_0212



