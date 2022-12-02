
clear
capture log close
set more off


*** multiple family house


log using multi_0702_2.smcl, replace



global path "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
cd "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"


***0701



clear
use ca_0609.dta

capture drop _merge
merge m:1 ImportParcelID using multi0701

rename PropertyLandUseStndCode housetype
encode housetype,gen(house)

gen vicinityall=(vicinity_1==1| vicinity_2==1| vicinity_3==1| vicinity_4==1 | vicinity_5==1 ///
|vicinity_6==1| vicinity_7==1 | vicinity_8==1 | vicinity_9==1 |vicinity_10==1)
gen vicinitypost=vicinityall*post

gen housevicinity=house*vicinitypost



xtset ImportParcelID date
xtreg logprice i.housevicinity vicinitypost post i.year i.month,fe vce(cluster ImportParcelID)
estimates store results1

esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)

xtset ImportParcelID date
xtreg logprice i.housevicinity vicinitypost post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2
esttab results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01)


xtreg logprice vicinitypost* post i.countyyear i.month,fe vce(cluster ImportParcelID)
estimates store results2  

esttab results1 results2, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1") ///
ytitle("Housing price %") xtitle("km") title("b. Change in housing prices with EVCSs",size(medium)) subtitle("（with county*year fixed effects and business patterns）")

graph save "multi_0701_b",replace






** check number of houses

gen n=1
collapse (sum) n ,by(ImportParcelID)



***summary statistics

use ca_1216.dta,clear
bysort vicinityall: sum SalesPriceAmount year post  vicinity_1-vicinity_10 





