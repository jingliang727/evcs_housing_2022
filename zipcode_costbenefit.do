

clear
capture log close
set more off
log using zipcode_costbenefit.smcl, replace


global path "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"
cd "C:\Users\jl3231\OneDrive - Princeton University\evcs_housing\data"

clear

use ca_0609.dta

destring evcszip,replace ignore("Â")

gen withevcs=(evcszip==PropertyZip)
tab withevcs



collapse logprice (sum)SalesPriceAmount (sum)withevcs , by(PropertyZip)


save zipcode_costbenefit.dta,replace

clear
use zipcode_costbenefit.dta,clear

gen benefits=SalesPriceAmount*0.036*0.37

gen costs1=2800*withevcs
gen costs2=10500*withevcs
gen costs3=53300*withevcs

sum costs*

sum costs1,d
sum benefits,d

gen dif1=benefits-costs1
gen dif2=benefits-costs2
gen difdc=benefits-costs3


sum costs* dif*



*** check number of evcs at zip code 

clear
use ca_evcs.dta
gen n=1
collapse (sum)n,by(zip)

