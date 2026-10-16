clear all
set more off
*===============================================================================
* 1. 读入数据
*===============================================================================
import delimited "E:/HKU ECON/6067/01_DID/data/public.csv", clear

*===============================================================================
* 2. 变量构造
*===============================================================================
gen byte nj = (state == 1)

gen fte  = empft  + 0.5*emppt  + nmgrs
gen fte2 = empft2 + 0.5*emppt2 + nmgrs2
replace fte2 = 0 if status2 == 3
replace fte2 = . if inlist(status2, 0, 2, 4)

gen pct_full  = empft  / fte  * 100
gen pct_full2 = empft2 / fte2 * 100

gen price  = pentree  + pfry  + psoda
gen price2 = pentree2 + pfry2 + psoda2

gen wage_425   = (wage_st  == 4.25) * 100
gen wage_425_2 = (wage_st2 == 4.25) * 100
gen wage_505_2 = (wage_st2 == 5.05) * 100
gen bonus_pct  = bonus * 100

*===============================================================================
* 3. 结果容器
*===============================================================================
capture postclose memhold
postfile memhold str40 varname double nj_mean double nj_se        ///
         double pa_mean double pa_se double t_stat                ///
         using "temp_results.dta", replace

*===============================================================================
* 4. 两个小工具
*===============================================================================

*--- 4a. 占比型变量: ck_share "标签" "条件" ---
capture program drop ck_share
program define ck_share
    args label cond
    quietly count if nj == 1
    local t1 = r(N)
    quietly count if nj == 0
    local t2 = r(N)
    quietly count if nj == 1 & `cond'
    local n1 = r(N)
    quietly count if nj == 0 & `cond'
    local n2 = r(N)
    post memhold ("`label'") (`n1'/`t1'*100) (.) (`n2'/`t2'*100) (.) (.)
end

*--- 4b. 均值型变量: ck_row "标签" 变量名 ---
capture program drop ck_row
program define ck_row
    args label varname
    quietly ttest `varname', by(nj)
    local tstat = r(t)
    quietly summarize `varname' if nj == 1
    local m1 = r(mean)
    local s1 = r(sd) / sqrt(r(N))
    quietly summarize `varname' if nj == 0
    local m2 = r(mean)
    local s2 = r(sd) / sqrt(r(N))
    post memhold ("`label'") (`m1') (`s1') (`m2') (`s2') (`tstat')
end

*===============================================================================
* 5. 逐行填入
*===============================================================================

*---- 5.1 门店类型分布 (%) ----
ck_share "Burger King"      "chain == 1"
ck_share "KFC"              "chain == 2"
ck_share "Roy Rogers"       "chain == 3"
ck_share "Wendys"           "chain == 4"
ck_share "Company-owned"    "co_owned == 1"

*---- 5.2 第1波 (1992年2-3月) ----
ck_row "FTE employment"                  fte
ck_row "Percentage full-time employees"  pct_full
ck_row "Starting wage"                   wage_st
ck_row "Wage = 4.25 (percentage)"        wage_425
ck_row "Price of full meal"              price
ck_row "Hours open (weekday)"            hrsopen
ck_row "Recruiting bonus"                bonus_pct

*---- 5.3 第2波 (1992年11-12月) ----
ck_row "FTE employment"                  fte2
ck_row "Percentage full-time employees"  pct_full2
ck_row "Starting wage"                   wage_st2
ck_row "Wage = 4.25 (percentage)"        wage_425_2
ck_row "Wage = 5.05 (percentage)"        wage_505_2
ck_row "Price of full meal"              price2

postclose memhold

*===============================================================================
* 6. 整理并导出
*===============================================================================
use "temp_results.dta", clear

gen str30 nj_d = trim(string(nj_mean, "%9.2f"))
replace nj_d = nj_d + " (" + trim(string(nj_se, "%9.2f")) + ")" if nj_se != .
gen str30 pa_d = trim(string(pa_mean, "%9.2f"))
replace pa_d = pa_d + " (" + trim(string(pa_se, "%9.2f")) + ")" if pa_se != .

order varname nj_d pa_d t_stat
rename varname Variable
rename nj_d     NJ
rename pa_d     PA

list Variable NJ PA t_stat, clean noobs
export excel using "Table2.xlsx", firstrow(variables) replace
