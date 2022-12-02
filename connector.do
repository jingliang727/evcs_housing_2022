


clear
capture log close
set more off
log using connector_type.smcl, replace




*global path 
*cd 


clear

use ca_0609,clear
capture drop _merge
merge m:1 id using evcs_type.dta
keep if _merge==3

capture drop _merge
merge m:1 id using hwproximity
keep if _merge==3

drop if hwproximity==1

*save ca_connector_type
save ca_connector_type_0630.dta



**** Tesla

clear
use ca_connector_type 

gen tesla=0
replace tesla=1 if evconnectortypes=="TESLA"

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)
gen vicinityallpost=vicinityall*post

gen teslavicinityallpost=tesla*vicinityall*post

xtset ImportParcelID date
xtreg logprice teslavicinityallpost vicinityallpost post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results3 
esttab results3, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

xtreg logprice teslavicinityallpost vicinityallpost post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results2 
esttab results2 results3, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 



