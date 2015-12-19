
SELECT "Adding functions..." AS INFO;

USE employees;
DROP FUNCTION IF EXISTS NumToCurrency;
DROP FUNCTION IF EXISTS NumToPct;

DELIMITER $$

CREATE FUNCTION NumToCurrency(numToConvert DECIMAL(30,10), outputDecimalPlaces INT) RETURNS VARCHAR(20)
#	To convert 123456.456 to $123,456.46:
#	SELECT (123456.456, 2)
#
#	To convert 7.12 to $7:
#	SELECT (7.12, 0)
#
  DETERMINISTIC
  READS SQL DATA
BEGIN
	RETURN CONCAT('$', FORMAT(numToConvert,outputDecimalPlaces));
END $$



CREATE FUNCTION NumToPct(numToConvert DECIMAL(30,10), outputDecimalPlaces INT, multiplyFactor INT) RETURNS VARCHAR(20)
#	Convert 0.123456 to 12.35%
#	SELECT NumToPct(0.123456, 2, 100)
#	The 100 means to multiple by 100
#	Convert 12.3456 to 12.35%
#	SELECT NumToPct(12.3456, 2,1)
  DETERMINISTIC
  READS SQL DATA
BEGIN
	RETURN CONCAT(FORMAT(numToConvert*multiplyFactor,outputDecimalPlaces), '%');
END $$

DELIMITER ;


###########################################################
#
# 2.1
#
###########################################################
SELECT "2.1" AS INFO;
SELECT "Creating MSBX_jjb database" AS INFO;
DROP SCHEMA IF EXISTS msbx5405_jjb;
CREATE SCHEMA msbx5405_jjb;
USE msbx5405_jjb;

DROP TABLE IF EXISTS sql_statements_jjb;

CREATE TABLE sql_statements_jjb (
    Key_Primary         int(11)       NOT NULL  
  , Key_Second_01       varchar(50)   DEFAULT NULL
  , Key_Second_02       varchar(50)   DEFAULT NULL
  , XLS_row_seq         int(11)       NOT NULL
  , SQL_Statement       varchar(320)  NOT NULL
  , SQL_Source          varchar(50)   NOT NULL
  , Chapter             int(11)       NOT NULL
  , SQL_Statement_Root  varchar(57)   NOT NULL
  , Input_Src           varchar(50)   NOT NULL
  , Input_Src_DTTM      datetime      NOT NULL
  

  , PRIMARY KEY (Key_Primary)
	, UNIQUE KEY (XLS_row_seq)
	,	KEY (SQL_Statement)
) ENGINE=MyISAM DEFAULT CHARSET=utf8
;

LOAD DATA LOCAL INFILE
'm:/sqlstatements-db/db_sql_statements_jjb.txt'
INTO TABLE sql_statements_jjb
IGNORE 1 LINES
;

###########################################################
# 2.1.i
###########################################################
# i.	Save the workbook in an XLSB format.  
#			Answer what is different about these XLS formats:
#     1) XLSb vs. XLSx vs. XLSm vs. XLS?
#	
#		* xls[X | M | B] available since 2007 and XML based with 
#			2^20 (1,048,576) rows and 2^16 (16,384) columns
#		* xls pre 2007 with 2^16 (65,536) rows and 2^8 (256) columns
#		
# From: #	http://superuser.com/questions/366468/what-is-the-maximum-allowed-rows-in-a-microsoft-excel-xls-or-xlsx
#+-----------------+-----------+--------------+---------------------+
#|                 | Max. Rows | Max. Columns | Max. Cols by letter |
#+-----------------+-----------+--------------+---------------------+
#| Excel 365*      | 1,048,576 | 16,384       | XFD                 |
#| Excel 2013      | 1,048,576 | 16,384       | XFD                 |
#| Excel 2010      | 1,048,576 | 16,384       | XFD                 |
#| Excel 2007      | 1,048,576 | 16,384       | XFD                 |
#| Excel 2003      | 65,536    | 256          | IV                  |
#| Excel 2002 (XP) | 65,536    | 256          | IV                  |
#| Excel 2000      | 65,536    | 256          | IV                  |
#| Excel 97        | 65,536    | 256          | IV                  |
#| Excel 95        | 16,384    | 256          | IV                  |
#| Excel 5         | 16,384    | 256          | IV                  |
#+-----------------+-----------+--------------+---------------------+
#	http://blog.datasafexl.com/excel-articles/advantages-of-xlsb-excel-binary-format/
#
#	When to use each from a practical view?
#	
#	XLSB:	As much as possible:  Stores VBA and compresses
#	XLSM:	Why use if B format compresses and stores VBA	if not doing anything unusual?
#	XLSx:	Many tools that import (such as Alteryx) can import XLS or XLSX only.
#	XLS:	Some export processes only save XLS formats, but restricted to XLS.
#
#	I use XLSB for everything I do (and have since 2007) unless 
#	I interact with tools that require XLSX format.
#
###########################################################
SELECT 'Check comments for XLS format discussion' AS '2.1.i';


###########################################################
#
# 2.2
#
###########################################################
SELECT "2.2" AS INFO;
SELECT "2.2.h.i" AS INFO;
SHOW DATABASES;

SELECT "2.2.h.ii" AS INFO;
SHOW TABLES IN jumpstart;
SHOW TABLES IN sakila;
SHOW TABLES IN menagerie;
SHOW TABLES IN employees;
SHOW TABLES IN world;
SHOW TABLES IN sqlzoo;
SHOW TABLES IN msbx5405_jjb;


###########################################################
#
# 2.3
#
###########################################################
# XLS worksheets
#	Additional info:
#		* Avoid the default #N/A with vlookup()
#			use IFERROR() and specifically set even if ''
#			I use !ERR! or !N/F! or something similar
#			Using N/A inside Excel invites challenges
###########################################################
SELECT "2.3" AS INFO;
SELECT 'Check comments for discussion about VLOOKUP() and #N/A' AS '2.3';


###########################################################
#
# 2.4
#
###########################################################
#
# Before Gender and Salary information can be calculated,
# the emp_no-to-dept and emp_no-to-salaries need to be 
# de-duped.
#
#	This could be done with a single SELECT using subqueries
#	and other approaches.
#	
#	The choice here to enable visibility into the process
#	is to create intermediate tables
# 
# The result should be a single current/most recent department 
# for each emp_no and and single current/most recent 
#	salary for each emp_no.
# 
# These are calculated for both active and inactive
# employees.
#
###########################################################
SELECT "2.4" AS INFO;
USE employees;
###########################################################
#
# Get the current department for each employee
#
###########################################################
SELECT "Creating Employee No Duplicates" AS INFO;

DROP TABLE IF EXISTS dept_emp_nodups;

CREATE TABLE dept_emp_nodups
SELECT
    dep01.emp_no
  , dep01.dept_no
  , dep01.from_date
  , dep01.to_date
FROM dept_emp AS dep01
JOIN (
        SELECT 
            d02.emp_no
          , max(d02.to_date) AS to_date 
        FROM dept_emp AS d02 
        GROUP BY d02.emp_no
      ) AS r
ON      dep01.emp_no = r.emp_no 
    AND dep01.to_date = r.to_date
GROUP BY dep01.emp_no
;


###########################################################
# Get the current department manager
###########################################################
SELECT "Creating Deparment Manager No Duplicates" AS INFO;
DROP TABLE IF EXISTS dept_manager_maxdate;

CREATE TABLE dept_manager_maxdate
SELECT DISTINCT
    mgr01.dept_no
  , MAX(mgr01.to_date) AS to_date_MAX
FROM employees.dept_manager AS mgr01
GROUP BY
    mgr01.dept_no
ORDER BY
    mgr01.dept_no
;

DROP TABLE IF EXISTS dept_manager_nodups;
CREATE TABLE dept_manager_nodups
SELECT
    mgr01.emp_no AS emp_no
  , mgr01.dept_no AS dept_no
  , mgr01.from_date AS from_date
  , mgr01.to_date AS to_date
FROM dept_manager_maxdate AS max01
LEFT OUTER JOIN dept_manager as mgr01
  ON      max01.dept_no = mgr01.dept_no 
      AND max01.to_date_MAX = mgr01.to_date
;


###############################################
# Get the current (i.e. max date) salary
# before calculations.
###############################################
SELECT "Creating Salaries No Duplicates" AS INFO;
DROP TABLE IF EXISTS salaries_nodups;

CREATE TABLE salaries_nodups
SELECT
    sal01.emp_no
  , sal01.salary  AS salary
  , sal01.from_date AS from_date
  , sal01.to_date AS to_date
FROM salaries AS sal01
JOIN 
  ( SELECT 
      s02.emp_no
    , max(s02.from_date) AS from_date 
    , max(s02.to_date) AS to_date 
    FROM salaries AS s02 
    GROUP BY s02.emp_no
  ) AS r
ON      sal01.emp_no = r.emp_no 
    AND sal01.to_date = r.to_date 
    AND sal01.from_date = r.from_date
GROUP BY sal01.emp_no

;


###########################################################
# Age At Hire In Years
# using total days/365
#	See next section for total days/365.25 calculation
###########################################################
SELECT "Creating Age Tables" AS INFO;
DROP TABLE IF EXISTS employees.employees_hwg02;

CREATE TABLE employees_hwg02
SELECT
  emp01.*
  , ROUND(DATEDIFF(emp01.hire_date, emp01.birth_date),3) AS AgeAtHireDateDays
  , ROUND((DATEDIFF(emp01.hire_date, emp01.birth_date))/365,3) AS AgeAtHireDateYears
FROM employees.employees AS emp01
;


SELECT "Preparing Age Output" AS INFO;
SELECT
    ROUND(AVG(hwg02.AgeAtHireDateYears),3)
FROM employees_hwg02 AS hwg02
INTO @AgeAvg
;

SELECT
  ROUND(STDDEV_SAMP(hwg02.AgeAtHireDateYears),3)
FROM employees_hwg02 AS hwg02
INTO @AgeSD
;

#	Two approaches for calculating median
#	Median calcuation Option 1
DROP TABLE IF EXISTS employees_median_age;

CREATE TABLE employees_median_age
SELECT
  hwg02.AgeAtHireDateYears
FROM employees_hwg02 AS hwg02
ORDER BY hwg02.AgeAtHireDateYears
LIMIT 2 OFFSET 150011
;

SELECT
  AVG(med01.AgeAtHireDateYears)
FROM employees_median_age AS med01
INTO @AgeMedian01
;

#	Median calcuation Option 2
# Source of median function:
#   https://github.com/infusion/udf_infusion
SELECT
  MEDIAN(hwg02.AgeAtHireDateYears)
FROM employees_hwg02 AS hwg02
INTO @AgeMedian02
;


SELECT
    ROUND(@AgeAvg,3)				AS AverageAgeInYrs
  , ROUND(@AgeMedian01,3)		AS MedianAgeInYrs01
  , ROUND(@AgeMedian02,3)		AS MedianAgeInYrs02
  , ROUND(@AgeSD,3)					AS StdDevinYrs
;

###########################################################
# Age At Hire In Years
# using total days/365.25
#
###########################################################
SELECT "Creating Age Tables using 365.25" AS INFO;
DROP TABLE IF EXISTS employees.employees_hwg02_365_25;

CREATE TABLE employees_hwg02_365_25
SELECT
  emp01.*
  , ROUND(DATEDIFF(emp01.hire_date, emp01.birth_date),3) 					AS AgeAtHireDateDays
  , ROUND((DATEDIFF(emp01.hire_date, emp01.birth_date))/365.25,3)	AS AgeAtHireDateYears
FROM employees.employees AS emp01
;

SELECT "Preparing Age Output using 365.25" AS INFO;
SELECT
    ROUND(AVG(hwg02.AgeAtHireDateYears),3)
FROM employees_hwg02_365_25 AS hwg02
INTO @AgeAvg_365_25
;

SELECT
  ROUND(STDDEV_SAMP(hwg02.AgeAtHireDateYears),3)
FROM employees_hwg02_365_25 AS hwg02
INTO @AgeSD_365_25
;

#	Two approaches for calculating median
#	Median calcuation Option 1
DROP TABLE IF EXISTS employees_median_365_25;

CREATE TABLE employees_median_365_25
SELECT
  hwg02.AgeAtHireDateYears
FROM employees_hwg02_365_25 AS hwg02
ORDER BY hwg02.AgeAtHireDateYears
LIMIT 2 OFFSET 150011
;

SELECT
  AVG(med01.AgeAtHireDateYears)
FROM employees_median_365_25 AS med01
INTO @AgeMedian01_365_25
;

#	Median calcuation Option 2
# Source of median function:
#   https://github.com/infusion/udf_infusion
SELECT
  MEDIAN(hwg02.AgeAtHireDateYears)
FROM employees_hwg02_365_25 AS hwg02
INTO @AgeMedian02_365_25
;


SELECT
    ROUND(@AgeAvg_365_25,3)					AS AverageAgeInYrs_Using365_25
  , ROUND(@AgeMedian01_365_25,3)		AS MedianAgeInYrs01_Using365_25
  , ROUND(@AgeMedian02_365_25,3)		AS MedianAgeInYrs02_Using365_25
  , ROUND(@AgeSD_365_25,3)					AS StdDevinYrs_Using365_25
;

#############################
# Add indices to intermediate
#	tables
#############################
SELECT "Adding indexes to intermediate tables" AS INFO;
ALTER TABLE employees_hwg02
    ADD PRIMARY KEY (emp_no)
;

ALTER TABLE dept_emp_nodups
    ADD PRIMARY KEY (emp_no)
  , ADD INDEX (dept_no)
;

ALTER TABLE dept_manager_nodups
    ADD PRIMARY KEY (emp_no)
  , ADD INDEX (dept_no)
;

ALTER TABLE salaries_nodups
  ADD PRIMARY KEY (emp_no)
;


# Assume this index from
#	original source 
#	already exists
#
# Use these statements if not.
/*
#	How to drop an index
#	PRIMARY needs `` as it is a key word

#	Departments
DROP INDEX `PRIMARY` ON departments;
DROP INDEX depet_name ON departments;
ALTER TABLE departments
  ADD PRIMARY KEY (dept_no),
	ADD KEY (dept_name)
;

#	dept_emp
DROP INDEX `PRIMARY` ON dept_emp;
DROP INDEX dept_no ON dept_emp;
ALTER TABLE dept_emp
		ADD PRIMARY KEY (emp_no, dept_no)
	,	ADD INDEX (dept_no)
;

#	dept_manager
DROP INDEX `PRIMARY` ON dept_manager;
DROP INDEX dept_no ON dept_manager;
ALTER TABLE dept_manager
		ADD PRIMARY KEY (emp_no, dept_no)
	,	ADD INDEX (dept_no)
;

#	employees
DROP INDEX `PRIMARY` ON employees;
ALTER TABLE employees
		ADD PRIMARY KEY (emp_no)
;

#	salaries
DROP INDEX `PRIMARY` ON salaries;
ALTER TABLE salaries
		ADD PRIMARY KEY (emp_no, from_date)
;

#	titles
DROP INDEX `PRIMARY` ON titles;
ALTER TABLE titles
		ADD PRIMARY KEY (emp_no, title, from_date)
;
	
*/


###############################################
# Create an all_employees table without titles
#	titles to be added in future exercises
###############################################
SELECT "Creating All Employees Table" AS INFO;
DROP TABLE IF EXISTS all_employees;

CREATE TABLE all_employees
SELECT
    hwg02.emp_no
  , hwg02.birth_date
  , hwg02.first_name
  , hwg02.last_name
  , hwg02.gender
  , hwg02.hire_date
  , hwg02.AgeAtHireDateYears
#	Leave out title info for now
#  , t01.title                 AS  title
#  , t01.from_date             AS  title_from_date
#  , t01.to_date               AS  title_to_date
  , dep01.dept_no             AS  dept_no
  , depName01.dept_name       AS  dept_name
  , dep01.from_date           AS  dept_from_date
  , dep01.to_date             AS  dept_to_date
  , sal01.salary              AS  salary
  , sal01.from_date           AS  salary_from_date
  , sal01.to_date             AS  salary_to_date
  , mgr01.dept_no             AS  mgr_dept
  , mgr01.from_date           AS  mgr_dept_from_date
  , mgr01.to_date             AS  mgr_dept_to_date
  
FROM employees_hwg02 AS hwg02
#LEFT OUTER JOIN titles_nodups       AS t01
#  ON hwg02.emp_no = t01.emp_no
LEFT OUTER JOIN dept_emp_nodups     AS dep01
  ON hwg02.emp_no = dep01.emp_no
LEFT OUTER JOIN salaries_nodups     AS sal01
  ON hwg02.emp_no = sal01.emp_no
LEFT OUTER JOIN dept_manager_nodups AS mgr01
  ON hwg02.emp_no = mgr01.emp_no
LEFT OUTER JOIN departments         AS depName01
  ON dep01.dept_no = depName01.dept_no
;

SELECT "Indexing all_employees" AS INFO;
ALTER TABLE all_employees
		ADD PRIMARY KEY (emp_no)
	,	ADD INDEX (dept_no)
	,	ADD INDEX (last_name)
	,	ADD INDEX (first_name)
;
###############################################
# 
# Salary All Employees:  Average, Median, & StdDev
#
###############################################
SELECT "Preparing output for final 2.4 Exercises (salaries)" AS INFO;
SELECT
  AVG(sal01.salary)
FROM salaries_nodups AS sal01
INTO @SalaryAvg
;

DROP TABLE IF EXISTS salary_median_salary
;
CREATE TABLE salary_median_salary
SELECT
  sal01.salary
FROM salaries_nodups AS sal01
ORDER BY sal01.salary
LIMIT 2 OFFSET 150011
;

SELECT
  AVG(sal01.salary)
FROM salary_median_salary AS sal01
INTO @SalaryMedian01
;


SELECT
  MEDIAN(sal01.salary)
FROM salaries_nodups AS sal01
INTO @SalaryMedian02
;

SELECT
  STDDEV_SAMP(sal01.salary)
FROM salaries_nodups AS sal01
INTO @SalarySD
;

SELECT 
    ROUND(@SalaryAvg,3)       AS AvgSalary_ALL
  , FORMAT(@SalaryMedian01,3) AS MedianSalary_All_Option1
  , FORMAT(@SalaryMedian02,3) AS MedianSalary_All_Option2
  , ROUND(@SalarySD,3)        AS StdDevSalary_All
;

###############################################
# Salary By Gender:  Average, Median, & StdDev
###############################################
SELECT
  AVG(all01.salary)
FROM all_employees AS all01
WHERE all01.gender = 'F'
INTO @SalaryAvgF
;

SELECT
  AVG(all01.salary)
FROM all_employees AS all01
WHERE all01.gender = 'M'
INTO @SalaryAvgM
;

SELECT
  MEDIAN(all01.salary)
FROM all_employees AS all01
WHERE all01.gender = 'F'
INTO @SalaryMedianF
;

SELECT
  MEDIAN(all01.salary)
FROM all_employees AS all01
WHERE all01.gender = 'M'
INTO @SalaryMedianM
;

SELECT
  STDDEV_SAMP(all01.salary)
FROM all_employees AS all01
WHERE all01.gender = 'F'
INTO @SalarySDF
;

SELECT
  STDDEV_SAMP(all01.salary)
FROM all_employees AS all01
WHERE all01.gender = 'M'
INTO @SalarySDM
;

SELECT 
    ROUND(@SalaryAvgF,3)      AS AvgSalary_F
  , FORMAT(@SalaryMedianF,3)  AS MedianSalary_F
  , ROUND(@SalarySDF,3)       AS StdDevSalary_F
;

SELECT 
    ROUND(@SalaryAvgM,3)      AS AvgSalary_M  
  , FORMAT(@SalaryMedianM,3)  AS MedianSalary_M
  , ROUND(@SalarySDM,3)       AS StdDevSalary_M
;

DROP TABLE IF EXISTS output_2_4_a;

CREATE TABLE output_2_4_a
	(
			Exercise			VARCHAR(20) NOT NULL
		,	Exercise_Desc	VARCHAR(50) NOT NULL
		,	Avg_Formatted_Value			VARCHAR(20)	NOT NULL
		,	Median_Formatted_Value	VARCHAR(20) DEFAULT NULL
		,	StdDev_Formatted_Value	VARCHAR(20)	NOT NULL
	) ENGINE=MyISAM DEFAULT CHARSET=utf8
; 

INSERT INTO output_2_4_a
	VALUES 
		('2.4.a.i', 'Age at Hire Date using 365', @AgeAvg, @AgeMedian02, @AgeSD)
	,	('2.4.a.i', 'Age at Hire Date using 365.25', @AgeAvg_365_25, @AgeMedian02_365_25, @AgeSD_365_25)
	,	('2.4.a.ii', 'Salaries', NumToCurrency(@SalaryAvg,3), NumToCurrency(@SalaryMedian01,3), NumToCurrency(@SalarySD,3))
	,	('2.4.a.iii','Salaries:  Female', NumToCurrency(@SalaryAvgF,3), NumToCurrency(@SalaryMedianF,3), NumToCurrency(@SalarySDF,3))
	,	('2.4.a.iii','Salaries:  Male', NumToCurrency(@SalaryAvgM,3), NumToCurrency(@SalaryMedianM,3), NumToCurrency(@SalarySDM,3))
;

SELECT
	*
FROM output_2_4_a
;

###############################################
# Salary By Department
###############################################
SELECT
		''																										AS 'Exercise:  2.4.a.iv'
  ,	all01.dept_no																					AS DeptNum
	,	all01.dept_name																				AS DeptName
  , CONCAT(	'$'
					,	FORMAT(ROUND(AVG(all01.salary),3),3))					AS DeptAvg
  , CONCAT(	'$'
					,	FORMAT(MEDIAN(all01.salary),3))								AS DeptMedian
  , CONCAT(	'$'
					,	FORMAT(ROUND(STDDEV_SAMP(all01.salary),3),3))	AS DeptStdDev
FROM all_employees AS all01

GROUP BY all01.dept_no
;


###############################################
# Manager of department compared with dept
###############################################
/*
#	Get list of managers if needed
SELECT
    all01.emp_no
  , all01.first_name
  , all01.last_name
  , all01.gender
  , all01.hire_date
  , all01.dept_no
  , all01.dept_name
  , all01.dept_from_date
  , all01.dept_to_date
  , all01.salary
  , all01.salary_from_date
  , all01.salary_to_date
  , all01.mgr_dept
  , all01.mgr_dept_from_date
  , all01.mgr_dept_to_date
FROM all_employees AS all01
WHERE all01.mgr_dept IS NOT NULL
ORDER BY all01.mgr_dept
;
*/

/*
#	Get list of managers with salary if needed
SELECT
		''																	AS 'Exercise:  2.4.a.iv By Manager'
  ,	all01.dept_no												AS DeptNum
	,	all01.dept_name											AS DeptName
  , FORMAT(all01.salary,3)							AS MgrSal
	,	all01.emp_no												AS MgrEmpNo
	,	CONCAT(all01.first_name, ' ', all01.last_name) AS MgrName
FROM all_employees AS all01
WHERE all01.mgr_dept IS NOT NULL
;
*/

SELECT
		''																						AS 'Exercise:  2.4.b'
  ,	all01.dept_no																	AS DeptNum
	,	all01.dept_name																AS DeptName
  , CONCAT(	'$'
					,	FORMAT(ROUND(AVG(all01.salary),3),3))	AS DeptAvg
  , CONCAT(	'$'
					,	FORMAT(MEDIAN(all01.salary),3))				AS DeptMedian
	,	CONCAT(	'$'
					,	FORMAT(dm02.salary,3))								AS DeptMgrSalary
	,	CONCAT(dm02.first_name, ' ', dm02.last_name)	AS DeptMgrName
	,	dm01.emp_no																		AS DeptMgrEmpNo
	
	,	CONCAT(	FORMAT(ABS((AVG(all01.salary)-dm02.salary)/((AVG(all01.salary)+dm02.salary)/2))*100,3)
		,	'%')																				AS Avg_PctDiff
	,	CONCAT(	FORMAT(ABS((MEDIAN(all01.salary)-dm02.salary)/((MEDIAN(all01.salary)+dm02.salary)/2))*100,3)
		,	'%')																				AS Median_PcfDiff
		
	, CONCAT(	FORMAT((dm02.salary - AVG(all01.salary))/ABS((AVG(all01.salary)))*100,3)
					,	'%')																	AS Avg_PctChange_ByMgr
	, CONCAT(	FORMAT((AVG(all01.salary)-dm02.salary)/ABS((AVG(dm02.salary)))*100,3)
				,	'%')																		AS Avg_PctChange_ByDept
				
	, CONCAT(	FORMAT((dm02.salary - MEDIAN(all01.salary))/ABS((MEDIAN(all01.salary)))*100,3)
				,	'%')																		AS Median_PctChange_ByMgr

###################################################
#	Style and debugging note
###################################################
#	Check out how function can simplify syntax a bit
#	Same approach as previous columns:
#	, CONCAT(	FORMAT((MEDIAN(all01.salary)-dm02.salary)/ABS((dm02.salary))*100,3)
#				,	'%')																		AS Median_PctChange_ByDept
#	Using function:
	,	NumToPct((MEDIAN(all01.salary)-dm02.salary)/ABS((dm02.salary)),3,100)
																									AS Median_PctChange_ByDept
#	This could be simplified more using a SELECT...INTO @variable
#	then using NumToPct(@variable, 3, 100) AS Median_PctChange_ByDept for
#	the column.  Disadvantage might be multiple SELECT statements to get
#	variables set.
###################################################

FROM all_employees AS all01
LEFT OUTER JOIN dept_manager_nodups dm01
	ON all01.dept_no = dm01.dept_no
INNER JOIN all_employees AS dm02
	ON dm01.emp_no = dm02.emp_no
WHERE all01.mgr_dept IS NULL
GROUP BY all01.dept_no
ORDER BY all01.dept_no
;


