* Descarga la base enaho, modulo laboral, trimestral
clear all
set more off, permanently
set matsize 1000
cd "..."

use "2012-I.dta", clear
	quietly append using "2012-II.dta"
	quietly append using "2012-III.dta"
	quietly append using "2012-IV.dta"
	quietly append using "2013-I.dta"
	quietly append using "2013-II.dta"
	quietly append using "2013-III.dta"
	quietly append using "2013-IV.dta"
	quietly append using "2014-I.dta"
	quietly append using "2014-II.dta"
	quietly append using "2014-III.dta"
	quietly append using "2014-IV.dta"
	quietly append using "2015-I.dta"
	quietly append using "2015-II.dta"
	quietly append using "2015-III.dta"
	quietly append using "2015-IV.dta"
	quietly append using "2016-I.dta"
	quietly append using "2016-II.dta"
	quietly append using "2016-III.dta"
	quietly append using "2016-IV.dta"
	quietly append using "2017-I.dta"
	quietly append using "2017-II.dta"
	quietly append using "2017-III.dta"
	quietly append using "2017-IV.dta"
	quietly append using "2018-I.dta"
	quietly append using "2018-II.dta"
	quietly append using "2018-III.dta"
	quietly append using "2018-IV.dta"
	quietly append using "2019-I.dta"
	quietly append using "2019-II.dta"

quietly destring *, replace
	
egen factor=rowfirst(fac*)
svyset [pw=factor], psu(conglome) strata(estrato) 

egen temp=rowfirst(a?o)
	drop a?o
	rename temp año
recode mes (1/3=1) (4/6=2) (7/9=3) (10/12=4), gen(trimestre)
gen periodo=yq(año,trimestre)
	format period %tq


*===============================================================================
*ENTORNO
*===============================================================================

*Generamos la división urbano/rural
recode estrato (1/5=1 "Urbano") (6/8=0 "Rural") (missing=.), gen(urbano)

*Región
destring ubigeo, replace
gen departamento=int(ubigeo/10000)
label variable departamento "Departamentos"
label define departamento 1 "Amazonas" 2 "Áncash" 3 "Apurímac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huánuco" 11 "Ica" 12 "Junín" 13 "La Libertad" 14 "Lambayeque" 15 "Lima" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martín" 23 "Tacna" 24 "Tumbes" 25 "Ucayali"
label values departamento departamento

*Zonas
gen zonas=.
replace zonas=1 if departamento==1 | departamento==6 | departamento==13 | departamento==14 | departamento==20 | departamento== 24
replace zonas=2 if departamento==2 | departamento==5 | departamento==7 | departamento==9 | departamento==11 | departamento==12 | departamento==19
replace zonas=3 if departamento==3 | departamento==4 | departamento==8 | departamento==17 | departamento==18 | departamento==21 | departamento==23
replace zonas=4 if departamento==10 | departamento==16 | departamento==22 | departamento==25
replace zonas=5 if departamento==15
label variable zonas "Regiones"
label define zonas 1 "Norte" 2 "Centro" 3 "Sur" 4 "Oriente" 5 "Lima"
label values zonas zonas


*===============================================================================
*EMPLEO
*===============================================================================
*Generamos una dummy llena de 1's
gen dummy=1

*Corregimos ocu500
replace ocu500=. if ocu500==0

*Separamos a los trabajadores por tipo de relacion laboral
recode p507 (3/4=1 "Asalariado") (2=2 "Independiente") (1=3 "Empleadores o patronos") (5/7=4 "Otros") (missing=.), gen(relacion_laboral)

*Separamos a los del sector público y privado
recode p510 (1/3=0 "Sector público") (4/7=1 "Sector privado") (missing=.), gen(privado)

*Identificamos a los trabajadores que tienen contrato
recode p511a (1 2 5 6 = 1 "Con contrato") (3 4 7 8 = 0 "Sin contrato") (missing=.), gen(trabajador_formal)

*Empleo formal (trabajadores dependientes del sector privado con contrato y trabajadores del sector público)
gen empleo_formal=.
replace empleo_formal=1 if ocu500==1 & relacion_laboral==1 & (privado==0 | (privado==1 & trabajador_formal==1))
replace empleo_formal=0 if ocu500==1 & ((relacion_laboral==1 & privado==1 & trabajador_formal==0) | relacion_laboral==2 | relacion_laboral==3 | relacion_laboral==4)
	label define empleo_formal 0 "Trabajador informal" 1 "Trabajador formal"
	label values empleo_formal empleo_formal

*Sectores económicos
	rename p506r4 ciiu_rev4
	recode ciiu_rev4 (100/299=1 "Agropecuario") (300/399=2 "Pesca") (500/599 700/999=3 "Minería") (600/699=4 "Hidrocarburos") (1000/3399=5 "Manufactura") (3500/3999=6 "Electricidad, gas y agua") (4100/4399=7 "Construcción") (4500/4799=8 "Comercio") (4900/9999=9 "Servicios"), gen(sector)

*===============================================================================
*INGRESOS Y MASA SALARIAL
*===============================================================================
rename (p523 p524a1 p530a) (frecuencia ingreso_por_pago ingreso_mensual_independiente) // todas las variables corresponden a la ocupación principal
recode frecuencia (1=26) (2=4) (3=2) (4=1), gen(pagos_por_mes)
replace ingreso_mensual_independiente=. if ingreso_mensual_independiente==999999  // ingreso de los independientes y empleadores

gen ingreso_mensual=ingreso_por_pago*pagos_por_mes // solo llena el ingreso de los trabajadores dependientes
replace ingreso_mensual=ingreso_mensual_independiente if relacion_laboral==2 | relacion_laboral==3 // completa la variable con el ingreso de los trabajadores independientes, empleadores y patronos
	label variable ingreso_mensual "Ingreso laboral mensual (ocupación principal)"

gen ingreso_trimestral_miles=ingreso_mensual*3/1000
	
*===============================================================================
*TABLAS
*===============================================================================

log using "Resultados_masa_salarial.log", replace text
	svy: total ingreso_trimestral_miles if urbano==1 & ocu500==1 & año>=2016, cformat(%9,0f) over(periodo departamento)
	table departamento periodo [pw=factor] if urbano==1 & ocu500==1 & año>=2016, c(sum ingreso_trimestral_miles) format(%9,0f)
log close

*svy: total dummy if urbano==1 & ocu500!=4 & !missing(ocu500), over(periodo) cformat(%8,0f)
*svy: total dummy if urbano==1 & privado==1 & empleo_formal==1, over(periodo) cformat(%8,0f)




*** FAL: INFORMALIDAD

svy: proportion empleo_formal, over (año trimestre) cformat(%9,3f) 
svy: proportion empleo_formal if sector==1, over (año trimestre) cformat(%9,3f) 
svy: proportion empleo_formal if sector==2, over (año trimestre) cformat(%9,3f) 
svy: proportion empleo_formal if sector==3, over (año trimestre) cformat(%9,3f) 



