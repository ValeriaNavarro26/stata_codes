clear all
cd "..."

use "enaho01a-2019-300.dta", clear
	drop a?o
	gen año=2019
	save "enaho01a-2019-300.dta", replace


clear all
cd "..."

use "enaho01a-2019-500.dta", clear

	drop a?o
	gen año=2019
	save "enaho01a-2019-500.dta", replace
	
merge 1:1 año conglome vivienda hogar codperso using "enaho01a-2019-300.dta"
	
	
*Sexo
	rename p207 sexo
	
*Edad
	rename p208a edad

egen temp=rowfirst(fac*)
	drop fac*
	rename temp factor
svyset [pw=factor], strata(estrato) psu(conglome)

rename p306 matriculado
rename p307 asiste

gen dummy=1
recode edad (15/25=1 "15 a 25 años") (26/35=2 "26 a 35 años") (36/45=3 "36 a 45 años") (46/60=4 "46 a 60 años") (61/max=5 "60 a más años") (missing=.), gen(grupos_edad1)


replace ocu500=. if ocu500==0

	
svy: total dummy if ocu500!=1 & asiste!=1 & grupos_edad1==1
