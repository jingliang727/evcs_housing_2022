


clear
capture log close
set more off

log using did_multi_0807.smcl, replace


*global path 
*cd 



clear
use zipcode_pl.dta,clear //from event study 


tab month,gen(mth)
tab year,gen(yr)

global ind cty1-yr29

did_multiplegt logprice PropertyZip ym withevcs,robust_dynamic  ///
placebo(1) breps(100) cluster(PropertyZip) controls($ind)


did_multiplegt logprice PropertyZip ym withevcs,robust_dynamic  ///
placebo(1) breps(20) cluster(PropertyZip) controls($ind)


event_plot e(estimates)#e(variances), default_look ///
	graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("did_multiplegt") xlabel(-15(1)5)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	
	
	
	*** twoway fixed effects
	
	
set maxvar 100000

gen vicinityallpost=vicinityall*post


 twowayfeweights logprice ImportParcelID date vicinityallpost,type(feTR)
 
 **** 1223  
 use zipcode_pl.dta,clear 
 
 
 tab year,gen(yr)
 tab month,gen(mnth)
 
 twowayfeweights logprice PropertyZip ym post,type(feS) controls(yr1-yr29 mnth1-mnth12)
 
 keep if year>=2020
 
 fuzzydid logprice withevcs year post,did tc cic cluster(PropertyZip)
 



