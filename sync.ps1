import-module -force ./EMA-Autotask.psm1
$mappings = Get-Content ./mappings.json | ConvertFrom-Json
Set-Variable -Name mappings -scope Script -Value $mappings


Set-Variable -Name emausername -scope Script -Value "usernamehere"
Set-Variable -Name emapassword -scope Script -Value "passwordhere"

Set-Variable -name autotaskBaseUri -scope Script -Value "https://webservices2.autotask.net" #no trailing slash
Set-Variable -Name autotaskUsername -scope Script -Value "usernamehere"
Set-Variable -Name autotaskSecret -scope Script -Value "secrethere"
Set-Variable -Name autotaskApiIntegrationCode -scope Script -Value "integrationcodehere"


ema-syncCompanies
#autotask-getServices