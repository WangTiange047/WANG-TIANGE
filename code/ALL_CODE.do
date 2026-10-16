**TABLE 2

clear all
set more off
*===============================================================================
* 1. 读入数据
*===============================================================================
import delimited "D:/public.csv", clear

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

**TABLE 3
*==============================================================================
* 1. 读入数据
*===============================================================================
import delimited "D:/public.csv", clear
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


**TABLE 4
*===============================================================================
* 1. 读入数据
*===============================================================================
import delimited "D:/public.csv", clear
rename *, lower

*===============================================================================
* 2. 变量构造
*===============================================================================

*---- 2.1 就业 (FTE) 与就业变化 ----
gen fte_before = empft  + 0.5*emppt  + nmgrs
gen fte_after  = empft2 + 0.5*emppt2 + nmgrs2

*     永久关闭店(STATUS2==3) -> 第2波就业记为 0
*     临时关闭/拒访店        -> 第2波就业记为缺失
replace fte_after = 0 if status2 == 3
replace fte_after = . if inlist(status2, 0, 2, 4)

gen delta_emp = fte_after - fte_before

*---- 2.2 New Jersey dummy ----
gen byte nj = (state == 1)

*---- 2.3初始工资缺口 (GAP) ----
*     论文定义 (脚注 a):
*       - PA 店                       -> gap = 0
*       - NJ 店 且 wage_st >= 5.05    -> gap = 0
*       - NJ 店 且 wage_st <  5.05    -> gap = (5.05 - wage_st) / wage_st
*     注意: 分子是 5.05, 不是 4.25
gen wage_gap = 0
replace wage_gap = (5.05 - wage_st) / wage_st ///
    if state == 1 & wage_st < 5.05 & !missing(wage_st)

*---- 2.4 连锁 dummy (基准组 Burger King=1) ----
gen byte chain_kfc       = (chain == 2)
gen byte chain_royrogers = (chain == 3)
gen byte chain_wendys    = (chain == 4)

*---- 2.5 公司直营 dummy ----
* co_owned 已经是 0/1, 直接用

*---- 2.6 Table 4 子样本 (脚注 a: N = 357) ----
*     两波就业 + 第1波工资都非缺失
*     永久关闭店的第2波工资允许缺失 (但已置 fte_after=0 入选)
gen byte sample_t4 = !missing(fte_before, fte_after, wage_st)
replace sample_t4 = 0 if missing(fte_before, fte_after, wage_st)
replace sample_t4 = 1 if sample_t4 == 0 & !missing(fte_before) & !missing(wage_st) ///
                         & status2 == 3

display "Table 4 样本 N = " %3.0f sample_t4  " (论文 357)"

*===============================================================================
* 3. 五个回归
*===============================================================================

*---- (i)  NJ dummy only ----
reg delta_emp nj if sample_t4 == 1

*---- (ii) NJ + chain & ownership controls ----
reg delta_emp nj chain_kfc chain_royrogers chain_wendys co_owned if sample_t4 == 1

*---- (iii) Initial wage gap only ----
reg delta_emp wage_gap if sample_t4 == 1

*---- (iv) Initial wage gap + chain & ownership ----
reg delta_emp wage_gap chain_kfc chain_royrogers chain_wendys co_owned if sample_t4 == 1

*---- (v) Initial wage gap + chain & ownership + region controls ----
*     区域变量直接用 southj / centralj / pa1 / pa2 本身 (它们已是 0/1)
*     基准组: NJ 北部 (northj) + PA 其他地区, 与论文 "2个NJ区域 + 2个PA区域" 一致
*     注: 不含 shore, 论文(v) 也没加
reg delta_emp wage_gap chain_kfc chain_royrogers chain_wendys co_owned ///
    southj i.pa1 pa2 if sample_t4 == 1

*===============================================================================
* 4. 导出到 Word (RTF)
*===============================================================================
* 若未安装 estout:  ssc install estout

eststo clear
eststo m1: reg delta_emp nj if sample_t4 == 1
eststo m2: reg delta_emp nj chain_kfc chain_royrogers chain_wendys co_owned if sample_t4 == 1
eststo m3: reg delta_emp wage_gap if sample_t4 == 1
eststo m4: reg delta_emp wage_gap chain_kfc chain_royrogers chain_wendys co_owned if sample_t4 == 1
eststo m5: reg delta_emp wage_gap chain_kfc chain_royrogers chain_wendys co_owned ///
              southj i.pa1 pa2 if sample_t4 == 1

* 把 3 个 chain dummy 合在一起显示
esttab m1 m2 m3 m4 m5 using "Table4_Reduced_Form.rtf", replace ///
    b(%9.2f) se(%9.2f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 4 -- Reduced-Form Models for Change in Employment") ///
    mtitles("(i)" "(ii)" "(iii)" "(iv)" "(v)") ///
    keep(nj wage_gap chain_kfc chain_royrogers chain_wendys co_owned) ///
    order(nj wage_gap chain_kfc chain_royrogers chain_wendys co_owned) ///
    stats(N r2 rmse, labels("Observations" "R-squared" "Std. error of regression")) ///
    nogaps

	
**PLACEBO TEST
*---- 5.1 真实效应 (模型 (ii) 口径) ----
reg delta_emp nj chain_kfc chain_royrogers chain_wendys co_owned if sample_t4 == 1
scalar real_b  = _b[nj]
scalar real_se = _se[nj]
scalar real_t  = _b[nj] / _se[nj]

display _n "================================================================"
display "  真实效应 (模型 (ii))"
display "================================================================"
display "NJ 系数  = " %6.3f real_b
display "标准误   = " %6.3f real_se
display "t 值     = " %5.2f real_t
display "样本量 N = " e(N)
display ""
display "注: t = " %5.2f real_t " < 1.96, 效应本身不显著 -- 这是论文的真实结论。"
display "    安慰剂检验问的是另一个问题: 真实系数是否偏离随机分配的零分布。"

*---- 5.2 随机化推断 ----
local reps = 500

preserve
    keep if sample_t4 == 1

    * 真实处理组比例, 让随机分配与真实设计可比
    quietly summarize nj
    local prop = r(mean)

    display _n "================================================================"
    display "  安慰剂检验: `reps' 次随机分配"
    display "  N = " _N "    假处理组比例 = " %4.3f `prop'
    display "================================================================"

    tempname mem
    tempfile placebo
    postfile `mem' double b_fake using `placebo', replace

    gen byte fake = 0
    set seed 2024

    forvalues i = 1/`reps' {
        * 随机指定与真实比例相同的门店为假处理组
        replace fake = (runiform() < `prop')
        quietly reg delta_emp fake chain_kfc chain_royrogers chain_wendys co_owned
        post `mem' (_b[fake])
    }
    postclose `mem'

    use `placebo', clear

    * 经验 p 值 = |假系数| >= |真实 NJ 系数| 的比例
    quietly count if abs(b_fake) >= abs(real_b)
    scalar p_placebo = r(N) / `reps'

    quietly summarize b_fake
    scalar fake_mean = r(mean)
    scalar fake_sd   = r(sd)

    save "placebo_distribution.dta", replace

    display ""
    display "假系数分布: 均值 = " %6.3f fake_mean "   标准差 = " %6.3f fake_sd
    display "真实 NJ 系数:       " %6.3f real_b
    display "经验 p 值:         " %5.3f p_placebo
    display ""
    if p_placebo < 0.05 {
        display ">> p < 0.05: 真实系数落在随机分布的尾部, 效应不太可能只是噪音。"
    }
    else {
        display ">> p >= 0.05: 真实系数未明显偏离随机分布。"
    }

    *---- 5.3 画图: 假系数分布 + 真实系数位置 ----
    local rb = string(real_b,    "%6.3f")
    local pp = string(p_placebo, "%5.3f")

    twoway (histogram b_fake, bin(40) fcolor(gs14) lcolor(black))           ///
           , xline(`rb', lcolor(red) lwidth(medthick))                      ///
             xtitle("Placebo Coefficient (random treatment assignment)")    ///
             ytitle("Frequency")                                           ///
             title("Placebo Test: `reps' Random Assignments")              ///
             note("Red line = actual NJ coefficient (`rb'); empirical p = `pp'")

    graph export "placebo_test.png", replace width(1600)
    graph export "placebo_test.pdf", replace
restore


	
**FIGURE 1
clear all
set more off

*---- 1. Import data ----------------------------------------------------------
import delimited "D:/public.csv", clear

*---- 2. Prepare wage variables ----------------------------------------------
gen nj = (state == 1)
label define njlab 0 "Pennsylvania" 1 "New Jersey"
label values nj njlab

* Keep only wages inside 4.25-5.55
gen wage1 = wage_st  if wage_st  != . & wage_st  >= 4.25 & wage_st  <= 5.55
gen wage2 = wage_st2 if wage_st2 != . & wage_st2 >= 4.25 & wage_st2 <= 5.55

*---- 3. Collapse to bins ----------------------------------------------------
* Bin midpoints for x-axis: 4.30, 4.40, ..., 5.50
* (each bin covers [4.25,4.35), [4.35,4.45), ...)
gen bin1 = floor((wage1 - 4.25) / 0.10) * 0.10 + 4.30
gen bin2 = floor((wage2 - 4.25) / 0.10) * 0.10 + 4.30

* Store totals for each wave & group
preserve
    keep if wage1 != .
    contract nj bin1
    bysort nj: egen tot1 = total(_freq)
    gen pct1 = 100 * _freq / tot1
    keep nj bin1 pct1
    rename bin1 bin
    tempfile w1
    save `w1'
restore

preserve
    keep if wage2 != .
    contract nj bin2
    bysort nj: egen tot2 = total(_freq)
    gen pct2 = 100 * _freq / tot2
    keep nj bin2 pct2
    rename bin2 bin
    tempfile w2
    save `w2'
restore

*---- 4. Figure 1a: February 1992 --------------------------------------------
use `w1', clear

* Offset PA to the left, NJ to the right
gen x_pa = bin - 0.02 if nj == 0
gen x_nj = bin + 0.02 if nj == 1

twoway ///
    (bar pct1 x_pa if nj == 0, barwidth(0.04) color(gs12) lcolor(black)) ///
    (bar pct1 x_nj if nj == 1, barwidth(0.04) color(black) lcolor(black)), ///
    legend(order(1 "Pennsylvania" 2 "New Jersey") rows(1) position(6)) ///
    xtitle("Wage Range") ytitle("Percent of Stores") ///
    xlabel(4.30(0.10)5.50, angle(45) labsize(small)) ///
    ylabel(0(5)35) ///
    title("February 1992") ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(fig1a, replace)

*---- 5. Figure 1b: November 1992 --------------------------------------------
use `w2', clear

gen x_pa = bin - 0.02 if nj == 0
gen x_nj = bin + 0.02 if nj == 1

twoway ///
    (bar pct2 x_pa if nj == 0, barwidth(0.04) color(gs12) lcolor(black)) ///
    (bar pct2 x_nj if nj == 1, barwidth(0.04) color(black) lcolor(black)), ///
    legend(order(1 "Pennsylvania" 2 "New Jersey") rows(1) position(6)) ///
    xtitle("Wage Range") ytitle("Percent of Stores") ///
    xlabel(4.30(0.10)5.50, angle(45) labsize(small)) ///
    ylabel(0(10)90) ///
    title("November 1992") ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(fig1b, replace)

*---- 6. Combine both panels -------------------------------------------------
graph combine fig1a fig1b, ///
    rows(2) ///
    graphregion(color(white)) ///
    title("Figure 1. Distribution of Starting Wage Rates", size(medium))

graph export "Figure1.png", replace width(2000)

