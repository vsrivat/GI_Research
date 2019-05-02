clear all
set more off 
capture log close
set scheme s1color

*cd "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Capstone/Kenya"
local resultsdir "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Kenya"

cd "`resultsdir'"

local excelfile "excelfile.xls"

log using "timefirstuse", replace

*****Analysis plan********

* Part 0. Data management
* Part a. Defining survival data
* Part c. Summary statistics

		*1---respondents's characteristics - By ever contraceptive use.
			//Mean age at interview, SD, T-test, p-value
			//Education levels or years of schooling
			//Marital status 
			//Wealth status 
			//Residence
			//Sexual initiation
			//Parity
		*2---Median time to contraceptive initiation by varibale.
		
* Part d. Plot Kaplan-Meier estimates of survivor function, by groups
			//Plot KM estimates by time interval 
			//Plot KM estimates by age 
			//Adjusted and unadjusted KM
* Part e. logrank test for survivor function by groups and test for collinearity
* Part f. Testing for collinearity
* Part g. Fit Cox Models
			//Undjusted models
			//Best subsets variable selection & Fitting Final Cox Models
			//Final adjusted model 

***************************

* Part 0. Data management

		use "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Kenya/PMA2017_KER6_HHQFQ_v1_28Aug2018.dta", clear
		save "KER6_PR_20190307.dta", replace

		shell md graphs

	*Generating Wealth tertiles
		preserve
		egen metatag=tag(metainstanceID)
		keep if metatag==1
		keep if HHQ_result==1
		xtile wealthtertile=score [pw=HHweight], nq(3)
		cap label define wealthtert 1 "Lowest tertile" 2 "Middle tertile"  3 "Highest tertile"
		label value wealthtertile wealthtert 
		keep metainstanceID wealthter
		tempfile temp
		save `temp', replace

		restore
	
	*Only 15-29 women
		keep if FQ_age <=29
	
	
	* Only using de-facto population
		keep if last_night==1

		
	* Generate follow-up time variable (expressed in years for convenience)

		drop if age_at_first_use<=age_at_first_sex
	
	* Use only completed HH interviews, use only 15-24 years females who have had sex. 
		keep if FRS_result==1 & HHQ==1
		gen hadsex=0 if (age_at_first_sex<0)
		replace hadsex=1 if hadsex==.
	
	//consider- To reduce recall bias it is suggested by Gillespie, Brenda
				//https://doi.org/10.1023/A:1016001211182.
		
		//drop if age_at_first_sex < 12 
		
		replace age_at_first_sex=. if age_at_first_sex==-77 | age_at_first_sex==-88 | age_at_first_sex==-99
		replace age_at_first_use=. if age_at_first_use==-88
		
		gen entry=age_at_first_sex

		generate interval=age_at_first_use-age_at_first_sex if fp_ever_used==1
		replace interval=FQ_age - age_at_first_sex if fp_ever_used!=1
		replace interval=0 if age_at_first_use <= age_at_first_sex

		total interval 

		merge m:1 metainstanceID using `temp', nogen
		save, replace

	/*
	******03/31/2019 (Chris and Varsha)

	drop if age_at_first_sex<12 & age_at_first_sex>age_at_first_use
	keep if FQ_age<24
	gen entry4 = age_at_first_sex
	gen exit4 = age_at_first_use
	gen fup = exit4-entry4 if fp_ever_used==1
	replace fup = 24-entry if fp_ever_used!=1 
	 
	total fup	
	stset fup, failure(fp_ever_used==1)
	sts graph, by (school) 

	*generate parity variable as a dichotomous variable 
	gen parity=birth_events
	replace parity=. if parity==-99
	recode parity 1/20=1 0=0
	label define parity 1"Ever birth" 0"Never birth"
	label values parity parity

	sts graph, by (parity)

	destring age_first_birth, replace
	
	gen EMM = 1 if age_first_birth != .
	replace EMM = 0 if age_first_birth == . & fup != .
	ta age_first_birth
	sts graph, by(EMM)
	
	sts graph, by (FQ_age)

	*/

	* Generate 5 years age group for female respondents
	replace FQ_age=. if FQ_age<0
	egen FQagecat=cut(FQ_age), at(15(5)50)
	label define FQagecat 15"15-19" 20"20-24" 25"25-29"
	label values FQagecat FQagecat

	* Generate category of highest level of education completed 
	* Post_primary_vocational & secondary asa level grouped into Secondary, college and university grouped into higher education
	replace school=. if school==-99
	recode school 1=1 2/6=2 0=0
	label define school 0"Never attended" 1"Primary" 2"Secondary+",modify
	label values school school
	
	* Generate new marital status category
	replace FQmarital_status=0 if FQmarital_status==5
	gen marital=FQmarital_status
	recode marital 0=0 1/2=1  3/4=2 -99=.
	label define marital 0"Never married" 1"Married/cohabiting" 2"Divorced/widowed" 
	label values marital marital

	* Generate future pregnancy intention for non pregnant women

	gen waitb=wait_birth
	replace waitb=wait_birth_pregnant if wait_birth_pregnant!=.
	replace waitb=0 if waitb==3 | (waitb==1 & wait_birth_value<24) | (waitb==2 &  wait_birth_value<2)
	replace waitb=1 if (waitb==1 & wait_birth_value>=24) | (waitb==2 &  wait_birth_value>=2)
	recode waitb 4/5=.
	label define wait_birth1 0"want kids in < 2 years" 1"wants kids in two or more years"
	label values waitb wait_birth1

	* Generate dichotomous marital status variable
	gen inunion=(FQmarital_status==1 | FQmarital_status==2)
	label define inunion 0"Not in a union" 1"In a union"
	label values inunion inunion
	replace inunion=. if FQmarital_status==-99

	*generate parity variable as a dichotomous variable 
	gen parity=birth_events
	replace parity=. if parity==-99
	recode parity 1/20=1 0=0
	label define parity 1"Ever birth" 0"Never birth"
	label values parity parity

	*generating early and late sexual debut
	gen earlysex=0 if age_at_first_sex < 17
	replace earlysex=1 if age_at_first_sex >=17 & age_at_first_sex <=29
	label define earlysex 0 "1st sex<17y.o" 1 "1st sex>17y.o"
	label values earlysex earlysex 

	*generate exposure to media FP information
	gen ex_info=1 if fp_ad_radio==1 | fp_ad_magazine==1 
	replace ex_info=0 if fp_ad_radio==0 | fp_ad_magazine==0
	replace ex_info=. if fp_ad_radio==-99 | fp_ad_magazine==-99
	lab def ex_info 0"FP media exposed" 1"No FP media exposure"
	lab val  ex_info ex_info
	
	*recode residence 
	recode ur (2=0 "rural") (1=1 "urban"), gen(residence)

* Part a. Defining survival data

	*set dataset as survival data
	svyset EA_ID [pw=FQweight], strata(strata) singleunit(scaled)
	*In Nigeria, change EA to Cluster in command above

	stset interval, failure(fp_ever_used==1)
	* CAN WEIGHT WITH P-WEIGHTS

	save Kenya_Fyouth.dta, replace 

* Part c. Summary statistics
			*1---respondents's characteristics - By ever contraceptive use.
			//Mean age at interview, SD, T-test, p-value
			//Education levels or years of schooling
			//Marital status 
			//Wealth status 
			//Residence
			//Sexual initiation
			//Parity
	
	svy: mean age, over(fp_ever_used)
	test [age]_subpop_1 = [age]_subpop_2

**Option 1
	tabout school fp_ever_used [aw=FQweight]  using "`excelfile'", replace ///
	c(freq col row) f(0 1) clab(n % %) npos(row)  h1("Table1")

	foreach var of varlist school inunion wealthtertile residence earlysex parity ex_info FQagecat {
	tabout `var' fp_ever_used [aw=FQweight] using "`excelfile'", append ///
	c(freq col row) f(0 1) clab(n % %) npos(row) h1("Respondents's characteristic by use status")
	}

**Option 2

	foreach var of varlist school inunion wealthtertile residence earlysex parity ex_info FQagecat {
	tabout `var' fp_ever_used using "`excelfile'", append ///
	c(row ci) svy f(3) stats(chi2) npos(col) cisep(-) h1("Respondents's characteristic by use status")
	}

	
*2---Quartiles and median time to contraceptive initiation by varibale.

	foreach var of varlist fp_ever_used school inunion wealthtertile residence earlysex parity ex_info FQagecat {
	stsum, by (`var')
	}


* Part d. Plot Kaplan-Meier estimates of survivor function, by groups & test the survivor and cumulative hazard functions

	sts graph 
	
	sts graph, by (FQagecat) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by age category", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(ACKMKenya, replace)saving(graphs/ACKMKenya.gph,replace)

	sts graph, by (wealthtertile) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by wealthtertile", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(WKMKenya, replace)saving(graphs/WKMKenya.gph,replace)
	sts graph, by (school) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by schooling", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(SMKenya, replace)saving(graphs/SMKenya.gph,replace)
	sts graph, by (residence) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by residence", size(small)) legend(size(small))xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(RMKenya, replace)saving(graphs/RMKenya.gph,replace)
	sts graph, by (parity) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by parity", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(PMKenya, replace)saving(graphs/PMKenya.gph,replace)
	sts graph, by (earlysex) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by earlysex", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(EMKenya, replace)saving(graphs/EMKenya.gph,replace)
	sts graph, by (inunion) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by inunion", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(UMKenya, replace)saving(graphs/UMKenya.gph,replace)

	cd "`resultsdir'/graphs"

	graph combine "WKMKenya.gph" "SMKenya.gph" "RMKenya.gph" "PMKenya.gph" "EMKenya.gph" "UMKenya.gph" 
	graph save combinedgraph, replace

	cd "`resultsdir'"
	
	sum FQ_age
	local mean r(mean)
	di `mean'
	gen agec=FQ_age-r(mean) //centering age to the mean age
	
****Other explorations 
	//Creating K-M adjusted by women's age
	// use option ---- failure adjustfor (age15) for cumulative
	
	sts graph, by (FQagecat) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by age category", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aACKMKenya, replace)saving(graphs/aACKMKenya.gph,replace)
	sts graph, by (wealthtertile) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival graph total", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aTKMKenya, replace)saving(graphs/aTKMKenya.gph,replace)
	sts graph, by (wealthtertile) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival by wealthtertile", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aWKMKenya, replace)saving(graphs/aWKMKenya.gph,replace)
	sts graph, by (school) adjustfor (agec)legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival by schooling", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aSMKenya, replace)saving(graphs/aSMKenya.gph,replace)
	sts graph, by (residence) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival by residence", size(small)) legend(size(small))xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aRMKenya, replace)saving(graphs/aRMKenya.gph,replace)
	sts graph, by (parity) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival by parity", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aPMKenya, replace)saving(graphs/aPMKenya.gph,replace)
	sts graph, by (earlysex) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival by earlysex", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aEMKenya, replace)saving(graphs/aEMKenya.gph,replace)
	sts graph, by (inunion) adjustfor (agec) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Adjusted survival by inunion", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(aUMKenya, replace)saving(graphs/aUMKenya.gph,replace)

	cd "`resultsdir'/graphs"

	graph combine "aWKMKenya.gph" "aSMKenya.gph" "aRMKenya.gph" "aPMKenya.gph" "aEMKenya.gph" "aUMKenya.gph" 
	graph save acombinedgraph, replace

	cd "`resultsdir'"
	
* Part e. logrank test for survivor function by groups and test for collinearity

	 //Log-rank test: Hypothesis that the survival curves are the same.
	sts test wealthtertile
	sts test school
	sts test residence
	sts test parity
	sts test earlysex
	sts test inunion
	sts test FQagecat


*Part f. Testing for collinearity

	xi: regress interval i.wealthtertile i.school residence parity earlysex inunion FQagecat

	estat vif	

* Part g. Fit Cox Models

	*--Undjusted models 
	svy: stcox i.wealthtertile
	svy: stcox i.school
	svy: stcox residence
	svy: stcox parity
	svy: stcox earlysex
	svy: stcox inunion
	svy: stcox FQagecat

	*--Best subsets variable selection & Fitting Final Cox Models
	
	//Best subsets variable selection
	gvselect <term>  wealthtertile school residence parity earlysex inunion FQagecat: poisson interval <term>

	*Final adjusted model 

	//Model with lowest AIC
			svy: stcox i.FQagecat earlysex i.school residence i.wealthtertile
	
	//Final model
	svy: stcox i.FQagecat earlysex i.school residence i.wealthtertile parity

	svy: stcox FQ_age earlysex i.school residence i.wealthtertile parity

	*For reference of total N by variables
	numlabel, add
	
	foreach var of varlist school inunion wealthtertile residence earlysex parity ex_info FQagecat {
	tab `var'
	}

log close
