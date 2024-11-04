use role sysadmin;
--create a warehouse to use if it does not exists
create warehouse if not exists adhoc_wh with
warehouse_size = XSMALL,
initially_suspended = TRUE;

--create roles
--Securityadmin can only create the the roles hahahaha
use role securityadmin;

create role eng_manager_role_pii;
create role engineer_role_nonPII;
create role marketing_manager_role_pii;
create role marketing_role_nonPII;
create role support_manager_role_PII;
create role support_role_nonPII;

--grant roles to yourself for demo
use role sysadmin;
grant role eng_manager_role_pii to user prassadht;
grant role engineer_role_nonPII to user prassadht;
grant role marketing_manager_role_pii to user prassadht;
grant role marketing_role_nonPII to user prassadht;
grant role support_manager_role_PII to user prassadht;
grant role support_role_nonPII to user prassadht;


--create database for demo
use role sysadmin;
create database PII_demo;

--create PII and nonPII schema for object segregation
use role sysadmin;
use PII_demo;
create schema PII;
create schema nonPII;

--create table with PII data
use role sysadmin;
create table pii_demo.pii.employees(
firstname varchar,
lastname varchar,
salary number,
department varchar,
role_name varchar
);

--insert data into employees
use role sysadmin;

insert into pii_demo.pii.employees (firstname, lastname, salary, department, role_name) VALUES
--manager for engineering
('John', 'Smith', 200000, 'engineering', 'eng_manager_role_pii')
--engineering team members
,('Juan', 'Jackson', 135000, 'engineering', 'engineer_role_nonPII')
,('Helen', 'Peters', 160000, 'engineering', 'engineer_role_nonPII')  
,('Carl', 'Lynch', 150000, 'engineering', 'engineer_role_nonPII')
--manager for marketing
,('Linda', 'Estrada', 220000, 'marketing', 'marketing_manager_role_pii' )
--marketing team
,('Jacob', 'Patel', 150000, 'marketing', 'marketing_role_nonPII')
,('Linda', 'Estrada', 220000, 'marketing', 'marketing_role_nonPII')
,('Lori', 'Rodgers', 180000, 'marketing', 'marketing_role_nonPII')
--support manager
,('Megan', 'Beck', 175000, 'support', 'support_manager_role_PII')
--support team
,('Mark', 'Arnolds', 130000, 'support', 'support_role_nonPII')
,('Linda', 'Estrada', 120000, 'support', 'support_role_nonPII')
,('Brandon', 'Hariison', 140000, 'support', 'support_role_nonPII');



--create mapping table for PII roles
use role sysadmin;
create table pii_demo.pii.pii_mappings ( department varchar, role varchar, pii_access number);
--insert data to mapping table
insert into pii_demo.pii.pii_mappings (department, role, pii_access) values
('engineering', 'eng_manager_role_pii', 1)
,('engineering', 'engineer_role_nonPII', 0)
,('marketing', 'marketing_manager_role_pii', 1)
,('marketing', 'marketing_role_nonPII', 0)
,('support', 'support_manager_role_PII', 1)
,('support', 'support_role_nonPII', 0);

use role sysadmin;
--create protected view that 1) all employees only see their department, 2) only managers see salary
create view pii_demo.nonpii.employee_protected as select
employees.firstname,
employees.lastname,
employees.department,
case when pii_mappings.pii_access = 1 then employees.salary else 0
end as salary
from pii_demo.pii.employees
inner join pii_demo.pii.pii_mappings on employees.department = pii_mappings.department
where UPPER(pii_mappings.role) = current_role();

--assign privileges to roles
--database usage
grant usage on database PII_demo to role eng_manager_role_pii;
grant usage on database PII_demo to role engineer_role_nonPII;
grant usage on database PII_demo to role marketing_manager_role_pii;
grant usage on database PII_demo to role marketing_role_nonPII;
grant usage on database PII_demo to role support_manager_role_PII;
grant usage on database PII_demo to role support_role_nonPII;
--schema usage to non pii schema only
grant usage on schema nonPII to role eng_manager_role_pii;
grant usage on schema nonPII to role engineer_role_nonPII;
grant usage on schema nonPII to role marketing_manager_role_pii;
grant usage on schema nonPII to role marketing_role_nonPII;
grant usage on schema nonPII to role support_manager_role_PII;
grant usage on schema nonPII to role support_role_nonPII;
--grant select on view to all roles
grant select on employee_protected to role eng_manager_role_pii;
grant select on employee_protected to role engineer_role_nonPII;
grant select on employee_protected to role marketing_manager_role_pii;
grant select on employee_protected to role marketing_role_nonPII;
grant select on employee_protected to role support_manager_role_PII;
grant select on employee_protected to role support_role_nonPII;
--warehouse usage
grant usage on warehouse adhoc_wh to role eng_manager_role_pii;
grant usage on warehouse adhoc_wh to role engineer_role_nonPII;
grant usage on warehouse adhoc_wh to role marketing_manager_role_pii;
grant usage on warehouse adhoc_wh to role marketing_role_nonPII;
grant usage on warehouse adhoc_wh to role support_manager_role_PII;
grant usage on warehouse adhoc_wh to role support_role_nonPII;


--test object segregation (will fail with object does not exist)
use role eng_manager_role_pii;
select * from pii_demo.pii.employees;


--test RLS & obfuscation
--eng manager sees their team (shows 4 rows with salaries)
use role eng_manager_role_pii;
select * from employee_protected;


--non pii engineer team don't see salary, but sees team (shows 4 rows with salary = 0)
use role engineer_role_nonpii;
select * from employee_protected;

--marketing manager sees their team(shows 4 rows with salaries)
use role marketing_manager_role_pii;
select * from employee_protected;

--marketing employees don't see salary(shows 4 rows with salary = 0)
use role marketing_role_nonpii;
select * from employee_protected;

--same with support (shows 4 rows with salaries)
use role support_manager_role_pii;
select * from employee_protected;

--non pii support engineers but not salary (show 4 rows but no salary)
use role support_role_nonpii;
select * from employee_protected;

--cleanup
use role securityadmin ;
drop role if exists eng_manager_role_pii;
drop role if exists engineer_role_nonPII;
drop role if exists marketing_manager_role_pii;
drop role if exists marketing_role_nonPII;
drop role if exists support_manager_role_PII;
drop role if exists support_role_nonPII;

use role sysadmin;
drop view if exists nonpii.employee_protected;
drop table if exists pii.employees;
drop database if exists pii_demo;