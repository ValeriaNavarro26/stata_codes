clear all
cd "..."
set more off, permanently

*===============================================================================
*Preparamos la base de datos
*===============================================================================

use "enaho-tabla-ciuo-88.dta", clear
	keep if variedad==0 & subgrupo==0
	drop variedad subgrupo
	replace codocupa=int(codocupa/10)
	save "ocupaciones-modif.dta", replace
	
import excel using "Códigos de carreras.xlsx", firstrow sheet("Hoja1") clear
	save "códigos carreras.dta", replace
	
use "enaho01a-2008-300.dta", clear
	quietly append using "enaho01a-2013-300.dta"
	quietly append using "enaho01a-2018-300.dta"
         quietly append using "enaho01a-2019-300.dta
	egen temp=rowfirst(a?o)
	drop a?o
	rename temp año
	rename p301a1 cod_carrera
	replace cod_carrera=. if cod_carrera==999999
	replace cod_carrera=int(cod_carrera/1000)
	merge m:1 cod_carrera using "códigos carreras.dta", keep(1 3) nogenerate
	save "carrera estudiada.dta", replace

use "enaho01a-2008-500.dta", clear
	quietly append using "enaho01a-2013-500.dta"
	quietly append using "enaho01a-2018-500.dta"
	quietly append using "enaho01a-2019-500.dta"
egen temp=rowfirst(a?o)
	drop a?o
	rename temp año

egen temp=rowfirst(fac*)
	drop fac*
	rename temp factor

replace p505=int(p505/10)
rename p505 codocupa

count
merge m:1 codocupa using "ocupaciones-modif.dta", keepusing(codocupa desocupa) keep(1 3) nogenerate // las observaciones que se pierden son los desocupados y los nombres de los grandes grupos de ocupaciones
merge 1:1 año conglome vivienda hogar codperso using "carrera estudiada.dta"
	
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
		replace empleo_formal=1 if ocu500==1 & relacion_laboral==1 & (privado==0 | (privado==1 & trabajador_formal==1))
		replace empleo_formal=0 if ocu500==1 & ((relacion_laboral==1 & privado==1 & trabajador_formal==0) | relacion_laboral==2 | relacion_laboral==3 | relacion_laboral==4)
			label define empleo_formal 0 "Trabajador informal" 1 "Trabajador formal"
			label values empleo_formal empleo_formal
	
	
	*cap drop ingreso_2 
	egen ingreso_2 = rowtotal(p524d1 p524e1 p529t p530a p536)			// Ingreso anual
	  
  
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

	
	
***Variables adicionales :

*1. Trabajadores vinculados al sector màs afectados por la cuarentena: restaurantes, hoteles, construcciòn, trsnporte y almac, enseñanza, comercio, minerìa, textiles y metalmecànica
gen trab_restaurante=.
replace trab_restaurante=1 if ciiu_rev_4==5610 | ciiu_rev_4==5621 | ciiu_rev_4==5629 | ciiu_rev_4==5630

gen trab_hotel=.
replace trab_hotel=1 if ciiu_rev_4==5510 | ciiu_rev_4==5590	

gen trab_construccion=.
replace trab_construccion=1 if ciiu_rev_4==4100	| ciiu_rev_4==4210 | ciiu_rev_4==4220 | ciiu_rev_4==4290 | ciiu_rev_4==4311 | ciiu_rev_4==4312 | ciiu_rev_4==4321 | ciiu_rev_4==4322 | ciiu_rev_4==4329 | ciiu_rev_4==4330 | ciiu_rev_4==390

gen trab_transp_almac=.
replace trab_transp_almac=1 if ciiu_rev_4==4911 | ciiu_rev_4==4912 | ciiu_rev_4==4921 | ciiu_rev_4==4922 | ciiu_rev_4==4923 | ciiu_rev_4==4930 | ciiu_rev_4==5011 | ciiu_rev_4==5012 | ciiu_rev_4==5021 | ciiu_rev_4==5022 | ciiu_rev_4==5110 | ciiu_rev_4==5120 | ciiu_rev_4==5210 | ciiu_rev_4==5221 | ciiu_rev_4==5222 | ciiu_rev_4==5223 | ciiu_rev_4==5224 | ciiu_rev_4==5229 | ciiu_rev_4==5310 | ciiu_rev_4==5320

gen trab_enseñanza=.
replace trab_enseñanza=1 if ciiu_rev_4==8510 | ciiu_rev_4==8521 | ciiu_rev_4==8522 | ciiu_rev_4==8530 | ciiu_rev_4==8541 | ciiu_rev_4==8542 | ciiu_rev_4==8549 | ciiu_rev_4==8550

gen trab_comercio=.
replace trab_comercio=1 if ciiu_rev_4==4510 | ciiu_rev_4==4520 | ciiu_rev_4==4530 | ciiu_rev_4==4540 | ciiu_rev_4==4651 | ciiu_rev_4==4652 | ciiu_rev_4==4653 | ciiu_rev_4==4659 | ciiu_rev_4==4661 | ciiu_rev_4==4662 | ciiu_rev_4==4663 | ciiu_rev_4==4669 | ciiu_rev_4==4690

gen trab_mineria=.
replace trab_mineria=1 if ciiu_rev_4==510 | ciiu_rev_4==610 | ciiu_rev_4==620 | ciiu_rev_4==710 | ciiu_rev_4==729 | ciiu_rev_4==810 | ciiu_rev_4==891 | ciiu_rev_4==893 | ciiu_rev_4==899 | ciiu_rev_4==910 | ciiu_rev_4==990
	
gen trab_textiles=.
replace trab_mineria=1 if ciiu_rev_4==1311 | ciiu_rev_4==1312 | ciiu_rev_4==1313 | ciiu_rev_4==1391 | ciiu_rev_4==1392 | ciiu_rev_4==1393 | ciiu_rev_4==1394 | ciiu_rev_4==1399 | ciiu_rev_4==1410 | ciiu_rev_4==1420 | ciiu_rev_4==1430 | ciiu_rev_4==1511 | ciiu_rev_4==1512 | ciiu_rev_4==1520

gen trab_metalmecanica=.
replace trab_metalmecanica=1 if ciiu_rev_4==2410 | ciiu_rev_4==2420 | ciiu_rev_4==2431 | ciiu_rev_4==2432 | ciiu_rev_4==2511 | ciiu_rev_4==2512	| ciiu_rev_4==2520 | ciiu_rev_4==2591 | ciiu_rev_4==2592 | ciiu_rev_4==2593 | ciiu_rev_4==2599


***Ingreso y gasto mensual promedio formal e informal por hogar urbano:
	*Al momento de mergear la base de empleo y sumaria, me quedé con los ingresos y gastos totales a nivel de hogar. (esto se puede ver en la fila 64 de este do: *NSE)
	//Por ello, para obtener los ingresos y gastos mensuales del hogar se divió entre 12
	gen ingreso_mensual_familiar= inghog2d/12
	gen gasto_mensual_familiar= gashog2d/12

	*Promedio del ingreso y gasto promedio mensual de los hogares urbanos en el 2018 según nse
	svy: mean ingreso_mensual_familiar if año==2018 & urbano==1, over(nse)
	svy: mean gasto_mensual_familiar if año==2018 & urbano==1, over(nse)

	matrix ing_mensual_familiar = (10093, 7100, 4670, 3120, 2100)
	matrix list ing_mensual_familiar
	
	*Ingreso promedio formal e informalde los hogares urbanos según nse
	svy: mean ingreso_mensual_familiar if año==2018 & urbano==1, over(nse empleo_formal)

	**Trabajadores independientes urbanos según nse:
	svy: proportion nse if año==2018 & urbano==1, over(relacion_laboral) // Del total de informales, qué % hay en cada NSE

	***Empleo formal urbano según nse:
	svy: proportion empleo_formal if año==2018 & urbano==1, over(nse)
	
	*% del empleo formal de cada hogar que está en el sector público 
	//Con este cálculo, asumimos que lo más probable es que los formales de los NSE D/E que continúan trabajando son del sector público
	svy: proportion privado if año==2018 & urbano==1 & empleo_formal==1, over(nse)

	
***Cantidad de personas que aportan a la AFP según NSE:
	*la variable p558b1 indica el último mes que la persona aportó al sistema de pensiones (tanto publica como privada)
	rename p558b1 mes_aporte
	*la variable p558b2 indica el último año que la persona aportó al sistema de pensiones (tanto publica como privada)
	rename p558b2 año_aporte
	*la variable p558a1 indica si la persona aporta al SPP (AFP) (=1 si es afp)
	rename p558a1 afp	
	
	*Número de trabajadores formales que aportaron al SPP en el 2018
	svy: total trabajador_formal if mes_aporte!=0 & mes_aporte!=. & año_aporte==2018 & año==2018 & afp==1, over(nse)

*===============================================================================
*keep conglome-estrato ocu500 sexo edad año-zonas horas_sem_principal frecuencia ingreso_por_pago ingreso_mensual_independiente pagos_por_mes horas_sem_secundaria ingreso_mensual_sec_dep ingreso_mensual_sec_indep ocupinf ciiu_rev_3 ciiu_rev_4 codocupa desocupa cod_carrera des_carrera p301a privado departamento zonas
save "...\bd-procesada.dta", replace



cd "..."
clear all
set more off, permanently
use "bd-procesada.dta", replace



*** 8. Impacto en pobreza:
	*Nuevo ingreso mensual por hogar luego del coronavirus:
	//A cada ingreso promedio mensual del hogar se le resta el impacto negativo obtenido en el excel:Impacto en pobreza
	gen ingreso_mensual_nuevo=.
	replace ingreso_mensual_nuevo= ingreso_mensual_familiar -669 if nse==1 & año==2018
	replace ingreso_mensual_nuevo= ingreso_mensual_familiar -1112 if nse==2 & año==2018
	replace ingreso_mensual_nuevo= ingreso_mensual_familiar -1034 if nse==3 & año==2018
	replace ingreso_mensual_nuevo= ingreso_mensual_familiar -1160 if nse==4 & año==2018
	replace ingreso_mensual_nuevo= ingreso_mensual_familiar -1046 if nse==5 & año==2018


	***Pobreza:
	//Se comparan los gastos familiares mensuales, los ingresos anteriores y los nuevos ingresos con la línea de pobreza del hogar (369*4 = 1476)
	*Gastos promedio mensuales del hogar vs línea de pobreza
	gen pobreza = .
	replace pobreza = 1 if gasto_mensual_familia < 1476 & año==2018

	*Ingresos promedio mensuales del hogar vs línea de pobreza
	gen pobreza_1 = .
	replace pobreza_1 = 1 if ingreso_mensual_familiar < 1476 & año==2018

	*Nuevos ingresos promedio mensuales del hogar vs vs línea de pobreza
	gen pobreza_2 = .
	replace pobreza_2 = 1 if ingreso_mensual_nuevo < 1476 & año==2018

	*% de hogares pobres según NSE:
	svy: proportion nse if año==2018, over (pobreza)
	svy: proportion nse if año==2018, over(pobreza_1)
	svy: proportion nse if año==2018, over(pobreza_2)



************************************
*** NOTA DE MERCADO LABORAL
************************************
*Educación
	recode p301a (1=1 "Sin nivel") (2 3 = 2 "Inicial completa") (4 5 = 3 "Primaria incompleta") (6 7 9 = 4 "Secundaria completa"), (8 10 11 12 = 5 "Universitario o tecnico completo"), gen(educacion_2)  
	
	
*** Panorama económico:

*Trabajadores beneficiados según nuevas actividades consideradas en el DS y por NSE:
gen trab_peluqueria =.
replace trab_peluqueria= 1 if año==2018 & ciiu_rev_4==9602

svy: total trab_peluqueria, over(nse)
	
gen trab_oficios=.
replace trab_oficios= 1 if ciiu_rev_4==9522 | ciiu_rev_4==9529 | ciiu_rev_4==9521 | ciiu_rev_4==9700 | ciiu_rev_4==9524 | ciiu_rev_4==9601 | ciiu_rev_4==9602 | ciiu_rev_4==4799 | ciiu_rev_4==4791
	
svy: total trab_oficios if año==2018 & urbano==1, over(nse)

	
drop trab_oficios



**Daily ancianos
svy: total dummy if ocu500==1 & año==2018 & edad>=65
svy: total dummy if ocu500==1 & año==2018 & edad>=65 & empleo_formal==0
	
svy: total dummy if ocu500==1 & año==2018 & edad>=65, over(nse)
svy: total dummy if ocu500==1 & año==2018 & edad>=65 & empleo_formal==0	
	
	
	
	
	
	
	
	
	
	
	
	









