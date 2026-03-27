clear all
set more off

local yr 2018

import excel "C:/Users/kyoon/OneDrive/Desktop/KCL Assessment/World Bank_ESG data_25-26.xlsx", sheet("Data") firstrow clear

foreach v of varlist _all {
    local lab : variable label `v'
    if regexm("`lab'", "^[0-9]{4}$") capture rename `v' y`lab'
}

keep CountryName CountryCode SeriesName SeriesCode y`yr'

keep if inlist(SeriesCode, ///
    "GE.EST", ///
    "EG.FEC.RNEW.ZS", ///
    "EN.ATM.CO2E.PC", ///
    "EG.USE.PCAP.KG.OE")

rename y`yr' value

gen indicator = ""
replace indicator = "ge"     if SeriesCode == "GE.EST"
replace indicator = "renew"  if SeriesCode == "EG.FEC.RNEW.ZS"
replace indicator = "co2"    if SeriesCode == "EN.ATM.CO2E.PC"
replace indicator = "energy" if SeriesCode == "EG.USE.PCAP.KG.OE"

keep CountryName CountryCode indicator value
reshape wide value, i(CountryCode CountryName) j(indicator) string

rename valuege government_effectiveness
rename valuerenew renewable_adoption
rename valueco2 co2_emissions
rename valueenergy energy_use

save "esg_`yr'_temp.dta", replace

clear
import delimited "C:/Users/kyoon/OneDrive/Desktop/KCL Assessment/API_NY.GDP.PCAP.CD_DS2_en_csv_v2_46.csv", varnames(5) clear

foreach v of varlist _all {
    local lab : variable label `v'
    if regexm("`lab'", "^[0-9]{4}$") capture rename `v' y`lab'
}

keep countryname countrycode indicatorname indicatorcode y`yr'
rename y`yr' gdp_per_capita

rename countryname CountryName
rename countrycode CountryCode

keep if indicatorcode == "NY.GDP.PCAP.CD"
drop if missing(CountryCode)

save "gdp_`yr'_temp.dta", replace

use "esg_`yr'_temp.dta", clear
merge 1:1 CountryCode using "gdp_`yr'_temp.dta"

keep if _merge == 3
drop _merge

drop if missing(government_effectiveness)
drop if missing(renewable_adoption)
drop if missing(gdp_per_capita)
drop if missing(co2_emissions)
drop if missing(energy_use)

save "clean_esg_gdp_`yr'.dta", replace
export excel using "clean_esg_gdp_`yr'.xlsx", firstrow(variables) replace

summarize renewable_adoption government_effectiveness gdp_per_capita co2_emissions energy_use
reg renewable_adoption government_effectiveness, robust
reg renewable_adoption government_effectiveness gdp_per_capita co2_emissions energy_use, robust

