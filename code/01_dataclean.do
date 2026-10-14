*=============================================
* 01_data_clean.do
* Replication Card & Krueger (1994) AER
* Strictly follow original paper data‑cleaning rules, no extra variables
*=============================================

* import raw csv, all variable names to lowercase
import delimited using "E:\HKU ECON\6067\01_DID\data\public.csv", clear case(lower)

* create unique store id (sheet has duplicates)
gen id = _n
label var id "Unique restaurant identifier"

* --------------------------
* Original paper rule: permanently closed stores(status2==3): set wave‑2 employment to zero
* temporarily closed(status2==2,4,5): keep missing, do NOT impute zero
* --------------------------
replace empft2 = 0 if status2 == 3
replace emppt2 = 0 if status2 == 3
replace nmgrs2 = 0 if status2 == 3

* ----------关键修复：把wave1变量重命名为xxx1，满足reshape long语法----------
rename empft empft1
rename emppt emppt1
rename nmgrs nmgrs1
rename wage_st wage_st1

* compute FTE employment in WIDE format first (per paper definition)
gen fte_w1 = empft1 + 0.5 * emppt1 + nmgrs1
gen fte_w2 = empft2 + 0.5 * emppt2 + nmgrs2
label var fte_w1 "FTE employment wave1 (pre_policy)"
label var fte_w2 "FTE employment wave2 (post_policy)"

* reshape wide → long panel，现在变量 empft1 empft2 匹配语法
reshape long empft emppt nmgrs wage_st fte_w, i(id) j(after)
label define after_lab 0 "Pre‑policy(Feb1992‑wave1)" 1 "Post‑policy(Nov1992_wave2)"
label values after after_lab
label var after "Post_policy dummy:0=pre,1=post"

* rename long‑format fte variable
rename fte_w emp
label var emp "Full_time_equivalent employment (Card_Krueger 1994)"

* treatment dummy: nj=1 New Jersey; nj=0 Pennsylvania
gen nj = (state == 1)
label var nj "New Jersey treatment dummy (1=NJ,0=PA)"

* DID interaction term
gen nj_after = nj * after
label var nj_after "DID interaction nj × after"
