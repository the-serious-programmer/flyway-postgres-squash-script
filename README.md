# Flyway postgres squash script
Script to squash flyway migrations to one migration script with a postgres database.


This script is based on: https://medium.com/att-israel/flyway-squashing-migrations-2993d75dae96.  
Please read this article before continuing.

In short: we wish to squash a lot of SQL files into one 'baseline' SQL file, basically starting flyway fresh again.
To do so we will have to generate a squashed migration file and create the `flyway_schema_history` table from scratch on every database environment flyway  already ran on.


In this script you can run two steps:
1. Creating a squashed migration (Create and Delete step from the article). This will delete all the SQL files in the current directory and create a schema-only dump with pg_dump.  
2. Preparing a database for the squashed migration (Rename step from the article). This will rename the `flyway_schema_history` table, so that flyway can be ran afterwards with the squashed migration file to create a new flyway_schema_history table.  

**NOTE** you will probably have to execute step 1 once and you will probably have to execute step 2 multiple times, for each database environment that already ran flyway.  

**NOTE** it is assumed you run the Baseline step (actually running flyway) from the article separately from this script (with for instance spring data on start-up of your application or with maven).  

**NOTE** this Baseline step (actually running flyway) should be done shortly after running step 2 to prevent for instance an application restart searching for a non existing flyway table.  
