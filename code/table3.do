*==============================================================================
* Replication of Card & Krueger (1994, AER) Table 3
* Average Employment per Store Before and After the Rise
* in New Jersey Minimum Wage
* Data: public.csv
*==============================================================================
* 1. 读入数据
*===============================================================================
import delimited "E:/HKU ECON/6067/01_DID/data/public.csv", clear
gen flag_delete = (missing(empft) | missing(emppt) | missing(nmgrs))
tab flag_delete

*---- 2. Generate variables ---------------------------------------------------
* FTE employment for both waves
gen fte1 = empft  + 0.5*emppt  + nmgrs
gen fte2 = empft2 + 0.5*emppt2 + nmgrs2

* Six permanently closed stores (STATUS2==3): set wave-2 employment to 0
replace fte2 = 0 if status2==3

* State and wage group
gen nj  = (state==1)
gen grp = 0
replace grp = 1 if nj & wage_st==4.25
replace grp = 2 if nj & wage_st>4.25 & wage_st<5.00
replace grp = 3 if nj & wage_st>=5.00

* Balanced-sample change
gen diff = fte2 - fte1

* Row 5: four temporarily closed stores get wave-2 employment = 0
gen fte2b = fte2
replace fte2b = 0 if status2==2 | status2==4 | status2==5
gen diff5 = fte2b - fte1

*---- 3. Program to compute mean and SE for a given row and subsample --------
capture program drop getrow
program define getrow
    args row sel
    if `row'==1 {
        quietly summarize fte1 if `sel', detail
        scalar mval  = r(mean)
        scalar seval = r(sd)/sqrt(r(N))
    }
    else if `row'==2 {
        quietly summarize fte2 if `sel', detail
        scalar mval  = r(mean)
        scalar seval = r(sd)/sqrt(r(N))
    }
    else if `row'==3 {
        quietly summarize fte1 if `sel', detail
        scalar m1 = r(mean)
        scalar s1 = r(sd)/sqrt(r(N))
        quietly summarize fte2 if `sel', detail
        scalar m2 = r(mean)
        scalar s2 = r(sd)/sqrt(r(N))
        scalar mval  = m2 - m1
        scalar seval = sqrt(s1^2 + s2^2)
    }
    else if `row'==4 {
        quietly summarize diff if `sel', detail
        scalar mval  = r(mean)
        scalar seval = r(sd)/sqrt(r(N))
    }
    else {
        quietly summarize diff5 if `sel', detail
        scalar mval  = r(mean)
        scalar seval = r(sd)/sqrt(r(N))
    }
end

*---- 4. Fill matrices B and SE ----------------------------------------------
matrix B  = J(5,8,.)
matrix SE = J(5,8,.)

forvalues r = 1/5 {

    * Column 1: PA
    getrow `r' "state==0"
    matrix B[`r',1]  = mval
    matrix SE[`r',1] = seval

    * Column 2: NJ
    getrow `r' "state==1"
    matrix B[`r',2]  = mval
    matrix SE[`r',2] = seval

    * Column 4: NJ, starting wage = 4.25
    getrow `r' "grp==1"
    matrix B[`r',4]  = mval
    matrix SE[`r',4] = seval

    * Column 5: NJ, starting wage 4.26-4.99
    getrow `r' "grp==2"
    matrix B[`r',5]  = mval
    matrix SE[`r',5] = seval

    * Column 6: NJ, starting wage >= 5.00
    getrow `r' "grp==3"
    matrix B[`r',6]  = mval
    matrix SE[`r',6] = seval

    * Column 3: NJ - PA
    matrix B[`r',3]  = B[`r',2] - B[`r',1]
    matrix SE[`r',3] = sqrt(SE[`r',2]^2 + SE[`r',1]^2)

    * Column 7: low - high
    matrix B[`r',7]  = B[`r',4] - B[`r',6]
    matrix SE[`r',7] = sqrt(SE[`r',4]^2 + SE[`r',6]^2)

    * Column 8: midrange - high
    matrix B[`r',8]  = B[`r',5] - B[`r',6]
    matrix SE[`r',8] = sqrt(SE[`r',5]^2 + SE[`r',6]^2)
}

* Optional check
matrix list B
matrix list SE

*---- 5. Build strings for putdocx -------------------------------------------
forvalues r = 1/5 {
    forvalues c = 1/8 {
        local b = B[`r',`c']
        local s = SE[`r',`c']
        if missing(`b') {
            local cell`r'_`c' = "."
        }
        else {
            local cell`r'_`c' = string(`b',"%6.2f") + " (" + string(`s',"%5.2f") + ")"
        }
    }
}

*---- 6. Export to Word -------------------------------------------------------
putdocx clear
putdocx begin

putdocx paragraph, halign(center)
putdocx text ("Table 3 - Average Employment per Store Before and After "), bold
putdocx text ("the Rise in New Jersey Minimum Wage"), bold

putdocx paragraph, halign(center)
putdocx text ("(Standard errors in parentheses; FTE = EMPFT + 0.5*EMPPT + NMGRS)")

putdocx table tab1 = (6,9)
putdocx table tab1(1,1) = ("Variable")
putdocx table tab1(1,2) = ("PA")
putdocx table tab1(1,3) = ("NJ")
putdocx table tab1(1,4) = ("Difference NJ-PA")
putdocx table tab1(1,5) = ("Wage=$4.25")
putdocx table tab1(1,6) = ("Wage=$4.26-$4.99")
putdocx table tab1(1,7) = ("Wage>=$5.00")
putdocx table tab1(1,8) = ("Low-high")
putdocx table tab1(1,9) = ("Midrange-high")

putdocx table tab1(2,1) = ("1. FTE employment before, all available observations")
putdocx table tab1(2,2) = ("`cell1_1'")
putdocx table tab1(2,3) = ("`cell1_2'")
putdocx table tab1(2,4) = ("`cell1_3'")
putdocx table tab1(2,5) = ("`cell1_4'")
putdocx table tab1(2,6) = ("`cell1_5'")
putdocx table tab1(2,7) = ("`cell1_6'")
putdocx table tab1(2,8) = ("`cell1_7'")
putdocx table tab1(2,9) = ("`cell1_8'")

putdocx table tab1(3,1) = ("2. FTE employment after, all available observations")
putdocx table tab1(3,2) = ("`cell2_1'")
putdocx table tab1(3,3) = ("`cell2_2'")
putdocx table tab1(3,4) = ("`cell2_3'")
putdocx table tab1(3,5) = ("`cell2_4'")
putdocx table tab1(3,6) = ("`cell2_5'")
putdocx table tab1(3,7) = ("`cell2_6'")
putdocx table tab1(3,8) = ("`cell2_7'")
putdocx table tab1(3,9) = ("`cell2_8'")

putdocx table tab1(4,1) = ("3. Change in mean FTE employment")
putdocx table tab1(4,2) = ("`cell3_1'")
putdocx table tab1(4,3) = ("`cell3_2'")
putdocx table tab1(4,4) = ("`cell3_3'")
putdocx table tab1(4,5) = ("`cell3_4'")
putdocx table tab1(4,6) = ("`cell3_5'")
putdocx table tab1(4,7) = ("`cell3_6'")
putdocx table tab1(4,8) = ("`cell3_7'")
putdocx table tab1(4,9) = ("`cell3_8'")

putdocx table tab1(5,1) = ("4. Change in mean FTE employment, balanced sample of stores")
putdocx table tab1(5,2) = ("`cell4_1'")
putdocx table tab1(5,3) = ("`cell4_2'")
putdocx table tab1(5,4) = ("`cell4_3'")
putdocx table tab1(5,5) = ("`cell4_4'")
putdocx table tab1(5,6) = ("`cell4_5'")
putdocx table tab1(5,7) = ("`cell4_6'")
putdocx table tab1(5,8) = ("`cell4_7'")
putdocx table tab1(5,9) = ("`cell4_8'")

putdocx table tab1(6,1) = ("5. Change in mean FTE employment, setting FTE at temporarily closed stores to 0")
putdocx table tab1(6,2) = ("`cell5_1'")
putdocx table tab1(6,3) = ("`cell5_2'")
putdocx table tab1(6,4) = ("`cell5_3'")
putdocx table tab1(6,5) = ("`cell5_4'")
putdocx table tab1(6,6) = ("`cell5_5'")
putdocx table tab1(6,7) = ("`cell5_6'")
putdocx table tab1(6,8) = ("`cell5_7'")
putdocx table tab1(6,9) = ("`cell5_8'")


putdocx paragraph
putdocx text ("Notes: Standard errors are shown in parentheses. "), italic
putdocx text ("FTE (full-time-equivalent) employment counts each part-time worker "), italic
putdocx text ("as half a full-time worker, plus managers (NMGRS). Employment at six "), italic
putdocx text ("closed stores is set to zero; employment at four temporarily closed "), italic
putdocx text ("stores is treated as missing (set to zero only in row 5)."), italic
putdocx paragraph
putdocx text ("Stores in New Jersey were classified by starting wage in wave 1: "), italic
putdocx text ("$4.25 per hour, $4.26-$4.99 per hour, or $5.00 per hour or higher."), italic

putdocx save "Table3.docx", replace