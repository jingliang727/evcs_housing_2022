
clear
capture log close
set more off

log using dynamic_neighbor_0702.smcl, replace



global path "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
cd "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"



*****

use property_regeocode,clear
 
bysort TransId: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>0

capture drop _merge

merge 1:1 TransId using saleprice_1101
keep if _merge==3 

sum SalesPriceAmount,d

drop if SalesPriceAmount < r(p5)
 
drop if SalesPriceAmount==.  // 17 million
format TransId %12.0g
decode RecordingDate,gen (date)
gen ddate=date(date,"YMD")
drop if ddate==.
sort TransId
drop date
rename ddate date

gen month=month(date)
gen year=year(date)

drop if PropertyZip<90000


collapse SalesPriceAmount, by(PropertyZip year)

sort PropertyZip year

tsset PropertyZip year
tsfill

by PropertyZip: gen rate=SalesPriceAmount/SalesPriceAmount[_n-1]-1

sum rate,d
drop if rate>r(p99)

collapse rate,by(PropertyZip)  

gen n=_n
xtile quart = rate, nq(4) //higher 1-4 higher rate
drop n

xtile third = rate, nq(3) 
xtile second=rate,nq(2)
save rate.dta,replace 
//0.17 mean from https://www.ceicdata.com/en/indicator/united-states/house-prices-growth#:~:text=US%20house%20prices%20grew%2017.5,%2D11.9%25%20in%20Mar%202009.

//mean=0.07

****
clear
use ca_0609.dta
merge m:1 PropertyZip using rate.dta
keep if _merge==3

sum SalesPriceAmount,d
drop if SalesPriceAmount < r(p5)

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)

gen vicinityallpost=vicinityall*post

*** second
gen secondvicinity=second*vicinityallpost


xtset ImportParcelID date
xtreg logprice i.secondvicinity vicinityallpost post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)


xtreg logprice i.secondvicinity vicinityallpost post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)


**** income
clear
use zipcode_income.dta,clear

use "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data\zipcode_income.dta" 
tsset zipcode year
tsfill

by zipcode: gen incomerate=meanincome/meanincome[_n-1]-1

sum incomerate,d
drop if incomerate>r(p99)

collapse incomerate,by(zipcode)  

xtile incomesecond = incomerate, nq(2) 

rename zipcode PropertyZip
save incomesecond.dta,replace

log using incomesecond.smcl

clear
use ca_0609.dta
merge m:1 PropertyZip using incomesecond.dta
keep if _merge==3

sum SalesPriceAmount,d
drop if SalesPriceAmount < r(p5)

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)

gen vicinityallpost=vicinityall*post

*** second
gen secondvicinity=incomesecond*vicinityallpost


xtset ImportParcelID date
xtreg logprice i.secondvicinity vicinityallpost post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)


xtreg logprice i.secondvicinity vicinityallpost post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)


*** third
keep if third==1

xtset ImportParcelID date
xtreg logprice vicinitypost* post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("a. Change in housing prices with EVCSs",size(medium)) subtitle("（with county,year fixed effects）")


graph save "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\graph\third1_a"

xtset ImportParcelID date
xtreg logprice vicinitypost* post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2  

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("b. Change in housing prices with EVCSs",size(medium)) subtitle("（with county*year fixed effects）")

graph save "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\graph\third1_b"

keep if third==3

xtset ImportParcelID date
xtreg logprice vicinitypost* post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("a. Change in housing prices with EVCSs",size(medium)) subtitle("（with county,year fixed effects）")


graph save "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\graph\third3_a"

xtset ImportParcelID date
xtreg logprice vicinitypost* post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2  

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("b. Change in housing prices with EVCSs",size(medium)) subtitle("（with county*year fixed effects）")

graph save "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\graph\third3_b"
