
clear
capture log close
set more off


*** cross-sectional 


log using hedonic_0726.smcl, replace //fe and weights

global path "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
cd "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"


use hedonic_0706.dta,clear //property saleprice attr merge together

decode RecordingDate,gen (date)
gen ddate=date(date,"YMD")
drop if ddate==.
sort TransId
drop date
rename ddate date
gen year=year(date)
gen month=month(date)

drop dup
bysort ImportParcelID: gen dup=cond(_N==1,0,_n)
drop if dup>1

capture drop _merge
merge m:m ImportParcelID using ca_vicinity_0609
keep if _merge==3
drop _merge
rename FIPS fips
merge m:1 fips year using pop_inc_ev
keep if _merge==3

drop _merge
merge m:1 id using slope_evcs.dta 
keep if _merge==3


ren numberofvehicles evnumber

global covnew YearBuilt NoOfStories TotalBedrooms TotalRooms LandAssessedValue sqfeet incp pop evnumber

gen open_date=date(opendate,"YMD")
bysort ImportParcelID: gen post=(date>open_date)

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)

gen vicinityallpost=vicinityall*post


gen logprice=ln(SalesPriceAmount)
gen slopepost=slope*post
egen countyyear=group(county year)

ren numberofvehicles evnumber
save cross_0727.dta,replace



clear
use cross_0727.dta,clear

foreach var of varlist cy301-cy716 {
*tempfile evcs`var'.dta
capture keep if `var'==1
quietly keep if _N>10 
capture psmatch2 vicinityall $covnew, quietly neighbor(1) ai(1) common caliper(0.25) ties logit
capture pstest, treated(vicinityall) both 
capture	display r(medbias) //  
capture	drop if _weight==.	
capture	tab _treated
capture keep ImportParcelID _weight vicinityall PropertyZip _pscore _treated _support
capture drop zip*
capture save evcs`var'.dta,replace
capture use cross_0727.dta,clear
}


clear
use "evcscy1.dta"
forval i=1/716 { //716
capture keep ImportParcelID _weight vicinityall PropertyZip _pscore _treated _support
capture quietly append using "evcscy`i'.dta"

}
drop if _weight==.
tab vicinityall
psgraph, title("Common support for consumers with and without vicinity to EVCS",size(medium))
 graph save Graph "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\graph\psgraph_0727.gph", replace
capture drop _merge

destring PropertyZip,replace


save zipexact_0727.dta,replace

global covnew1 YearBuilt NoOfStories TotalBedrooms TotalRooms LandAssessedValue sqfeet incp pop 

clear
use cross_0727,clear
capture drop _merge
merge m:1 ImportParcelID using zipexact_0727.dta 
keep if _merge==3

capture drop _merge

ren PropertyZip zipcode

reg logprice vicinityall vicinityallpost post $covnew1 i.County i.year i.month [pweight=_weight]
estimates store results1  

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

reg logprice vicinityall vicinityallpost post $covnew i.countyyear i.month [pweight=_weight]
estimates store results2  

esttab results1  results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

