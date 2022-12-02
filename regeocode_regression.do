
clear
capture log close
set more off
*log using evcs_regeocode.smcl, replace
log using evcs_regeocode_0628.smcl, replace
log using evcs_regeocode_0703.smcl, replace

*global path 
*cd 



clear
use property_regeocode

rename y latitude
ren x longitude

drop if ImportParcelID==.


sort ImportParcelID
quietly by ImportParcelID: gen dup2 = cond(_N==1,0,_n)
*tab dup2

drop if dup2>1 
drop if dup2==0

drop dup*

drop _merge
geonear ImportParcelID latitude longitude using ca_evcs_1204.dta, ///
   wide neighbors(id latitude longitude)
forval i=1/9 {
local j=`i'-1 
gen byte vicinity_`i'=1 if km_to_nid <= 0.`i' & km_to_nid>0.`j'
replace vicinity_`i'=0 if missing(vicinity_`i')

}

gen byte vicinity_10=1 if km_to_nid<=1 & km_to_nid>0.9
replace vicinity_10=0 if vicinity_10==.
   

sum km_to_nid

ren nid id
merge m:1 id using ca_evcs.dta // get opendate of closest evsc
keep if _merge==3
rename zip evcszip

keep ImportParcelID TransId FIPS vicinity* opendate km_to_nid evcszip id

save ca_vicinity_0609,replace 


**** RUN REGRESSION
use property_regeocode,clear
 
bysort TransId: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>0

capture drop _merge

merge 1:1 TransId using saleprice_1101
keep if _merge==3 
 
drop if SalesPriceAmount==.  // 17 million

sum SalesPriceAmount,d
drop if SalesPriceAmount < r(p5)

format TransId %12.0g
decode RecordingDate,gen (date)
gen ddate=date(date,"YMD")
drop if ddate==.
sort TransId
drop date
rename ddate date

sort ImportParcelID
quietly by ImportParcelID : gen dup1 = cond(_N==1,0,_n)
*tab dup1 // too many cannot dup
drop if dup1==0

gen logprice=ln(SalesPriceAmount)
gen month=month(date)
gen year=year(date)

drop if PropertyZip<90000
bysort PropertyZip year: egen modeCounty=mode(County)
egen countyyear=group(modeCounty year)


** merge vicinity
capture drop _merge

merge m:m ImportParcelID using ca_vicinity_0609,force

keep if _merge==3
gen open_date=date(opendate,"YMD")
bysort ImportParcelID: gen post=(date>open_date)

forval i=1/10 {
replace vicinity_`i'=0 if missing(vicinity_`i')

}

forval i=1/10 {
gen  vicinitypost`i'=vicinity_`i'*post 

}
drop if date==.
sort ImportParcelID date
capture drop dup
quietly by ImportParcelID date : gen dup = cond(_N==1,0,_n)
tab dup
drop if dup>1
*drop if year<1900

drop if year<1993
drop _merge
merge m:1 year using cpi_evcs
gen pricenew=SalesPriceAmount*cpi_2021
drop logprice
gen logprice=ln(pricenew)
save ca_0609.dta,replace // this file adjusted for price ca_1205

xtset ImportParcelID date
xtreg logprice vicinitypost* post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("a. Change in housing prices with EVCSs",size(medium)) subtitle("（with county,year fixed effects）")



xtset ImportParcelID date
xtreg logprice vicinitypost* post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2  

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("b. Change in housing prices with EVCSs",size(medium)) subtitle("（with county*year fixed effects）")



log using regeocode_0705.smcl

**cluster at county level 
log using ca_1114_cluster_county.smcl, replace
use ca_1102.dta

use ca_0609.dta,clear

xtset ImportParcelID date
xtreg logprice vicinitypost* post i.countyyear i.month,fe vce(cluster County)
estimates store results2  

esttab results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("Change in housing prices with EVCSs",size(medium)) subtitle("（clustered at county level）")




** check number of houses
use ca_0609.dta,clear

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)


**
gen n=1
collapse (sum)n (mean)vicinityall,by(ImportParcelID)





