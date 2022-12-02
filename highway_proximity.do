

clear
capture log close
set more off
log using evcs_hwproximity.smcl, replace


*global path 
*cd 


***highway gis data transform

clear

. import excel "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data\Jo
> in_Output_TableToExcel.xls", sheet("Join_Output_TableToExcel") firstrow

. sum
 gen hwproximity=(OBJECTID_1!=.)

. tab hwproximity
drop OBJECTID_1- ORIG_FID

drop OBJECTID_1- ORIG_FID

save highway_proximity
keep id hwproximity

save hwproximity.dta,replace

** regression

clear 
use ca_0609
sort id
capture drop _merge
merge m:1 id using hwproximity
keep if _merge==3


forval i=1/10 {
gen  hwvicinitypost`i'=hwproximity*vicinity_`i'*post 

}

gen hwpost=hwproximity*post

xtset ImportParcelID date
xtreg logprice hwvicinitypost* hwpost post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

coefplot, vertical keep(hwvicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("a. Change in housing prices with highway EVCSs",size(medium)) subtitle("（with county,year fixed effects）")

graph save "highway_a"


xtreg logprice hwvicinitypost* hwpost post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2  

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(hwvicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("b. Change in housing prices with highway EVCSs",size(medium)) subtitle("（with county*year fixed effects）")


graph save "highway_b"




