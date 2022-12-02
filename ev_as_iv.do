

clear
capture log close
set more off
log using evcs_iv_0621.smcl, replace


*global path 
*cd 


tab fueltype

drop if fueltype=="Hydrogen"

rename datayear year
rename numberofvehicles nbev

collapse (sum)nbev,by (year zip)

save zipevno.dta,replace //1998-2022


clear
use ca_evcs.dta
gen open_date=date(opendate,"YMD")
drop if open_date==.
destring zip,replace ignore("Â")
gen year=year(open_date)

merge m:1 zip year using zipevno.dta
keep if _merge==3


drop _merge 

merge m:1 zip using  zip_to_county_ca //https://www.zip-codes.com/state/ca.asp#zipcodes
keep if _merge==3
drop _merge

gen n=1 //number of evcs
encode county, gen(County)

collapse County (sum)nbev n ,by(zip year)

sort zip year nbev n County

xtset zip year
xtreg n nbev,fe vce(cluster evcs)

save evcs_instrument.dta,replace

*** year level

clear

use ca_0609.dta
drop id-dup
drop if PropertyZip<90000


replace PropertyZip=user_propertyzip if missing(PropertyZip)

rename FIPS fips

bysort PropertyZip: egen modecounty=mode(County) 

 
collapse logprice SalesPriceAmount fips modecounty, by(PropertyZip year)
rename modecounty county
egen countyyear=group(county year)
drop if countyyear==.

rename PropertyZip zipcode 
merge m:1 zipcode year using zipcode_income.dta //2011-2020
keep if _merge==3
drop _merge


rename zipcode zip
merge m:1 zip year using evcs_instrument

replace nbev=0 if nbev==.
replace n=0 if n==.

rename n nevcs

rename zip PropertyZip

xtset PropertyZip year


save zipcode_instrument.dta,replace


xi: xtivreg2 SalesPriceAmount (nevcs=nbev) i.year,fe cluster(PropertyZip) first savefirst
estimates store results0 

esttab results0, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 


xi: xtivreg2 SalesPriceAmount (nevcs=nbev) i.year meanincome,fe cluster(PropertyZip) first savefirst
estimates store results2  

esttab results0 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 


xi: xtivreg2 SalesPriceAmount (nevcs=nbev) i.countyyear meanincome,fe cluster(PropertyZip) first savefirst
estimates store results3  

esttab results2 results3, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

sum SalesPriceAmount,d
return list
 di  12181.484/r(mean)
.0189345

. di 17685.814/r(mean)


