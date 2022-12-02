
clear
capture log close
set more off

 log using traffic_0708.smcl, replace


*global path 
*cd 





clear
use property_regeocode

rename y latitude
ren x longitude

drop if ImportParcelID==.

sort ImportParcelID
quietly by ImportParcelID: gen dup2 = cond(_N==1,0,_n)

drop if dup2>1
drop if dup2==0 

drop dup*

drop _merge
geonear ImportParcelID latitude longitude using ca_evcs_traffic.dta, ///
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
merge m:1 id using ca_evcs.dta // get opendate 
keep if _merge==3
rename zip evcszip

keep ImportParcelID TransId FIPS vicinity* opendate km_to_nid evcszip id

save ca_vicinity_0706,replace 


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

merge m:m ImportParcelID using ca_vicinity_0706,force

keep if _merge==3

drop _merge
capture drop _merge
rename nid id
merge m:m id year using ca_evcs_traffic.dta 
keep if _merge==3

gen open_date=date(opendate,"YMD")
bysort ImportParcelID: gen post=(date>open_date)


drop if aadt==.

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

drop if year<1993
drop _merge
merge m:1 year using cpi_evcs
gen pricenew=SalesPriceAmount*cpi_2021
drop logprice
gen logprice=ln(pricenew)
save ca_traffic_0707.dta,replace /



*** 1203

clear
use ca_traffic_0707.dta
gen lnaadt=ln(aadt)
gen lnmadt=ln(madt)
gen lnhadt=ln(hadt)

gen lnpm=ln(pm) //2015-2020

xtset ImportParcelID date

xtreg lnaadt post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results0  

xtreg lnaadt post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results1  

esttab results0 results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

xtreg lnmadt post  i.year i.month,fe vce(cluster ImportParcelID)
estimates store results2  

xtreg lnmadt post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results3  

esttab results2 results3, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

xtreg lnhadt post  i.year i.month,fe vce(cluster ImportParcelID)
estimates store results4  

xtreg lnhadt post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results5  

esttab results0 results1 results2 results3 , b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 
esttab  results4 results5, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 




bysort ImportParcelID: egen modezip=mode(PropertyZip)
xtset ImportParcelID date

xtreg lnaadt post i.year i.month,fe vce(cluster modezip)
estimates store results0  

xtreg lnaadt post i.countyyear i.month,fe vce(cluster modezip)
estimates store results1  

esttab results0 results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

xtreg lnmadt post  i.year i.month,fe vce(cluster modezip)
estimates store results2  

xtreg lnmadt post i.countyyear i.month,fe vce(cluster modezip)
estimates store results3  

esttab results2 results3, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

xtreg lnhadt post  i.year i.month,fe vce(cluster modezip)
estimates store results4  

xtreg lnhadt post i.countyyear i.month,fe vce(cluster modezip)
estimates store results5  

esttab results0 results1 results2 results3 , b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 
esttab  results4 results5, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

xtset ImportParcelID date

xtreg lnpm post i.year i.month,fe vce(cluster modezip)
estimates store results6  

xtreg lnpm post i.countyyear i.month ,fe vce(cluster modezip)
estimates store results7  

esttab results6 results7, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 



