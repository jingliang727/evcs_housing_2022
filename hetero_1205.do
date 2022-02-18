
clear
capture log close
set more off
log using hetero_1213.smcl, replace
global path C:\Users\yqiu16\OneDrive - Princeton University\evcs_housing\data
cd "C:\Users\yqiu16\OneDrive - Princeton University\evcs_housing\data"
global wd1 "C:\Users\yqiu16\Desktop\EVCS_housing\"

*/
global path C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data
cd "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
global wd1 "C:\Users\jl3231\Desktop\EVCS_housing\"



// for happening opinion
xtplfc logprice_adjusted Remodel_Age IncomePC_county PopulationDensity_CountyAnnually ///
fed_fund_rate Residential_Elec_Price NaturalGasPrice ///
i.year i.monthfixed,zvars(D) uvars(happening)


xtplfc logprice_adjusted Remodel_Age IncomePC_county PopulationDensity_CountyAnnually fed_fund_rate Residential_Elec_Price NaturalGasPrice yearfixed1-monthfixed12 ,zvars(D) uvars(HPbyPop) gen(coef)
bysort HPbyPop:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save "C:\Users\wills\Desktop\Heat Pump Paper\Data\IF on premium\xtplfc result4-HPbyPOP.dta"
keep if HPbyPop<300000
gen HPbyPop_PC=HPbyPop/1000000
twoway line h95ci HPbyPop_PC, lpattern(dash) lcolor(grey) ||line l95ci HPbyPop_PC, lpattern(dash) lcolor(grey) ||line coef_1 HPbyPop_PC, lpattern(solid) lcolor(blue)
graph export "C:\Users\wills\Desktop\Heat Pump Paper\Data\IF on premium\Graph4.png", as(png) replace



clear

use ca_1205.dta // new file with traffic of aadt 2013-2020
 rename FIPS fips
destring zip,replace ignore("Â")
collapse logprice SalesPriceAmount vicinitypost* post fips km_to_nid, by(zip year month)
egen ym=group(year month)

merge m:1 fips year using hetero_covariates.dta
keep if _merge==3
capture drop coef*

xtset zip ym // repeated before
tsfill,full
 tab year,gen(yr)
 tab month,gen(mth)
 egen cy=group(county year)
 tab cy,gen(countyyear)
 gen vicinityall=(km_to_nid<1)
 gen vicinityallpost=vicinityall*post

save hetero_use.dta,replace

sort zip ym
quietly by zip ym : gen dup2 = cond(_N==1,0,_n)
tab dup2

xtset fips ym
xtbalance2 logprice, generate(balanceN) optimisation(N)

sort ImportParcelID
quietly by ImportParcelID : gen dup2 = cond(_N==1,0,_n)
tab dup2

sort ImportParcelID year month
order ImportParcelID year month

tsfill,full

drop if ImportParcelID<15900000


gen nonmissing=(month!=.)
sort ymfips year nonmissing

foreach var of varlist year month incp pop_intensity x65_happening sales residential ///
vicinitypost* fips logprice salesshare numberofvehicles{
bysort ym fips: replace `var'=`var'[_n-1] if missing(`var')
}




xtreg logprice vicinityallpost post i.countyyear i.year i.month,fe vce(cluster ImportParcelID)
estimates store results2

sort ImportParcelID year


******** xtplfc
clear
use hetero_use.dta
replace salesshare=salesshare*100
replace incp=inc/1000
/*
xtreg logprice vicinitypost* post  incp  ///
pop_intensity x65_happening salesshare residential yr1-mth12,fe vce(cluster zip)
 estimates store results1
esttab results1, b(3) se(3) scalars(r2) star( * 0.10 ** 0.05 *** 0.01) 
*/

*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
tsfill,full
xtplfc logprice post  pop_intensity x65_happening salesshare residential yr1-mth12 ///
,zvars(vicinityallpost) uvars(incp) gen(coef)

bysort incp:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save inc.dta,replace
keep if incp<90
*keep if incp>30
twoway (rarea h95ci l95ci incp, sort color(gs15)) line coef_1 incp, lpattern(solid) lcolor(gray) ///
xlabel(20 "20k" 30 "30k" 40 "40k" 50 "50k" 60 "60k" 70 "70k" 80 "80k" 90 "90k") ///
ytitle("Housing price %") xtitle("Income per capita") yline(0, lpattern(dash) lcolor(gray)) ///
xline(36.955, lpattern(dash) lcolor(gray))  xline(47.124, lpattern(dash) lcolor(gray)) ///
 text(2.5 37 "CA median:36,955", size(Small) color(grey)) ///
 text(2 55 "Sample median:47,124", size(Small)) legend(off)
 
 
 
 *** obs income
 
 clear
use hetero_use.dta
replace salesshare=salesshare*100
replace incp=inc/1000
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
tsfill,full
replace SalesPriceAmount=SalesPriceAmount/1000
 xtplfc SalesPriceAmount post  pop_intensity x65_happening salesshare residential yr1-mth12 ///
,zvars(vicinityallpost) uvars(incp) gen(coef)

bysort incp:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save inc.dta,replace
keep if incp<90
*keep if incp>30
twoway (rarea h95ci l95ci incp, sort color(gs15)) line coef_1 incp, lpattern(solid) lcolor(gray) ///
xlabel(20 "20k" 30 "30k" 40 "40k" 50 "50k" 60 "60k" 70 "70k" 80 "80k" 90 "90k") ///
ytitle("Housing price ($)") xtitle("Income per capita") yline(0, lpattern(dash) lcolor(gray)) ///
xline(36.955, lpattern(dash) lcolor(gray))  xline(47.124, lpattern(dash) lcolor(gray)) ///
 text(-100 37 "CA median:36,955", size(Small) color(grey)) ///
 text(200 55 "Sample median:47,124", size(Small)) legend(off)

** $36,955 california mean 2015-209/ sample median  47124   (2013-2020)  

** happening
clear
use hetero_use.dta
replace salesshare=salesshare*100
replace incp=inc/1000
*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
gen price=exp(logprice)
tsfill,full

xtplfc logprice post incp pop_intensity  salesshare residential yr1-mth12 ///
,zvars(vicinityallpost) uvars(x65_happening) gen(coef)

bysort x65_happening:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save x65_happening.dta,replace

twoway (rarea h95ci l95ci x65_happening, sort color(gs15)) line coef_1 x65_happening, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Environmental awareness (%)") yline(0, lpattern(dash) lcolor(gray)) ///
xline( 68.2, lpattern(dash) lcolor(gray))  xline(68.3, lpattern(dash) lcolor(gray)) ///
 text(2.5 67 "CA mean: 68.2",size(Small) color(grey)) ///
 text(1.5 71 "Sample mean:68.3",size(Small)) legend(off)

**** salesshare
 
clear
use hetero_use.dta
replace salesshare=salesshare*100
replace incp=inc/1000
*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
gen price=exp(logprice)
tsfill,full

xtplfc logprice post incp pop_intensity x65_happening residential yr1-mth12 ///
,zvars(vicinityallpost) uvars(salesshare) gen(coef)

bysort salesshare:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
drop if salesshare>10

** 9.622222 ca //  1.7 in 2020
twoway (rarea h95ci l95ci salesshare, sort color(gs15)) line coef_1 salesshare, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("EV sales share (%)") yline(0, lpattern(dash) lcolor(gray)) ///
xline( 1.7, lpattern(dash) lcolor(gray))  xline(9.6, lpattern(dash) lcolor(gray)) ///
 text(0 1.7 "US mean: 1.7",size(Small) color(grey)) ///
 text(-0.05 9 "Sample mean:9.6",size(Small)) legend(off)
 
 
 
 ***population density
clear
use hetero_use.dta
replace salesshare=salesshare*100
replace incp=inc/1000
*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
gen price=exp(logprice)
tsfill,full

xtplfc logprice post incp pop_intensity  salesshare residential yr1-mth12 ///
,zvars(vicinityallpost) uvars(x65_happening) gen(coef)

bysort x65_happening:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save x65_happening.dta,replace

twoway (rarea h95ci l95ci x65_happening, sort color(gs15)) line coef_1 x65_happening, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Environmental awareness (%)") yline(0, lpattern(dash) lcolor(gray)) ///
xline( 68.2, lpattern(dash) lcolor(gray))  xline(68.3, lpattern(dash) lcolor(gray)) ///
 text(2.5 67 "CA mean: 68.2",size(Small) color(grey)) ///
 text(1.5 71 "Sample mean:68.3",size(Small)) legend(off)
 
 
*** hispanic share

clear
use hetero_use.dta
replace salesshare=salesshare*100
replace incp=inc/1000
*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
gen price=exp(logprice)
tsfill,full

xtplfc logprice post incp pop_intensity  salesshare residential yr1-mth12 x65_happening ///
,zvars(vicinityallpost) uvars(hispanic_share) gen(coef)

bysort hispanic_shareg:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save hispanic_share.dta,replace

twoway (rarea h95ci l95ci hispanic_share, sort color(gs15)) line coef_1 hispanic_share, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Environmental awareness (%)") yline(0, lpattern(dash) lcolor(gray)) ///
xline( 68.2, lpattern(dash) lcolor(gray))  xline(68.3, lpattern(dash) lcolor(gray)) ///
 text(2.5 67 "CA mean: 68.2",size(Small) color(grey)) ///
 text(1.5 71 "Sample mean:68.3",size(Small)) legend(off)
 
 *** black and white share
 replace whiteshare=whiteshare*100
 replace salesshare=salesshare*100
replace incp=inc/1000
*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
gen price=exp(logprice)
tsfill,full

xtplfc logprice post incp pop_intensity  salesshare residential yr1-mth12 x65_happening ///
,zvars(vicinityallpost) uvars(whiteshare) gen(coef)

bysort whiteshare:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save whiteshare.dta,replace
drop if whiteshare<40
drop if whiteshare>80

twoway (rarea h95ci l95ci whiteshare, sort color(gs15)) line coef_1 whiteshare, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Environmental awareness (%)") yline(0, lpattern(dash) lcolor(gray)) ///
xline( 69.7, lpattern(dash) lcolor(gray))  xline(71.9, lpattern(dash) lcolor(gray)) ///
 text(-0.05 72 "CA mean: 71.9",size(Small) color(grey)) ///
 text(0.05 61 "Sample mean:69.7",size(Small)) legend(off)
 
 *** blackshare
 
  replace salesshare=salesshare*100
replace incp=inc/1000
*gen vicinitypost=(vicinitypost1==1|vicinitypost2==1|vicinitypost3==1|vicinitypost4==1|vicinitypost5==1 ///
*|vicinitypost6==1|vicinitypost7==1|vicinitypost8==1|vicinitypost9==1)
capture egen cy=group(county year)
capture tab cy,gen(countyyear)
gen price=exp(logprice)
tsfill,full

xtplfc logprice post incp pop_intensity  salesshare residential yr1-mth12 x65_happening ///
,zvars(vicinityallpost) uvars(blackshare) gen(coef)

bysort blackshare:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save blackshare.dta,replace

twoway (rarea h95ci l95ci blackshare, sort color(gs15)) line coef_1 blackshare, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Black share (%)") yline(0, lpattern(dash) lcolor(gray)) ///
xline( 68.2, lpattern(dash) lcolor(gray))  xline(68.3, lpattern(dash) lcolor(gray)) ///
 text(2.5 67 "CA mean: 68.2",size(Small) color(grey)) ///
 text(1.5 71 "Sample mean:68.3",size(Small)) legend(off)
 
 
 

