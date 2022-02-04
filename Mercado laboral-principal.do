clear all

*==========
*Directorio
*===========
cd "..." 

*===============================================================================
*Preparamos la base de datos
*===============================================================================

* Paso 1: Descarga las bases de Enaho, módulo 5 y guardalas en una carpeta llamada "Originales"
* Paso 2: crea una carpeta llamada "Modifcadas" aqui se almacenaran las bases para trabajar
forvalues anio=2004/2019 {
	use "Originales\enaho01-`anio'-500.dta", clear
	quietly destring *, replace
	quietly compress
	drop i* d5* t* z5* p544* p556* p557* p558* p559* p59f* p560*
	save "Modificadas\Empleo `anio'.dta", replace
}

use "Modificadas\Empleo 2004.dta", clear
	quietly append using "Modificadas\Empleo 2005.dta"
	quietly append using "Modificadas\Empleo 2006.dta"
	quietly append using "Modificadas\Empleo 2007.dta"
	quietly append using "Modificadas\Empleo 2008.dta"
	quietly append using "Modificadas\Empleo 2009.dta"
	quietly append using "Modificadas\Empleo 2010.dta"
	quietly append using "Modificadas\Empleo 2011.dta"
	quietly append using "Modificadas\Empleo 2012.dta"
	quietly append using "Modificadas\Empleo 2013.dta"
	quietly append using "Modificadas\Empleo 2014.dta"
	quietly append using "Modificadas\Empleo 2015.dta"
	quietly append using "Modificadas\Empleo 2016.dta"
	quietly append using "Modificadas\Empleo 2017.dta"
	quietly append using "Modificadas\Empleo 2018.dta"
        quietly append using "Modificadas\Empleo 2019.dta"

set more off, permanently

egen temp=rowfirst(a?o)
	drop a?o
	rename temp año

egen temp=rowfirst(fac*)
	drop fac*
	rename temp factor
	


*===============================================================================
*Variables personales
*===============================================================================
	
*Sexo
	rename p207 sexo
	
*Edad
	rename p208a edad

*Educación
	recode p301a (1=1 "Sin nivel") (2 3 4 5 6 = 2 "Escolar") (7 9 = 3 "Superior incompleta") (8 10 11 = 4 "Superior completa"), gen(educacion)         
	recode p301a (2 3=1 "Inicial") (4 5=2 "Primaria") (6 7 9=3 "Secundaria") (8 10 11 = 4 "Superior") (12 = 0) (99=.), gen(educ_2)
	
*NSE
merge m:1 año conglome vivienda hogar using "I:\Consulta SAE\NSE - Consumidor\EE\Enaho\1. Bases\NSE 2004-2019.dta", keepusing(nse nse2 nse3)
drop _merge
rename (nse2 nse3) (clase_media nse_grupos)

*Tipo de contrato
	recode p511a (1 2 = 1 "Plazo fijo") (3 4 5 6 7 8 = 2 "Plazo indeterminado"), gen(tipo_contrato)

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
	recode p512b (1=1 "Independientes") (2/10=2 "Micro") (11/50=3 "Pequeña") (51/100=4 "Mediana") (101/9999=5 "Grande")(missing=.), gen(tamaño_empresa)

*Empleo formal (trabajadores asalariados del sector privado con contrato y trabajadores del sector público)
	gen empleo_formal=.
		replace empleo_formal=1 if ocu500==1 & relacion_laboral==1 & ((privado==0 & trabajador_formal==1) | (privado==1 & trabajador_formal==1))
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

*label drop departamento zonas

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
keep conglome-estrato ocu500 sexo edad año-zonas horas_sem_principal frecuencia ingreso_por_pago ingreso_mensual_independiente pagos_por_mes horas_sem_secundaria ingreso_mensual_sec_dep ingreso_mensual_sec_indep ocupinf ciiu_rev_3 ciiu_rev_4 educ_2 p511a tipo_contrato
save "Empleo 2004-2018.dta", replace

*===============================================================================
*Tablas
*===============================================================================
clear all
cd "I:\Consulta SAE\Empleo\EE\Enaho\Bases"
use "Empleo 2004-2019.dta", clear
set more off, permanently
svyset [pw=factor], strata(estrato) psu(conglome)
*********************************************************
*Composición de la PEA urbana
	svy: total dummy if ocu500==1, over(urbano año) cformat(%9,0f)
	svy: proportion relacion_laboral if urbano==1 & dominio==8 & ocu500==1, over(año) cformat(%9,8f)
	svy: proportion privado if urbano==1 & ocu500==1 & relacion_laboral==1, over(año) cformat(%9,8f)
	svy: proportion empleo_formal if urbano==1 & ocu500==1 & relacion_laboral==1 & privado==1, over(año) cformat(%9,8f)
	
*Ingreso promedio mensual
	svy: mean ingreso_mensual if ocu500==1 & año==2017, over(educacion) cformat(%9,4f)
	svy: mean ingreso_mensual if urbano==1 & ocu500==1, over(año) cformat(%9,4f)
	svy: mean ingreso_mensual if urbano==1 & ocu500==1, over(año relacion_laboral) cformat(%9,4f)
	svy: mean ingreso_mensual if urbano==1 & ocu500==1 & relacion_laboral==1, over(año privado) cformat(%9,4f)
	svy: mean ingreso_mensual if urbano==1 & ocu500==1 & relacion_laboral==1 & privado==1, over(año empleo_formal) cformat(%9,4f)
	
	svy: mean ingreso_mensual if urbano==1 & ocu500==1, over(año empleo_formal) cformat(%9,4f)
		
*Sector público nacional
    svy: total dummy if ocu500==1 & relacion_laboral==1, over(año) cformat(%9,0f)
	svy: total dummy if ocu500==1 & relacion_laboral==1, over(año privado) cformat(%9,0f)
	svy: proportion privado if ocu500==1 & relacion_laboral==1, over(año) cformat(%9,4f)
*Tamaño de empresa
	svy: proportion tamaño_empresa if urbano==1 & ocu500==1 & relacion_laboral==1 & privado==1, over(año) cformat(%9,8f)
	
*Nivel educativo
	svy: proportion educacion if urbano==1 & ocu500==1 & relacion_laboral==1 & privado==1, over(año) cformat(%9,8f)
	
*Sector
	svy: proportion sector if urbano==1 & ocu500==1, over(año) cformat(%9,8f)
	svy: proportion sector if urbano==1 & ocu500==1 & año==2017, over(nse_grupos) cformat(%9,8f)
	svy: proportion nse_grupos if urbano==1 & ocu500==1 & año==2017, over(sector) cformat(%9,8f)

*NSE
	svy: proportion nse_grupos if urbano==1 & dominio==8 & ocu500==1, over(año) cformat(%9,8f)

*Horas semanales
	svy: mean horas_sem_principal if urbano==1 & ocu500==1, over(año) cformat(%9,5f)
	svy: mean horas_sem_total if urbano==1 & ocu500==1, over(año) cformat(%9,5f)

*Ingreso por hora
	svy: mean ingreso_por_hora if urbano==1 & ocu500==1, over(año) cformat(%9,6f)
	svy: mean ingreso_por_hora_total if urbano==1 & ocu500==1, over(año) cformat(%9,6f)
	
*Grupos de edad

	svy: proportion grupos_edad if urbano==1 & ocu500==1, over(año) cformat(%9,8f)

*********************************************************

*Composición del empleo urbano por regiones
	svy: proportion departamento if urbano==1 & ocu500==1 & año==2017, cformat(%9,8f)

*Crecimiento del empleo total por región
	
	
*Crecimiento del empleo asalariado por región
	svy: total dummy if urbano==1 & ocu500==1 &relacion_laboral==1, over(año departamento) cformat(%9,0f)
	
*Ingreso promedio mensual
	svy: mean ingreso_mensual if urbano==1 & ocu500==1, over(año departamento) cformat(%9,4f)
	svy: mean ingreso_mensual if urbano==1 & ocu500==1 & relacion_laboral==1, over(año departamento) cformat(%9,4f)
	
*Masa salarial anual
	svy: total ingreso_anual_millones if urbano==1 & ocu500==1, over(año departamento) cformat(%7,0f)
	svy: total ingreso_anual_millones if urbano==1 & ocu500==1, over(año zonas) cformat(%7,0f)
	
svy: proportion relacion_laboral  if urbano==1 & nse_grupos==1 & dominio==8 & ocu500==1, over(año) cformat(%9,8f)
svy: proportion relacion_laboral  if urbano==1 & nse_grupos==2 & dominio==8 & ocu500==1, over(año) cformat(%9,8f)
svy: proportion relacion_laboral  if urbano==1 & nse_grupos==3 & dominio==8 & ocu500==1, over(año) cformat(%9,8f)
svy: proportion relacion_laboral  if urbano==1 & nse_grupos==4 & dominio==8 & ocu500==1, over(año) cformat(%9,8f)


*******************************NEXA************************************************************************

recode ocu500 (1/2 =1 "PEA") (3/4=0 "no PEA") (else=.), gen(pea)
table año pea [pw=factor], format(%9,0f)

*Empleo formal público:
gen formal_publico = .
replace formal_publico = 1 if empleo_formal==1 & privado==0
table año formal_publico [pw=factor], format(%9,0f)

table año empleo_formal [pw=factor] if privado==0, format(%9,0f)
table año privado [pw=factor] if empleo_formal==1, format(%9,0f) row col
	*Lima:
	table año formal_publico [pw=factor] if zona==5, format(%9,0f)
	*Provincias:
	table año formal_publico [pw=factor] if zona!==5, format(%9,0f)
	

*Empleo formal privado:
gen formal_privado = .
replace formal_privado = 1 if empleo_formal==1 & privado==1
table año formal_privado [pw=factor], format(%9,0f)
	*Lima:
	table año formal_privado [pw=factor] if zona==5, format(%9,0f)
	*Provincias:
	table año formal_privado [pw=factor] if zona!==5, format(%9,0f) 
	
	
*Empleo dependiente:
gen dependiente = .
replace dependiente=1 if relacion_laboral==1
table año dependiente [pw=factor], format(%9,0f)
	*Lima:
	table año dependiente [pw=factor] if zona==5, format(%9,0f)

table año ocu500 [pw=factor], format(%9,0f)
table año ocu500 [pw=factor] if ocu500==1 | ocu500==2, format(%9,0f) row col
table año empleo_formal [pw=factor], format(%9,0f) row col
table año privado [pw=factor], format(%9,0f) row col


*% trabajadores independientes, dependientes y otros:
svy: proportion relacion_laboral, over(año) cformat(%9,8f)

*Informalidad en el sector formal e informal
table trabajador_formal empresa_formal [pw=factor] if año==2018, format(%9,0f) row col

*PEA según tamaño de empresa
table pea tamaño_empresa [pw=factor] if año==2018, format(%9,0f) row col

	*Huancavelica
	table pea tamaño_empresa [pw=factor] if año==2018 & departamento==9, format(%9,0f) row col
	*Ancash
	table pea tamaño_empresa [pw=factor] if año==2018 & departamento==2, format(%9,0f) row col
	*Ica
	table pea tamaño_empresa [pw=factor] if año==2018 & departamento==11, format(%9,0f) row col
	*Pasco
	table pea tamaño_empresa [pw=factor] if año==2018 & departamento==19, format(%9,0f) row col
	
*PET x nivel educativo
table educ_2 [pw=factor] if año==2018, format(%9,0f) row col
table educ_2 [pw=factor] if año==2018, by(departamento) format(%9,0f) row col

*Salario mensual promedio por sector
svy: mean ingreso_mensual if urbano==1 & año==2018, over(sector) cformat(%9,4f)

*Salario mensual promedio por region
svy: mean ingreso_mensual if urbano==1 & año==2018, over(departamento) cformat(%9,4f)
svy: mean ingreso_mensual if urbano==1 & año==2018, cformat(%9,4f)
svy: mean ingreso_mensual_total if urbano==1 & año==2018, cformat(%9,4f)
svy: mean ingreso_mensual if urbano==1 & año==2018 & privado==1, cformat(%9,4f)

*Salario mensual promedio por tamaño de empresa
svy: mean ingreso_mensual if urbano==1 & año==2018, over(tamaño_empresa) cformat(%9,4f)
svy: mean ingreso_mensual if urbano==1 & año==2018, cformat(%9,4f)

*Salario mensual promedio por nivel educativo
svy: mean ingreso_mensual if urbano==1 & año==2018, over(educ_2) cformat(%9,4f)
svy: mean ingreso_mensual if urbano==1 & año==2018, cformat(%9,4f)

*PET con educación escolar
	*Ica
	table educ_2 [pw=factor] if departamento==11 & edad>14 & edad<65, by(año) format(%9,0f) row col
	*Junin
	table educ_2 [pw=factor] if departamento==12 & edad>14 & edad<65, by(año) format(%9,0f) row col

*Empleo calificado y no calificado
recode educ_2 (1 2 3 = 1 "No calificados") (4 = 2 "Calificados"), gen(calificados)

svy: proportion calificados if año==2018 & relacion_laboral==1 & sector==3, cformat(%9,3f) 


*trabajadores mineros segun nivel educativo:
svy: proportion educ_2 if año==2018 & sector==3, cformat(%9,3f)
svy: proportion educ_2 if año==2018 & sector==3 & trabajador_formal==1, cformat(%9,3f) 
svy: proportion educ_2 if año==2018 & sector==3 & empleo_formal==1, cformat(%9,3f) 

*Trabajadores mineros segun tipo de contrato
svy: proportion tipo_contrato if sector==3, over(año) cformat(%9,3f)





******************************* IPSOS ***********************************************************************************************************
*% Trabajadores mujeres y hombres en el sector minero
svy: proportion sexo if sector==3 & año==2018 & ocu500==1 & trabajador_formal==1, cformat(%9,3f)

*% Trabajadores del sector minero según edad
recode edad (14/24=0 "14-17") (25/44=1 "18-30") (45/98=2 "31-50") (51/70=3 "51-70") (71/90=4 "71-90") (91/98=5 ">90"), gen(grupos_edad2)

svy: proportion  grupos_edad2 if sector==3 & año==2018 & ocu500==1 & trabajador_formal==1, cformat(%9,3f)

*% Trabajadores según grupo de edad en los demas sectores diferentes al sector minero
svy: proportion  grupos_edad2 if sector!=3 & año==2018 & ocu500==1 & trabajador_formal==1, cformat(%9,3f)


*% de PEA en el sector agrícola según NSE
svy: proportion  nse if sector==1 & año==2018, cformat(%9,3f)




*% personas con ingresos diarios y semanales
svy: proportion frecuencia, over(año) cformat(%9,3f)
svy: proportion empleo_formal, over(año) cformat(%9,3f)
svy: proportion pea if año==2018, over(tamaño_empresa) cformat(%9,3f)


svy: proportion empleo_formal if urbano==1, over (año) cformat(%9,3f) 


** Desigualdad en Perú
xtile percentil = ingreso_mensual_total [w=factor], nq(100)
svy: total ingreso_mensual_total, over(año) cformat(%7,0f)
svy: total ingreso_mensual_total if percentil<=50, over(año) cformat(%7,0f)
svy: total ingreso_mensual_total if percentil==100, over(año) cformat(%7,0f)

svy: total ingreso_mensual_total if percentil>=99, over(año) cformat(%7,0f)


** Coeficiente de GINI
svy: total ingreso_mensual_total if año==2017, over(percentil) cformat(%7,0f)
svy: total pea if año==2017, over(percentil) cformat(%7,0f)

table departamento if año==2018 [pw=factor], c(median ingreso_mensual_total)
table departamento if año==2018 [pw=factor], c(mean ingreso_mensual_total)

svy: mean ingreso_mensual_total if año==2018, over(departamento) cformat(%9,4f)

gen pea2= 1 if ocu500==1 | ocu500==2
svy: total pea2 if urbano==1, over(año) cformat(%7,0f) 
svy: total pea if sexo==2 & edad>=30, over(año) cformat(%7,0f) 


svy: total pea2 if urbano==1, over(año) cformat(%7,0f)

*Informalidad en las zonas urbanas
svy: proportion empleo_formal if urbano==1, over (año) cformat(%9,3f) 
svy: mean ingreso_mensual if urbano==1 & empleo_formal==0, over(año) cformat(%9,4f)

*Informalidad en el sector formal e informal
svy: proportion trabajador_formal, over(empresa_formal año) cformat(%9,3f) 


*Ingresos mensuales por rangos
gen ingreso_rango=0
replace ingreso_rango=1 if ingreso_mensual<930
replace ingreso_rango=2 if ingreso_mensual>=930 & ingreso_mensual<=1000
replace ingreso_rango=3 if ingreso_mensual>1000

svy: proportion ingreso_rango if empleo_formal==1 & año==2018, over(sector) cformat(%9,3f)

svy: proportion ingreso_rango if año==2018, over(empleo_formal) cformat(%9,3f)



*Obreros en el sector construcción
svy: proportion p507 if sector==8 & año==2018, cformat(%9,3f)

svy: proportion p507 if sector==1 & año==2018, cformat(%9,3f)
svy: proportion educ_2 if p505==971 & empleo_formal==1 & año==2018, cformat(%9,3f)
svy: mean ingreso_mensual if p505==971 & empleo_formal==1 & año==2018, cformat(%9,4f)


*Obreros en el sector industria
svy: proportion p507 if (sector==5 | sector==6) & año==2018, cformat(%9,3f)

*Peones en el sector minero
svy: proportion p505 if sector==3 & año==2018, cformat(%9,3f)


*Nivel educativo de los obreros Obreros en el sector formal
svy: proportion educ_2 if p507==4 & empleo_formal==1 & año==2018, cformat(%9,3f)
svy: mean ingreso_mensual if p507==4 & empleo_formal==1 & año==2018, cformat(%9,4f)


svy: proportion educ_2 if p505==711 & empleo_formal==1 & año==2018, cformat(%9,3f)
svy: mean ingreso_mensual if p505==711 & empleo_formal==1 & año==2018, cformat(%9,4f)



gen empl=0
replace empl=1 if ocu500==1

svy: total empl if sector_grupos==4 & empleo_formal==1 & año==2018, cformat(%7,0f) 
svy: total empl if sector==5 & empleo_formal==1 & año==2018, cformat(%7,0f) 
svy: total empl if sector==6 & empleo_formal==1 & año==2018, cformat(%7,0f) 


*Caracterización de los trabajadores del sector formal privado entre 15 y 29 años
svy: proportion educ_2 if edad>=15 & edad<=29 & empleo_formal==1 & privado==1 & año==2018, cformat(%9,3f)
svy: mean ingreso_mensual if edad>=15 & edad<=29 & empleo_formal==1 & privado==1 & año==2018, cformat(%9,4f)


*Carcaterización de los trabajadores informales
svy: mean ingreso_mensual if empleo_formal==0 & año==2018, cformat(%9,4f)
svy: proportion educacion if empleo_formal==0 & año==2018, cformat(%9,3f)
svy: proportion educacion if empleo_formal==0 & año==2018, cformat(%9,3f)


*Trabajadores que ganan entre 930 y 1000
gen edad_seg=0
replace edad_seg =1 if edad>=15 & edad<=29
replace edad_seg =2 if edad>=30 & edad<=45
replace edad_seg =3 if edad>=46 & edad<=65
replace edad_seg =4 if edad>65

svy: proportion edad_seg if ingreso_mensual>=930 & ingreso_mensual<=1000 & empleo_formal==1 & año==2018, cformat(%9,3f)
svy: proportion tipo_contrato if ingreso_mensual>=930 & ingreso_mensual<=1000 & empleo_formal==1 & año==2018, cformat(%9,3f)
svy: proportion educacion if ingreso_mensual>=930 & ingreso_mensual<=1000 & empleo_formal==1 & año==2018, cformat(%9,3f)

svy: proportion edad_seg if ingreso_mensual<=930 & empleo_formal==1 & año==2019, cformat(%9,3f)

svy: proportion educacion if edad_seg==1 & urbano==1, over(año) cformat(%9,3f)
svy: proportion educacion if edad_seg==2 & urbano==1, over(año) cformat(%9,3f)
svy: proportion educacion if edad_seg==3 & urbano==1, over(año) cformat(%9,3f)

svy: proportion educacion if urbano==1, over(año) cformat(%9,3f)


svy: mean ingreso_mensual if empleo_formal==0, over(año) cformat(%9,4f)
svy: mean ingreso_mensual if trabajador_formal==0, over(año) cformat(%9,4f)



***Pedido JSS:
gen subsidio= (2000-ingreso_mensual)*0.3 if año==2018 & ingreso_mensual>=930 & ingreso_mensual<=2000
gen subsidio2= (2000-ingreso_mensual_total)*0.3 if año==2018 & ingreso_mensual_total>=930 & ingreso_mensual_total<=2000

*Todas las empresas
svy: total subsidio if trabajador_formal==1 & año==2018 & privado==1, cformat(%7,0f) 
svy: total subsidio2 if trabajador_formal==1 & año==2018 & privado==1, cformat(%7,0f) 

*Empresas con menos de 100 trabajadores
gen empresa_100 = 0
replace empresa_100 =1 if tamaño_empresa==1 | tamaño_empresa==2 | tamaño_empresa==3 | tamaño_empresa==4
svy: total subsidio if trabajador_formal==1 & privado==1 & empresa_100==1 & año==2018, cformat(%7,0f)
svy: total subsidio if (trabajador_formal==1 & privado==1 & empresa_100==1 & año==2018) | , cformat(%7,0f)


svy: total subsidio2 if trabajador_formal==1 & privado==1 & empresa_100==1 & año==2018, cformat(%7,0f)

*Trabajadores temporales (contrato fijo)
svy: total subsidio if trabajador_formal==1 & tipo_contrato==1 & privado==1 & año==2018, cformat(%7,0f)
svy: total subsidio2 if trabajador_formal==1 & privado==1 & tipo_contrato==1 & año==2018, cformat(%7,0f)

*Número de trabajadores formales privados que ganan entre S/930 y S/2000
svy: total trabajador_formal if ingreso_mensual>=930 & ingreso_mensual<=2000 & privado==1 & año==2018
svy: mean ingreso_mensual if trabajador_formal==1 & privado==1 & ingreso_mensual>=930 & ingreso_mensual<=2000 & año==2018
table trabajador_formal if privado==1 & ingreso_mensual>=930 & ingreso_mensual<=2000 & año==2018 [pw=factor], c(median ingreso_mensual)

svy: total trabajador_formal if año==2018



*Trabajadores en empresas de menos de 100
gen ingreso = ingreso_mensual/1000
svy: total ingreso if trabajador_formal==1 & año==2018 & privado==1 & ingreso_mensual>=930 & ingreso_mensual<=2000 & empresa_100==1, cformat(%7,0f)
svy: mean ingreso_mensual if trabajador_formal==1 & privado==1 & ingreso_mensual>=930 & ingreso_mensual<=2000 & año==2018 & empresa_100==1, cformat(%7,0f)



**Trabajadores formales que ganan menos de S/1500 al mes
svy: total empleo_formal if año==2018
svy: total empleo_formal if ingreso_mensual<=1500 & año==2018

gen trab_1500=0
replace trab_1500=1 if ingreso_mensual<=1500
svy: proportion trab_1500 if empleo_formal==1 & privado==1 & año==2018


*Empleo informal por edad

recode edad (15/25=1 "15 a 25 años") (26/35=2 "26 a 35 años") (36/45=3 "36 a 45 años") (46/60=4 "46 a 60 años") (61/max=5 "60 a más años") (missing=.), gen(grupos_edad1)

svy: total grupos_edad1 if empleo_formal==0  & año==2019, over(grupos_edad1)  cformat(%9,0f)

svy: total grupos_edad1 if empleo_formal==1 & año==2019 & urbano==1, over(grupos_edad1) 

svy: total ocu500 if grupos_edad==2 & ocu500==1 & año==2019 & sector_grupos==8, over(departamento) cformat(%9,0f)

* Horas a la semana que trabajan los jóvenes

svy: mean horas_sem_principal if grupos_edad1==1 & año==2019
recode horas_sem_principal (0/30=1 "menos o igual 30 horas") (31/47=2 "menos de 48 horas") (48/max=3 "48 a más horas") (missing=.), gen(horas_1)
recode horas_sem_total (0/30=1 "menos o igual 30 horas") (31/47=2 "menos de 48 horas") (48/max=3 "48 a más horas") (missing=.), gen(horas_2)
*recode edad (15/29=1 "15 a 29 años") (30/44=2 "30 a 44 años") (45/max=3 "45 a más años") (missing=.), gen(grupos_edad1)


*Caracterización de los trabajadores del sector formal privado entre 15 y 29 años
svy: proportion ocu500 if edad>=15 & edad<=29 & año==2019 & horas_1==3 , over(grupos_edad1) cformat(%9,3f) 
svy: mean ingreso_mensual if ocu500==1 & año==2019 & empleo_formal==0, over(grupos_edad1) cformat(%9,4f)

svy: total ocu500 if ocu500==1 &  empleo_formal==0 & año==2019, over (grupos_edad1) cformat(%7,0f) 
table grupos_edad1 if ocu500==1  & año==2019 &  sexo==2 [pw=factor]



svy: total grupos_edad1 if grupos_edad1==1 & año==2019 & ocu500==1
svy: total ocu500 if ocu500==1 & año==2019 & empleo_formal==1 & (educacion==2 |educacion==3) & p507==4, over (grupos_edad1) cformat(%7,0f)
