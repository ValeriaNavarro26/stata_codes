
cd "..."
set more off, permanently
*===============================================================================
*Preparamos la base de datos
*===============================================================================

forvalues anio=2004/2017 {
	use "enaho01a-`anio'-500.dta", clear
	quietly destring *, replace
	quietly compress
	save "enaho01a-`anio'-500 modif.dta", replace 
}

use "enaho01a-2015-500 modif.dta", clear

quietly append using "enaho01a-2016-500 modif.dta" 
quietly append using "enaho01a-2017-500 modif.dta" 

egen temp=rowfirst(a?o)
	drop a?o
	rename temp año

egen temp=rowfirst(fac*)
	drop fac*
	rename temp factor
	
svyset [pw=factor], strata(estrato) psu(conglome)

*===============================================================================
*Variables personales
*===============================================================================
	
*Sexo
	rename p207 sexo
	
*Edad
	rename p208a edad

*Educación
	recode p301a (1=1 "Sin nivel") (2 3 4 5 6 = 2 "Escolar") (7 9 = 3 "Superior incompleta") (8 10 11 = 4 "Superior completa"), gen(educacion)         

*NSE
	merge m:1 año conglome vivienda hogar using "NSE 2004-2017.dta", keepusing(nse nse2 nse3)
		drop _merge
	rename (nse2 nse3) (clase_media nse_grupos)
keep if año>=2015

*===============================================================================
*Variables laborales
*===============================================================================

*Generamos una dummy llena de 1's
	gen dummy=1

*Corregimos ocu500
	replace ocu500=. if ocu500==0

*Separamos a los trabajadores por tipo de relacion laboral
	recode p507 (3/4=1 "Asalariado") (2=2 "Independiente") (1=3 "Empleadores o patronos") (5/7=4 "Otros") (missing=.), gen(relacion_laboral)

*Separamos a los del sector público y privado
	recode p510 (1/3=0 "Sector público") (4/7=1 "Sector privado") (missing=.), gen(privado)
	
*Sectores económicos
	rename (p506 p506r4) (ciiu_rev_3 ciiu_rev_4)
	recode ciiu_rev_3 (100/499=1 "Agropecuario") (500/999=2 "Pesca") (1030/1099 1200/1499 = 3 "Minería") (1100/1199=4 "Hidrocarburos") (1511 1512 1542 1010 1020 2320 2330 2720 = 5 "Industria primaria") (1513/1541 1543/2310 2411/2710 2731/3999 = 6 "Industria no primaria") (4000/4499=7 "Electricidad y agua") (4500/4999=8 "Construcción") (5000/5499=9 "Comercio") (5500/9999=10 "Servicios") (missing=.) if año<=2008, gen(temp1)
	recode ciiu_rev_4 (100/299=1 "Agropecuario") (300/399=2 "Pesca") (500/599 700/899 990/999 = 3 "Minería") (600/699 900/989 = 4 "Hidrocarburos") (1010 1020 1072 1920 2420 = 5 "Industria primaria") (1030/1071 1073/1910 1930/2410 2431/3399 = 6 "Industria no primaria") (3500/3999=7 "Electricidad, agua y gas natural") (4100/4399=8 "Construcción") (4500/4799=9 "Comercio") (4900/9999=10 "Servicios") if año>=2009, gen(temp2)
	egen sector=rowfirst(temp1 temp2)
		drop temp1 temp2
		label define sector 1"Agropecuario" 2"Pesca" 3"Minería" 4"Hidrocarburos" 5"Industria primaria" 6"Industria no primaria" 7"Electricidad, gas y agua" 8"Construcción" 9"Comercio" 10"Servicios"
		label values sector sector

    recode ciiu_rev_3 (100/499=1 "Agropecuario") (500/999=2 "Pesca") (1030/1099 1200/1499 1100/1199=3 "Minería e Hidrocarburos") (1511 1512 1542 1010 1020 2320 2330 2720 1513/1541 1543/2310 2411/2710 2731/3999 = 4 "Manufactura") (4000/4499=5 "Electricidad y agua") (4500/4999=6 "Construcción") (5000/5499=7 "Comercio") (5500/9999=8 "Servicios") (missing=.) if año<=2008, gen(temp3)
	recode ciiu_rev_4 (100/299=1 "Agropecuario") (300/399=2 "Pesca") (500/599 700/899 990/999 600/699 900/989 = 3 "Minería e Hidrocarbruros") (1010 1020 1072 1920 2420 1030/1071 1073/1910 1930/2410 2431/3399 = 4 "Manufactura") (3500/3999=5 "Electricidad, agua y gas natural") (4100/4399=6 "Construcción") (4500/4799=7 "Comercio") (4900/9999=8 "Servicios") if año>=2009, gen(temp4)
	egen sector_grupos=rowfirst(temp3 temp4)
		drop temp3 temp4
		label define sector_grupos 1"Agropecuario" 2"Pesca" 3"Minería e Hidrocarburos" 4"Manufactura" 5"Electricidad, gas y agua" 6"Construcción" 7"Comercio" 8"Servicios"
		label values sector_grupos sector_grupos
	
		
*Identificamos a los trabajadores que tienen contrato
	recode p511a (1 2 5 6 = 1 "Con contrato") (3 4 7 8 = 0 "Sin contrato") (missing=.), gen(trabajador_formal)

*Empresas formales (registradas en la Sunat)
	recode p510a1 (1/2=1 "Empresa formal") (3=0 "Empresa informal") (missing=.), gen(empresa_formal)

*Tamaño de empresa
	recode p512b (1=1 "Independientes") (2/10=2 "Micro") (11/50=3 "Pequeña") (51/9999=4 "Mediana y grande") (missing=.), gen(tamaño_empresa)

*Empleo formal (trabajadores asalariados del sector privado con contrato y trabajadores del sector público)
	gen empleo_formal=.
		replace empleo_formal=1 if ocu500==1 & relacion_laboral==1 & (privado==0 | (privado==1 & trabajador_formal==1))
		replace empleo_formal=0 if ocu500==1 & ((relacion_laboral==1 & privado==1 & trabajador_formal==0) | relacion_laboral==2 | relacion_laboral==3 | relacion_laboral==4)
			label define empleo_formal 0 "Trabajador informal" 1 "Trabajador formal"
			label values empleo_formal empleo_formal
   
*Ingreso mensual en la ocupación principal
		rename (p513t p523 p524a1 p530a) (horas_sem_principal frecuencia ingreso_por_pago ingreso_mensual_independiente) // todas las variables corresponden a la ocupación principal
		recode frecuencia (1=26) (2=4) (3=2) (4=1), gen(pagos_por_mes)
		replace ingreso_mensual_independiente=. if ingreso_mensual_independiente==999999  // ingreso de los independientes y empleadores
		gen ingreso_mensual=ingreso_por_pago*pagos_por_mes // solo llena el ingreso de los trabajadores dependientes
	replace ingreso_mensual=ingreso_mensual_independiente if relacion_laboral==2 | relacion_laboral==3 // completa la variable con el ingreso de los trabajadores independientes y empleadores
		label variable ingreso_mensual "Ingreso laboral mensual (ocupación principal)"
	
*Ingreso por hora
	gen ingreso_por_hora=ingreso_mensual/(horas_sem_principal*4)
		label variable ingreso_por_hora "Ingreso laboral por hora (ocupación principal)"

*Ingreso anual (asume 15 sueldos para el sector privado formal y 12 sueldos para los demás)
	gen ingreso_anual_miles=ingreso_mensual/1000*15 if empleo_formal==1 & privado==1
		replace ingreso_anual_miles=ingreso_mensual/1000*12 if !(empleo_formal==1 & privado==1)
	
*Estabilidad de ingresos (solo para trabajadores dependiente)
	recode frecuencia (1/2=0 "Inestable (ingreso diario o semanal") (3/4=1 "Estable (ingreso quincenal o mensual") (missing=.), gen(estabilidad_ingresos)
	
*Ocupación principal y secundaria
	rename (p518 p538a1 p541a) (horas_sem_secundaria ingreso_mensual_sec_dep ingreso_mensual_sec_indep)
	egen horas_sem_total=rowtotal(horas_sem_secundaria horas_sem_principal), missing
	egen ingreso_mensual_total=rowtotal(ingreso_mensual ingreso_mensual_sec_dep ingreso_mensual_sec_indep), missing
	gen ingreso_por_hora_total=ingreso_mensual_total/(horas_sem_total*4)
	
	
*===============================================================================
*Variables del entorno
*===============================================================================

label drop departamento zonas

*Urbano/rural
	recode estrato (1/5=1 "Urbano") (6/8=0 "Rural") (missing=.), gen(urbano)

*Región
	destring ubigeo, replace
	gen departamento=int(ubigeo/10000)
	label variable departamento "Departamentos"
	label define departamento 1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huanuco" 11 "Ica" 12 "Junin" 13 "La Libertad" 14 "Lambayeque" 15 "Lima" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martín" 23 "Tacna" 24 "Tumbes" 25 "Ucayali"
	label values departamento departamento

*Zonas
	gen zonas=.
	replace zonas=1 if departamento==1 | departamento==6 | departamento==13 | departamento==14 | departamento==20 | departamento== 24
	replace zonas=2 if departamento==2 | departamento==5 | departamento==9 | departamento==11 | departamento==12 | departamento==19
	replace zonas=3 if departamento==3 | departamento==4 | departamento==8 | departamento==17 | departamento==18 | departamento==21 | departamento==23
	replace zonas=4 if departamento==10 | departamento==16 | departamento==22 | departamento==25
	replace zonas=5 if departamento==7 | departamento==15
	label variable zonas "Zonas"
	label define zonas 1 "Norte" 2 "Centro" 3 "Sur" 4 "Oriente" 5 "Lima"
	label values zonas zonas

*===============================================================================

save "Financiero.dta", replace

save "G:\Estudios Economicos\PROYECTOS\PROYECTOS 2018\La Victoria Lab\Temas\7. Servicios financieros\Financiero.dta", replace
*===============================================================================
*Tablas
*===============================================================================
clear all
cd "I:\Consulta SAE\NSE - Consumidor\EE\Enaho\1. Bases"
use "Financiero.dta", clear
set more off, permanently
drop if edad<18


recode p558e1 (0=0) (1=1) (missing=.), gen (cuenta_ahorro)
recode p558e2 (0=0) (2=1) (missing=.), gen (cuenta_plazo_fijo)
recode p558e3 (0=0) (3=1) (missing=.), gen (cuenta_corriente)
recode p558e4 (0=0) (4=1) (missing=.), gen (tarjetac)
recode p558e5 (0=0) (5=1) (missing=.), gen (tarjetad)

gen cuenta=.
replace cuenta=0 if cuenta_ahorro==0 | cuenta_plazo_fijo==0 | cuenta_corriente==0
replace cuenta=1 if cuenta_ahorro==1 | cuenta_plazo_fijo==1 | cuenta_corriente==1


recode departamento (1/6 8/14 16/25=0) (7 15=1) (missing=.), gen (limaprovincias)
svyset [pw=factor], psu(conglome) strata(estrato)


svy: mean cuenta if año==2017, over (año departamento)
svy: mean tarjetad if año==2017, over (año departamento)

svy: mean cuenta if año==2017 & urbano==1, over (año departamento)
svy: mean tarjetad if año==2017 & urbano==1, over (año departamento)


svy: mean cuenta if urbano==1 & dominio==8, over (año)
svy: mean tarjetad if urbano==1 & dominio==8, over (año)
svy: mean cuenta if urbano==1 & dominio!=8, over (año)
svy: mean tarjetad if urbano==1 & dominio!=8, over (año)


svy: mean cuenta, over (año limaprovincias)
svy: mean cuenta_ahorro, over (año limaprovincias)
svy: mean cuenta_plazo_fijo, over (año limaprovincias)
svy: mean cuenta_corriente, over (año limaprovincias)
svy: mean tarjetac, over (año limaprovincias)
svy: mean tarjetad, over (año limaprovincias)

svy: mean cuenta, over (año departamento)
svy: mean cuenta_ahorro, over (año departamento)
svy: mean cuenta_plazo_fijo, over (año departamento)
svy: mean cuenta_corriente, over (año departamento)
svy: mean tarjetac, over (año departamento)
svy: mean tarjetad, over (año departamento)

svy: mean cuenta if urbano==0, over (año)
svy: mean cuenta_ahorro if urbano==0, over (año)
svy: mean cuenta_plazo_fijo if urbano==0, over (año)
svy: mean cuenta_corriente if urbano==0, over (año)
svy: mean tarjetac if urbano==0, over (año)
svy: mean tarjetad if urbano==0, over (año)

gen pers=1
svy: total pers if edad<=70, over (año)
svy: total pers if edad<=70 & cuenta!=. & tarjetac!=. & tarjetad!=., over (año)

drop if urbano==0

svy: mean cuenta, over (año)
svy: mean cuenta_ahorro, over (año)
svy: mean cuenta_plazo_fijo, over (año)
svy: mean cuenta_corriente, over (año)
svy: mean tarjetac, over (año)
svy: mean tarjetad, over (año)


*********************************************************

*gen departamento2=int(ubigeo/10000)
*replace departamento2=0 if dominio==8

*label variable departamento2 "Departamentos"
*label define departamento2 0 "Lima Metropolitana" 1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huanuco" 11 "Ica" 12 "Junin" 13 "La Libertad" 14 "Lambayeque" 15 "Lima Resto" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martín" 23 "Tacna" 24 "Tumbes" 25 "Ucayali"
*label values departamento2 departamento2
*gen persona=1
*gen grupos=privado
*replace grupos=2 if empleo_formal==0
*gen limatot=departamento2
*replace limatot=departamento
*drop departamento
*gen departamento=int(ubigeo/10000)
*label variable departamento "Departamentos"
*label define departamento1 1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huanuco" 11 "Ica" 12 "Junin" 13 "La Libertad" 14 "Lambayeque" 15 "Lima" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martín" 23 "Tacna" 24 "Tumbes" 25 "Ucayali"
*label values departamento departamento1

*General
recode sexo (1=0) (2=1) (missing=.), gen(mujer)
recode p301a (1/6=0) (7/11=1) (missing=.), gen(superior)
recode nse (1/3=1) (4/5=0) (missing=.), gen(clase_media)
recode edad (18/30=1) (30/98=0) (missing=.), gen(adulto_joven)
gen edad

*Productos Financieros



**Total
svy: mean cuenta, over (año)
svy: mean tarjetac, over (año)
svy: mean tarjetad, over (año)


**Por NSE
svy: mean cuenta, over (nse año)
svy: mean tarjetac, over (nse año)
svy: mean tarjetad, over (nse año)

**Por Tipo de empleo
svy: proportion cuenta, over (empleo_formal privado año)
svy: proportion tarjetac, over (empleo_formal privado año)
svy: proportion tarjetad, over (empleo_formal privado año)

**Por Sector de empleo
svy: proportion cuenta, over (sector_grupos año)
svy: proportion tarjetac, over (sector_grupos año)
svy: proportion tarjetad, over (sector_grupos año)

**Por Frecuencia de ingresos
svy: proportion cuenta, over (estabilidad_ingresos año)
svy: proportion tarjetac, over (estabilidad_ingresos año)
svy: proportion tarjetad, over (estabilidad_ingresos año)

svy: proportion cuenta if empleo_formal==0, over (estabilidad_ingresos año)
svy: proportion tarjetac if empleo_formal==0, over (estabilidad_ingresos año)
svy: proportion tarjetad if empleo_formal==0, over (estabilidad_ingresos año)




***Peru total

**Por NSE
svy: mean cuenta, over (nse año)
svy: mean tarjetad, over (nse año)

**Por Tipo de empleo
svy: proportion cuenta, over (empleo_formal privado año)
svy: proportion tarjetad, over (empleo_formal privado año)

**Por Sector de empleo
svy: proportion cuenta, over (sector_grupos año)
svy: proportion tarjetad, over (sector_grupos año)



***Lima metropolitana

**Por NSE
svy: mean cuenta if dominio==8, over (nse año)
svy: mean tarjetad if dominio==8, over (nse año)

**Por Tipo de empleo
svy: proportion cuenta if dominio==8, over (empleo_formal privado año)
svy: proportion tarjetad if dominio==8, over (empleo_formal privado año)

**Por Sector de empleo
svy: proportion cuenta if dominio==8, over (sector_grupos año)
svy: proportion tarjetad if dominio==8, over (sector_grupos año)






**Por Rango de ingresos
gen rangos=.
replace rangos=0 if ingreso_mensual_total<=500 
replace rangos=1 if ingreso_mensual_total>500 & ingreso_mensual_total<=1000
replace rangos=2 if ingreso_mensual_total>1000 & ingreso_mensual_total<=1500
replace rangos=3 if ingreso_mensual_total>1500 & ingreso_mensual_total<=2000
replace rangos=4 if ingreso_mensual_total>2000

svy: proportion cuenta, over (rangos año)
svy: proportion tarjetac, over (rangos año)
svy: proportion tarjetad, over (rangos año)

**Por Rango de ingresos
gen rango=.
replace rango=0 if edad<28
replace rango=1 if edad>=28 & edad<38
replace rango=2 if edad>=38 & edad<48
replace rango=3 if edad>=48 & edad<58
replace rango=4 if edad>=58

svy: proportion cuenta, over (rango año)
svy: proportion tarjetac, over (rango año)
svy: proportion tarjetad, over (rango año)

**Por Sexo
svy: proportion cuenta, over (sexo año)
svy: proportion tarjetac, over (sexo año)
svy: proportion tarjetad, over (sexo año)

*Por qué no tiene?
gen fin=.
replace fin=1 if cuenta==1 | tarjetac==1 | tarjetad==1
tab p558f fin,m
svy: proportion p558f, over (año)


svy: proportion p558f if clase_media==1, over (año)


*Ahorro
gen ahorro=.
replace ahorro=0 if p558g1==0 | p558g2==0 | p558g3==0
replace ahorro=1 if p558g1==1 | p558g2==1 | p558g3==1

*Usos

gen p=1
*Débito
forvalues a=1/12 {
svy: total p if año==2017, over (p558h`a'_2)
svy: total p if clase_media==1 & año==2017, over (p558h`a'_2)
 
	
}
*crédito
forvalues a=1/12 {
svy: proportion p558h`a'_3 if año==2017 & p558h`a'_6!=6 & urbano==1
}
*BI
forvalues a=1/12 {

svy: total p if nse_grupos==1 & año==2017, over (p558h`a'_4)
	
}
*Efectivo
forvalues a=1/12 {
svy: total persona if año==2017, over (p558h`a'_1)
svy: total persona if clase_media==1 & año==2017, over (p558h`a'_1)
 
 }

svy: total p if año==2017, over (cuenta)
svy: total p if año==2017, over (tarjetac)
svy: total p if año==2017, over (tarjetad)

svy: total p if año==2017 & clase_media==1 , over (cuenta)
svy: total p if año==2017 & clase_media==1 , over (tarjetac)
svy: total p if año==2017 & clase_media==1 , over (tarjetad)
