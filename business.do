

*https://www.census.gov/data/datasets/2019/econ/cbp/2019-cbp.html

clear
capture log close
set more off
log using business_0630.smcl, replace //forget to have log file open
*global path 
*cd 


**** clean business data

foreach i in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 {
import delimited "\$wd1\zbp`i'totals\zbp`i'totals.txt",clear
keep zip est
gen year=20`i'
save 20`i'_est.dta,replace
}


foreach i in 94 95 96 97 98 99 {
import delimited "\$wd1\zbp`i'totals\zbp`i'totals.txt",clear
keep zip est
gen year=19`i'
save 19`i'_est.dta,replace
}

use 1994_est.dta,clear
forval i=1995/2019 {
capture drop _merge
append using `i'_est.dta

}

save est.dta,replace
gen state=round(PropertyZip/10000)
keep if state==9
sort PropertyZip year
quietly by PropertyZip year:  gen dup = cond(_N==1,0,_n)
		
tab dup
keep PropertyZip year est
save ca_business.dta,replace
		
		
		
*** 
*use "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data\ca_1216.dta",clear 
use ca_0609.dta,clear
capture drop _merge
merge m:1 PropertyZip year using "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\business\ca_business.dta"
keep if _merge==3

replace est=est*1000

xtset ImportParcelID date
xtreg logprice vicinitypost* post est i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("a. Change in housing prices with EVCSs",size(medium)) subtitle("（with county,year fixed effects）")

graph save "business_a"
xtreg logprice vicinitypost* post i.countyyear i.month est,fe vce(cluster ImportParcelID)
estimates store results2  

esttab results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("b. Change in housing prices with EVCSs",size(medium)) subtitle("（with county*year fixed effects）")
graph save "business_b"

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)


**
gen n=1
collapse (sum)n (mean)vicinityall,by(ImportParcelID)
