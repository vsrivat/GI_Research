clear all
set more off 
capture log close
set scheme s1color

*cd "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Capstone/Kenya"
cd "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Kenya"
*log using "Kenya_cph_log file_survival analysis_2", replace
log using "Kenya_cph_log file_03312019", replace

**making changes

** applying GitHub with OLIVIER

*****Analysis plan********

* Part 0. Data management
* Part a. Defining survival data; get summary statistics
* Part b. Plot Kaplan-Meier estimates of survivor function, by groups
* Part c. logrank test and Wilcoxon tests for survivor function by groups
* Part d. Fit Cox Models
* Part f. Stepwise Cox regression
* Part d. Fit Final Cox Models


* Part 0. Data management

	use "KER4_WealthWeightAll_13Jan2017", clear

	local excelfile "capstone_Kenya_JCR.xls"

	shell md graphs

	*Generating Wealth tertiles
	preserve
	keep if metatag==1
	keep if HHQ_result==1
	xtile wealthtertile=score [pw=HHweight], nq(3)
	cap label define wealthtert 1 "Lowest tertile" 2 "Middle tertile"  3 "Highest tertile"
	label value wealthtertile wealthtert 
	keep metainstanceID wealthter
	tempfile temp
	save `temp', replace

	restore


	* Generate follow-up time variable (expressed in years for convenience)

	drop if age_at_first_use<=age_at_first_sex

	*Dropping all who had sex before the age of 12
	//Age 12 by assuming that a girl can only become pregnant at 12 and above.

	drop if age_at_first_sex < 12

	gen entry=age_at_first_sex

	generate interval=age_at_first_use-age_at_first_sex if fp_ever_used==1
	
	replace interval=30-age_at_first_sex if fp_ever_used!=1
	
*	replace interval=24-age_at_first_sex if fp_ever_used!=1

	total interval 
	
******03/31/2019
	replace school=. if school==-99
	recode school 1=1 2 3 4 5 6=2 0=0
	label define school 0"Never attended" 1"Primary" 2"Secondary+",modify
	label values school school


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

x
***** 03/31/2019
	
	merge m:1 metainstanceID using `temp', nogen

	* Only using de-facto population
	gen pop=1 if usual_member!=. & usual_member!=-99

	* Use only completed HH interviews, use only 15-24 years females who have had sex. 
	keep if FRS_result==1 & HHQ==1
	drop if age < 15 | age >24 | age_at_first_sex==-99 | age_at_first_sex==-88 | age_at_first_sex==-77

	* Generate 5 years age group for female respondents
	replace FQ_age=. if FQ_age<0
	egen FQagecat=cut(FQ_age), at(15(5)25)
	label define FQagecat 15"15-19" 20"20-24" 
	label values FQagecat FQagecat

	* Generate category of highest level of education completed 
	* Post_primary_vocational & secondary asa level grouped into Secondary, college and university grouped into higher education
	replace school=. if school==-99
	recode school 1=1 2 3 4 5 6=2 0=0
	label define school 0"Never attended" 1"Primary" 2"Secondary+",modify
	label values school school

	* Generate new marital status category
	replace FQmarital_status=0 if FQmarital_status==5
	gen marital=FQmarital_status
	recode marital 0=0 1/2=1  3/4=2 -99=.
	label define marital 0"Never married" 1"Married/cohabiting" 2"Divorced/widowed" 
	label values marital marital

	* Generate future pregnancy intention for non pregnant women
	replace wait_birth=. if wait_birth==-99 | wait_birth==5 | wait_birth==-88
	recode wait_birth 1 3=0 2=1, gen (wait_birth1)

	*Generate pregnancy intention for pregnant women
	replace wait_birth_pregnant=. if wait_birth_pregnant==-99 | wait_birth_pregnant==5 | wait_birth_pregnant==-88
	replace wait_birth1=0 if wait_birth_pregnant==1 | wait_birth_pregnant==3
	replace wait_birth1=1 if wait_birth_pregnant==2
	label define wait_birth1 0"want kids in < 2 years" 1"wants kids in two or more years"
	label values wait_birth1 wait_birth1

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
	label define earlysex 0 "First sex <17 y.o" 1 "First sex >17 y.o"
	label values earlysex earlysex 

	*generate exposure to media FP information
	gen ex_info=1 if fp_ad_radio==1 | fp_ad_magazine==1 
	replace ex_info=0 if fp_ad_radio==0 | fp_ad_magazine==0
	replace ex_info=. if fp_ad_radio==-99 | fp_ad_magazine==-99
	lab def ex_info 0"FP media exposed" 1"No FP media exposure"
	lab val  ex_info ex_info

	*recode residence 
	recode ur (2=0 "rural") (1=1 "urban"), gen(residence)


* Part a. Defining survival data get summary statistics

	* Keep only completed interviews and de-facto member of household

	keep if HHQ_result==1 & FRS_result==1 & (usual_member==1 | usual_member==3)

	* By urban/rural
	tabout residence FQagecat [aw=FQweight] if (FQagecat==15 | FQagecat==20) & pop==1 using "`excelfile'", replace ///
	c(freq col row) f(0 1) clab(n % %) npos(row) ///
	h1("Youth population by urban/rural (weighted %)")

	* By education
	tabout school FQagecat[aw=FQweight] if (FQagecat==15 | FQagecat==20) & pop==1 using "`excelfile'", append ///
	c(freq col row) f(0 1) clab(n % %) npos(row) ///
	h2("Youth population by highest level of education attended (weighted %)")

	*By wealthtertile status 
	tabout wealthtertile FQagecat [aw=FQweight] if (FQagecat==15 | FQagecat==20) & pop==1 using "`excelfile'", append ///
	c(freq col row) f(0 1) clab(n % %) npos(row) ///
	h1("Youth population by wealth status(weighted %)")

	*By sexual activity

	tabout earlysex FQagecat [aw=FQweight] if (FQagecat==15 | FQagecat==20) & pop==1 using "`excelfile'", append ///
	c(freq col row) f(0 1) clab(n % %) npos(row) h1("Early sexual intercourse among 15-24 years old (weighted %)")

	*MCPR by age category
	tabout mcp FQagecat [aw=FQweight] if (FQagecat==15 | FQagecat==20) & pop==1 using "`excelfile'", append ///
	c(freq col row) f(0 1) clab(n % %) npos(row) ///
	h1("Modern Contraceptive Prevalence rate - 15-24 age group (weighted %)")

	tabout mcp FQagecat [aw=FQweight] if (FQagecat==15 | FQagecat==20 | FQagecat==25 | FQagecat==30 | FQagecat==35 | FQagecat==40 | FQagecat==45) & pop==1 using "`excelfile'", append ///
	c(freq col row) f(0 1) clab(n % %) npos(row) ///
	h1("Modern Contraceptive Prevalence rate - 15-49 age group (weighted %)")

	*set data set as survival data
	svyset EA [pw=FQweight], strata(strata) singleunit(scaled)
	*In Nigeria, change EA to Cluster in command above

	stset interval, failure(fp_ever_used==1)
	* CAN WEIGHT WITH P-WEIGHTS

	save Kenya_Fyouth.dta, replace 

	sts list if fp_ever_used==1

	sts list 

	stsum, by(fp_ever_used)
	stsum, by(wealthtertile)
	stsum, by(earlysex)
	stsum, by(residence)
	stsum, by(school)
	stsum, by(inunion)
	stsum, by(ex_info)
	


* Part b. Plot Kaplan-Meier estimates of survivor function, by groups and test the survivor and cumulative hazard functions

	*Generating boxplots by age
	sts graph, by (FQ_age) 
	sts graph, cumhaz by (FQ_age) 
	sts graph

	sts graph, by (wealthtertile) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by wealthtertile", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(WKMKenya, replace)saving(graphs/WKMKenya.gph,replace)
	sts graph, by (school) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by schooling", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(SMKenya, replace)saving(graphs/SMKenya.gph,replace)
	sts graph, by (residence) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by residence", size(small)) legend(size(small))xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(RMKenya, replace)saving(graphs/RMKenya.gph,replace)
	sts graph, by (parity) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by parity", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(PMKenya, replace)saving(graphs/PMKenya.gph,replace)
	sts graph, by (earlysex) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by earlysex", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(EMKenya, replace)saving(graphs/EMKenya.gph,replace)
	sts graph, by (inunion) legend(size(small)) ylabel(0 (0.25) 1, format(%02.1f) labsize(*.8)) xlabel(0 2.5 5 7.5 10 12.5 15 17.5,labsize(small)) legend(cols(1)) title ("Survival by inunion", size(small)) xtitle ("Time to 1st contraceptive use after 1st sex (Years)", size(small)) name(UMKenya, replace)saving(graphs/UMKenya.gph,replace)

	cd "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Capstone/Kenya/graphs"

	graph combine "WKMKenya.gph" "SMKenya.gph" "RMKenya.gph" "PMKenya.gph" "EMKenya.gph" "UMKenya.gph" 
	graph save combinedgraph, replace

	cd "/Users/jeanchristopherusatira/Dropbox (Gates Institute)/Capstone/Kenya"

	*testing for possible interractions wealthtertile*education and wealthtertile*earlysex 
	sts graph if school==0, by(wealthtertile) title ("Kenya") name(KMwealth_educationtest, replace)saving(graphs/KMwealth_noschooltest.gph,replace)
	sts graph if school==1, by(wealthtertile) title ("Kenya") name(KMwealth_educationtest, replace)saving(graphs/KMwealth_primaryschooltest.gph,replace)
	sts graph if school==2, by(wealthtertile) title ("Kenya") name(KMwealth_educationtest, replace)saving(graphs/KMwealth_secondaryschoolplus.gph,replace)
	sts graph if earlysex==0, by(wealthtertile) title ("Kenya") name(KMwealth_earlysextest, replace)saving(graphs/KMwealth_latersex.gph,replace)
	sts graph if earlysex==1, by(wealthtertile) title ("Kenya") name(KMwealth_earlysextest, replace)saving(graphs/KMwealth_earlysex.gph,replace)


* Part c. logrank test for survivor function by groups and test for collinearity

	***Log rank tests by groups
	 //Log-rank test: Hypothesis that the survival curves are the same.
	sts test wealthtertile
	sts test school
	sts test residence
	sts test parity
	sts test earlysex
	sts test inunion
	sts test ex_info

	*Testing for collinearity
	regress interval wealthtertile school residence parity earlysex ex_info inunion

	estat vif

	xi: regress interval i.wealthtertile i.school residence parity earlysex ex_info inunion

	estat vif
	
* Part d. Fit Cox Models

	*Undjusted models 
	svy: stcox i.wealthtertile
	svy: stcox i.school
	svy: stcox residence
	svy: stcox parity
	svy: stcox earlysex
	svy: stcox inunion
	svy: stcox ex_info

* Part f. Stepwise Cox regression

	* Stepwise selection

	sw stcox  wealthtertile school residence parity earlysex ex_info inunion, pr(.05)

* Part d. Fit Final Cox Models

	*Final adjusted model 

	svy: stcox i.wealthtertile i.school residence parity earlysex inunion ex_info

	svy: stcox i.wealthtertile i.school residence parity earlysex inunion

	*For reference of total N by variables
	numlabel, add
	tab wealthtertile 
	tab school 
	tab residence 
	tab parity 
	tab facility_fp_discussion 
	tab earlysex 
	tab inunion 
	tab ex_info  

log close
