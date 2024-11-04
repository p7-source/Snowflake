# Securing PII data in Snowflake

Scenario: A company has three departments, engineering, marketing and support. Each of the departments have a manager and three team members. A table exists which contains the employees of each department and the salary for each.  

# Customer requirements:

Objects containing PII data must be segregated and not visible to non PII users

Only managers should be able to see salary information

Employees should only be able to see members of their own department.  

The following example implements the following solutions:

Object Segregation to hide PII objects

Row level security to hide other departments

Data obfuscation to hide sensitive data (salary)

PII enabled roles to control what roles should/should not have access to PII data
