# Index of Scripts
This is a list and brief description of scripts which are contain useful examples of how to do common things in a variety of languages. 

## Node

[parser-data.js](Node/parser-data.js) - Reads and writes large CSV files using pipes

[parser-headings.js](Node/parser-headings.js) - Reads large cvs files and creates unique list of values using pipes

[test-case-converter.js](Node/test-case-convert.js) - Parses CSV files and creates C# test case class using pipes

[extract-text-from-lines.js](Node/extract-text-from-lines.js) - Parses a file line by line and extracts values from each line based on a test. Uses node `readline` in an async self executing function.

## Powershell

[Invoke-Coverage.ps1](Powershell/Invoke-Coverage.ps1) - Runs `dotnet test` with coverage using Coverlet.MSBuild or Coverlet.Collector and merges the results into a report using ReportGenerator.

[New-PullRequest.ps1](Powershell/New-PullRequest.ps1) - Opens your browser to the new pull request page for the current checked out branch. Currently supports Azure DevOps and BitBucket.

[New-Sln.ps1](Powershell/New-Sln.ps1) - Creates a new .sln file for the csproj projects in the current directory matching the directory structure with solution directories.

## SQL

[Current_Sessions.sql](SQL/Current_Sessions.sql) - Selects the sessions currently logged in to the database

[Max_By_Order](SQL/Max_By_Order.sql) - Selects records which have a max value of a grouping using a partition over clause

[Table_Size.sql](SQL/Table_Size.sql) - Returns the sizes of the tables in the database

[Users.sql](SQL/Users.sql) - Creates a login and user and grants it permissions for a table. Also includes scripts to remove user and login
