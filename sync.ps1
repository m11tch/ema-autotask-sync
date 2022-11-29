import-module -force ./EMA-Autotask.psm1
$mappings = Get-Content ./mappings.json | ConvertFrom-Json
Set-Variable -Name mappings -scope Script -Value $mappings


Set-Variable -Name emausername -scope Script -Value "usernamehere"
Set-Variable -Name emapassword -scope Script -Value "passwordhere"

Set-Variable -name autotaskBaseUri -scope Script -Value "https://webservices2.autotask.net" #no trailing slash
Set-Variable -Name autotaskUsername -scope Script -Value "usernamehere"
Set-Variable -Name autotaskSecret -scope Script -Value "secrethere"
Set-Variable -Name autotaskApiIntegrationCode -scope Script -Value "integrationcodehere"

Invoke-EmaAuthenticate
Invoke-EmaSyncCompanies
#If you don't want to make changes in autotask you can execute: 
#Invoke-EmaSyncCompanies -DryRun

#If you want to use mapping based on Activated device product name instead of license type (this allows you to map individual products within a bundle license to different services e.g. ESET Server Security to service X and ESET Endpoint Security to Service Y)
#Invoke-EmaSyncCompaniesExperimental
#If you don't want to make changes in autotask you can execute: 
#Invoke-EmaSyncCompanies -DryRun

