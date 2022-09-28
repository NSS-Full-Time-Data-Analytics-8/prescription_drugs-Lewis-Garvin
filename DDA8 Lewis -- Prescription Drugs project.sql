--DDA8 Lewis Garvin
--Prescription Drugs Project

-----------------------------------
--MAIN-----------------------------

--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--      Report the npi and the total number of claims.

SELECT prescriber.npi, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY prescriber.npi
ORDER BY total_claims DESC
LIMIT 1;
--npi = 1881634483, total_claims = 99707

--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
--       specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, 
       nppes_provider_last_org_name, 
	   specialty_description,
       SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY prescriber.npi,  -- Included to avoid combining two prescribers with the same name and specialty.
         nppes_provider_first_name, 
         nppes_provider_last_org_name, 
		 specialty_description
ORDER BY total_claims DESC
LIMIT 1;
--Bruce Pendley, Family Practice, 99707 total claims


--2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_claim_count) AS specialty_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY specialty_claims DESC
LIMIT 1;
-- Specialty: Family Practice; total claims = 9,752,347

--    b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count) AS specialty_opioid_claims
FROM prescriber 
     INNER JOIN prescription USING (npi)
     INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY specialty_opioid_claims DESC
LIMIT 1;
-- Nurse Practitioner; 900,845 total claims for opioids

--    c. **Challenge Question:** Are there any specialties that appear in the prescriber table 
--       that have no associated prescriptions in the prescription table?

SELECT DISTINCT specialty_description
FROM (SELECT npi FROM prescriber 
	  EXCEPT SELECT npi FROM prescription) AS npi_without_prescription
INNER JOIN prescriber USING (npi);
-- 92 specialties have no associated prescriptions

--    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, 
--       report the percentage of total claims by that specialty which are for opioids. Which specialties 
--       have a high percentage of opioids?

SELECT specialty_description, 
       specialty_opioid_claims, 
	   SUM(total_claim_count) AS specialty_all_claims,
	   CONCAT(ROUND(100 * specialty_opioid_claims / SUM(total_claim_count),2), '%') AS opioid_claims_percentage
FROM (SELECT specialty_description, SUM(total_claim_count) AS specialty_opioid_claims
          FROM prescriber INNER JOIN prescription USING (npi)
                          INNER JOIN drug USING (drug_name)
          WHERE opioid_drug_flag = 'Y'
          GROUP BY specialty_description) AS opioid_claims_by_specialty
	  INNER JOIN prescriber USING (specialty_description)
	  INNER JOIN prescription USING (npi)
GROUP BY specialty_description, specialty_opioid_claims
ORDER BY specialty_opioid_claims / SUM(total_claim_count) DESC;
--Top 5 specialties with highest percentage of total from opioid prescriptions:
--     Case Manager/Care Coordinator  72.00%
--     Orthopaedic Surgery            68.98%
--     Interventional Pain Management 60.89%
--     Pain Management                59.42%
--     Anesthesiology                 59.32%

--Note: This solution for Q2.d. only includes specialties that have opioid 
--      prescriptions. It would need to be changed in order to include 
--      specialties that do not have associated opiod prescriptions or that 
--      do not have associated prescriptions for any drug.


--3. a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC;
--Drug: INSULIN GLARGINE,HUM.REC.ANLOG, total drug cost = $104,264,066.35

--    b. Which drug (generic_name) has the hightest total cost per day? 
--       **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS total_cost_per_day
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC;
-- Drug: C1 ESTERASE INHIBITOR, total cost per day: $3495.22


--4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which 
--      says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which 
--      have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name, CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
                       WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
					   ELSE 'neither' END AS drug_type
FROM drug;

--    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
--       on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' END AS drug_type,
	   SUM(total_drug_cost::MONEY) AS total_cost_by_type
FROM drug INNER JOIN prescription USING (drug_name)
WHERE CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
           WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' END IS NOT NULL
GROUP BY drug_type
ORDER BY total_cost_by_type DESC;
--More was spent on opiods ($105,080,626.37) than on antibiotics ("$38,435,121.26").

--5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN';
-- 10 CBSAs are in Tennessee.

--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS cbsa_population
FROM cbsa INNER JOIN population USING (fipscounty)
--        INNER JOIN fips_county USING (fipscounty)
--WHERE state = 'TN'
GROUP BY cbsaname
ORDER BY cbsa_population DESC;
-- Nashville-Davidson--Murfreesboro--Franklin, TN has 1,830,410 total population.
-- NOTE: Joining to fips_county and filtering for state = 'TN' is not strictly necessary
--       because the population table only includes counties in TN.

--    c. What is the largest (in terms of population) county which is not included in a CBSA? 
--       Report the county name and population.

--Anti-Join
SELECT county, population
FROM fips_county INNER JOIN population USING (fipscounty)
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY population DESC;
--County: Sevier, population: 95523

--6. 
--    a. Find all rows in the prescription table where total_claims is at least 3000. 
--       Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription INNER JOIN drug USING (drug_name)
WHERE total_claim_count > 3000;

--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, opioid_drug_flag, total_claim_count
FROM prescription INNER JOIN drug USING (drug_name)
WHERE total_claim_count > 3000;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last 
--       name associated with each row.

SELECT drug_name, opioid_drug_flag, total_claim_count, nppes_provider_first_name, nppes_provider_last_org_name
FROM prescription INNER JOIN drug USING (drug_name)
                  INNER JOIN prescriber USING (npi)
WHERE total_claim_count > 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
--   and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--    a. First, create a list of all npi/drug_name combinations for pain management specialists 
--       (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--       where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. 
--       You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
	  
SELECT DISTINCT npi, drug_name
FROM prescriber CROSS JOIN drug 
WHERE specialty_description = 'Pain Management'
      AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y';
	  
--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or 
--       not the prescriber had any claims. You should report the npi, the drug name, and the number of 
--       claims (total_claim_count).

SELECT npi, drug_name, SUM(total_claim_count) AS npi_drug_total_claims
FROM prescriber CROSS JOIN drug 
                LEFT JOIN prescription USING (npi, drug_name) -- Assumption: the CROSS JOIN happens before the LEFT JOIN.
WHERE specialty_description = 'Pain Management'
      AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
GROUP BY npi, drug_name;
	  
--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
--       Hint - Google the COALESCE function.

SELECT npi, drug_name, COALESCE(SUM(total_claim_count), 0) AS npi_drug_total_claims
FROM prescriber CROSS JOIN drug 
                LEFT JOIN prescription USING (npi, drug_name) -- Assumption: the CROSS JOIN happens before the LEFT JOIN.
WHERE specialty_description = 'Pain Management'
      AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
GROUP BY npi, drug_name;


-----------------------------------
--BONUS: PART 1--------------------

--1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(npi)
FROM (SELECT DISTINCT npi FROM prescriber 
	  EXCEPT SELECT npi FROM prescription) AS npi_without_prescription;
--4458 npi numbers


--2.
--    a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) as family_practice_drug_claims
FROM prescriber
     INNER JOIN prescription USING (npi)
	 INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY family_practice_drug_claims DESC
LIMIT 5;
--Top 5 drugs prescribed by Family Practice prescribers w/total claims:
--LEVOTHYROXINE SODIUM	406547
--LISINOPRIL	        311506
--ATORVASTATIN CALCIUM	308523
--AMLODIPINE BESYLATE	304343
--OMEPRAZOLE	        273570

--    b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) as cardiology_drug_claims
FROM prescriber
     INNER JOIN prescription USING (npi)
	 INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY cardiology_drug_claims DESC
LIMIT 5;
--Top 5 drugs prescribed by Cardiology prescribers w/total claims
--ATORVASTATIN CALCIUM	120662
--CARVEDILOL	        106812
--METOPROLOL TARTRATE	 93940
--CLOPIDOGREL BISULFATE	 87025
--AMLODIPINE BESYLATE	 86928

--    c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
--       Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name, SUM(total_claim_count) as fp_card_drug_claims
FROM prescriber
     INNER JOIN prescription USING (npi)
	 INNER JOIN drug USING (drug_name)
WHERE specialty_description IN ('Family Practice', 'Cardiology')
GROUP BY generic_name
ORDER BY fp_card_drug_claims DESC
LIMIT 5;
--Top 5 drugs prescribed by Family Practice and Cardiology prescribers w/total claims
--ATORVASTATIN CALCIUM	429185
--LEVOTHYROXINE SODIUM	415476
--AMLODIPINE BESYLATE	391271
--LISINOPRIL	        387799
--FUROSEMIDE	        318196


--3. Your goal in this question is to generate a list of the top prescribers in each of the major 
--   metropolitan areas of Tennessee.

--    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total 
--       number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, 
--       and include a column showing the city.

SELECT npi, SUM(total_claim_count) AS npi_total_claims, nppes_provider_city
FROM prescriber INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY npi_total_claims DESC
LIMIT 5;
--Top 5 prescribers in Nashville:
--npi         npi_total_claims  nppes_provider_city
--1538103692  			 53622	NASHVILLE
--1497893556             29929	NASHVILLE
--1659331924             26013	NASHVILLE
--1881638971             25511	NASHVILLE
--1962499582             23703	NASHVILLE

--    b. Now, report the same for Memphis.

SELECT npi, SUM(total_claim_count) AS npi_total_claims, nppes_provider_city
FROM prescriber INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY npi_total_claims DESC
LIMIT 5;
--npi         npi_total_claims  nppes_provider_city
--1346291432			 65659	MEMPHIS
--1225056872			 62301	MEMPHIS
--1801896881			 40169	MEMPHIS
--1669470316			 39491	MEMPHIS
--1275601346			 36190	MEMPHIS

--    c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

--I am assuming the result set should include the top 5 prescribers for each of the 4 cities, 
--which is a total of 20 prescribers.
(SELECT npi, SUM(total_claim_count) AS npi_total_claims, nppes_provider_city
	FROM prescriber INNER JOIN prescription USING (npi)
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY npi_total_claims DESC
	LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS npi_total_claims, nppes_provider_city
	FROM prescriber INNER JOIN prescription USING (npi)
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY npi, nppes_provider_city
	ORDER BY npi_total_claims DESC
	LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS npi_total_claims, nppes_provider_city
	FROM prescriber INNER JOIN prescription USING (npi)
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY npi_total_claims DESC
	LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS npi_total_claims, nppes_provider_city
	FROM prescriber INNER JOIN prescription USING (npi)
	WHERE nppes_provider_city = 'CHATTANOOGA'
	GROUP BY npi, nppes_provider_city
	ORDER BY npi_total_claims DESC
	LIMIT 5)
ORDER BY nppes_provider_city, npi_total_claims;
	

--4. Find all counties which had an above-average number of overdose deaths. 
--   Report the county name and number of overdose deaths.

SELECT county, deaths
FROM fips_county INNER JOIN overdoses USING (fipscounty)
WHERE deaths > (SELECT AVG(deaths) FROM overdoses);
--Solution is based only on overdose deaths per county. 
--A more meaningful approach would be to focus on overdose deaths per capita.


--5.
--    a. Write a query that finds the total population of Tennessee.

SELECT SUM(population)
FROM fips_county INNER JOIN population USING (fipscounty)
WHERE state = 'TN';
--6597381

--    b. Build off of the query that you wrote in part a to write a query that returns for each county 
--       that county's name, its population, and the percentage of the total population of Tennessee 
--       that is contained in that county.

SELECT county, 
	   population,
	   CONCAT(ROUND(100 * population / (SELECT SUM(population) 
					 					FROM fips_county INNER JOIN population USING (fipscounty) 
					 					WHERE state = 'TN'),
					2),'%')
	   AS percentage_of_tn_pop
FROM fips_county INNER JOIN population USING (fipscounty)
WHERE state = 'TN';


-----------------------------------
--BONUS: PART 2--------------------

--**Attempt these questions only after completing all other Main and Bonus 1 questions**

--In this set of exercises you are going to explore additional ways to group and organize the output of a query 
--when using postgres.

--For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management 
--Specialists compared to those from Pain Managment specialists.


--1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

--specialty_description         |total_claims|
--------------------------------|------------|
--Interventional Pain Management|       55906|
--Pain Management               |       70853|

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description;


--2. Now, let's say that we want our output to also include the total number of claims between these two groups. 
--Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

--specialty_description         |total_claims|
--------------------------------|------------|
--                              |      126759|
--Interventional Pain Management|       55906|
--Pain Management               |       70853|

SELECT NULL, SUM(total_claim_count) AS total_claims
	FROM prescriber INNER JOIN prescription USING (npi)
	WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
UNION
SELECT specialty_description, SUM(total_claim_count) AS total_claims
	FROM prescriber INNER JOIN prescription USING (npi)
	WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
	GROUP BY specialty_description;

--3. Now, instead of using UNION, make use of GROUPING SETS 
--   (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) 
--   to achieve the same output.

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS ((), specialty_description);


--4. In addition to comparing the total number of prescriptions by specialty, let's also bring in 
-- information about the number of opioid vs. non-opioid claims by these two specialties. 
-- Modify your query (still making use of GROUPING SETS so that your output also shows the total 
-- number of opioid claims vs. non-opioid claims by these two specialites:

--specialty_description         |opioid_drug_flag|total_claims|
--------------------------------|----------------|------------|
--                              |                |      129726|
--                              |Y               |       76143|
--                              |N               |       53583|
--Pain Management               |                |       72487|
--Interventional Pain Management|                |       57239|

SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
                INNER JOIN drug USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS ((), opioid_drug_flag, specialty_description);
	

--5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). 
--How is the result different from the output from the previous query?

SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
                INNER JOIN drug USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP (opioid_drug_flag, specialty_description);
--Results no longer include subtotals for each specialty_description across all drugs,
--but they still include subtotals for each opioid_drug_flag across both specialty_description values.
--Results also include subtotals for every combination of opioid_drug_flag and specialty_description values.
--Overall, these results imply a grouping hierarchy for subtotals in which specialty_description is a 
--smaller grouping within opioid_drug_flag.


--6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). 
--How does this change the result?

SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
                INNER JOIN drug USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP (specialty_description, opioid_drug_flag);
--Results no longer include totals for each opioid_drug_flag across both specialty_description values.
--Instead, the results now include totals for each specialty_description across both opioid_drug_flag_values. 
--This implies a grouping hierarchy for subtotals in which opioid_drug_flag is a smaller grouping 
--within specialty_description.
	
	
--7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?

SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
                INNER JOIN drug USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE (specialty_description, opioid_drug_flag);
--Results now include subtotals for every possible grouping:
--  subtotals for all 4 combinations of specialty_description and opioid_drug_flag values, 
--  subtotals by opioid_drug_flag,
--  subtotals by specialty_description,
--  and totals for the entire result set.


--8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities 
--   in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six 
--   common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. 
--   For the purpose of this question, we will put a drug into one of the six listed categories if it has 
--   the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" 
--   and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

--   The end result of this question should be a table formatted like this:

--city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-------------|-------|--------|-----------|--------|---------|-----------|
--CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
--KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
--MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
--NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

--   For this question, you should look into use the crosstab function, which is part of the tablefunc extension 
--   (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) 
--   run the command
--	 CREATE EXTENSION tablefunc;

--Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
--Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with 
--         one row_name column, one category column, and one value column. So in this case, you need to have a city 
--         column, a drug label column, and a total claim count column.
--Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that 
--         you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.


--QUERY WITHOUT CROSSTAB--
WITH drug_with_opioid_type AS (SELECT drug_name,
					 		  	      generic_name,
									  CASE WHEN generic_name LIKE '%HYDROCODONE%' THEN 'hydrocodone'
	 									   WHEN generic_name LIKE '%OXYCODONE%' THEN 'oxycodone'
	 									   WHEN generic_name LIKE '%OXYMORPHONE%' THEN 'oxymorphone'
										   WHEN generic_name LIKE '%MORPHINE%' THEN 'morphine'
	 									   WHEN generic_name LIKE '%CODEINE%' THEN 'codeine'
	 									   WHEN generic_name LIKE '%FENTANYL%' THEN 'fentanyl'
	 									   ELSE NULL END AS opioid_type
							   FROM drug)
SELECT nppes_provider_city AS city, 
	   opioid_type,
	   SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
                INNER JOIN drug_with_opioid_type USING (drug_name)
WHERE nppes_provider_city IN ('CHATTANOOGA','KNOXVILLE','MEMPHIS','NASHVILLE')
      AND opioid_type IS NOT NULL
GROUP BY nppes_provider_city, opioid_type
ORDER BY city, opioid_type;

--QUERY WITH CROSSTAB--
SELECT * 
FROM CROSSTAB(
	'WITH drug_with_opioid_type AS (SELECT drug_name,
						 		  	      generic_name,
										  CASE WHEN generic_name LIKE ''%HYDROCODONE%'' THEN ''hydrocodone''
		 									   WHEN generic_name LIKE ''%OXYCODONE%'' THEN ''oxycodone''
		 									   WHEN generic_name LIKE ''%OXYMORPHONE%'' THEN ''oxymorphone''
											   WHEN generic_name LIKE ''%MORPHINE%'' THEN ''morphine''
		 									   WHEN generic_name LIKE ''%CODEINE%'' THEN ''codeine''
		 									   WHEN generic_name LIKE ''%FENTANYL%'' THEN ''fentanyl''
		 									   ELSE NULL END AS opioid_type
								   FROM drug)
	SELECT nppes_provider_city AS city, 
		   opioid_type,
		   SUM(total_claim_count) AS total_claims
	FROM prescriber INNER JOIN prescription USING (npi)
	                INNER JOIN drug_with_opioid_type USING (drug_name)
	WHERE nppes_provider_city IN (''CHATTANOOGA'',''KNOXVILLE'',''MEMPHIS'',''NASHVILLE'')
	      AND opioid_type IS NOT NULL
	GROUP BY nppes_provider_city, opioid_type
	ORDER BY city, opioid_type;' 
	) AS ct(city TEXT,
	    	codeine NUMERIC,
			fentanyl NUMERIC,
			hydrocodone NUMERIC,
			morphine NUMERIC,
			oxycodone NUMERIC,
			oxymorphone NUMERIC);

--------------------