*导入csv数据
import delimited "public.csv", clear

* 剔除employment information缺失：EMPFT、EMPPT、NMGRS任意一个缺失就删除该行
drop if missing(empft) | missing(emppt) | missing(nmgrs)

* 查看清洗后样本量
count
