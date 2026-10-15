
*---- 5.1 真实效应 (模型 (ii) 口径) ----
reg delta_emp nj chain_kfc chain_royrogers chain_wendys co_owned if sample_t4 == 1
scalar real_b  = _b[nj]
scalar real_se = _se[nj]
scalar real_t  = _b[nj] / _se[nj]

*---- 5.2 随机化推断 ----
local reps = 500

preserve
    keep if sample_t4 == 1

    * 真实处理组比例, 让随机分配与真实设计可比
    quietly summarize nj
    local prop = r(mean)


    tempname mem
    tempfile placebo
    postfile `mem' double b_fake using `placebo', replace

    gen byte fake = 0
    set seed 2024

    forvalues i = 1/`reps' {
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
