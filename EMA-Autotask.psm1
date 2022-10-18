function autotask-ContractServiceadjustments {
    param(
        $serviceID,
        $contractId,
        $unitChange
    )

    $headers = @{
        "accept" = "application/json"
        "Username" = "$autotaskUsername"
        "Secret" = "$autotaskSecret"
        "ApiIntegrationCode" = "$autotaskApiIntegrationCode"
    }
    $timestamp = Get-Date -Format o -AsUTC
    $body = @"
    {
        "id": 0,
        "serviceId": $serviceID,
        "contractId": $contractId,
        "unitChange": $unitChange,
        "effectiveDate": "$timestamp"
    }
"@
    
    
    Invoke-RestMethod -Method Post -Headers $headers -Body $body -uri $autotaskBaseUri/ATServicesRest/V1.0/ContractServiceAdjustments -ContentType 'application/json'
    

}

function autotask-GetCompanies {
    param(
        $print
    )
#Get all companies from autotask
$body = @{
    search =@"
    {
        "Filter":
        [
            {
                "field":"Id",
                "op":"gte",
                "value":0
            }
        ]
    }
"@
}
$headers = @{
    "accept" = "application/json"
    "Username" = "$autotaskUsername"
    "Secret" = "$autotaskSecret"
    "ApiIntegrationCode" = "$autotaskApiIntegrationCode"
}

$autotaskCompanies = Invoke-RestMethod -Method Get -Headers $headers -Uri $autotaskBaseUri/ATServicesRest/v1.0/Companies/query -Body $body
#Loop through the companies
if ($null -ne $print) {
    Write-Host("Printing Companies")
    foreach ($autotaskCompany in $autotaskCompanies.items) {
       Write-Host("companyId: " + $autotaskCompany.Id + " companyName: " + $autotaskCompany.companyName) 
        #Add check for mapped companies, nothing else is really needed here
    }
}

return $autotaskCompanies
}


function autotask-GetContracts {
    
    $body = @{
        search =@"
        {
            "Filter":
            [
                {
                    "field":"Id",
                    "op":"gte",
                    "value":0
                }
            ]
        }
"@
    }
    
    $headers = @{
        "accept" = "application/json"
        "Username" = "$autotaskUsername"
        "Secret" = "$autotaskSecret"
        "ApiIntegrationCode" = "$autotaskApiIntegrationCode"
    }   
    $autotaskContracts = Invoke-RestMethod -Method Get -Headers $headers -Uri $autotaskBaseUri/ATServicesRest/v1.0/Contracts/query -Body $body
    #Loop through the contracts
    $autoTaskCompanies = autotask-GetCompanies

    Write-Host("Printing contracts:")
    foreach ($autotaskContract in $autotaskContracts.items){
        $companyName = $autoTaskCompanies.items | Where-Object -Property Id -eq $autotaskContract.companyID
        $companyName = $companyName[0].companyName
        Write-Host("contractId: " + $autotaskContract.Id + " contractCompany: " + $companyName + " contractName: " + $autotaskContract.contractName)  
    }
}

function autotask-getServices {

    $headers = @{
        "accept" = "application/json"
        "Username" = "$autotaskUsername"
        "Secret" = "$autotaskSecret"
        "ApiIntegrationCode" = "$autotaskApiIntegrationCode"
    }
#Get services, These will mapped to ESET PRODUCTS. 
$body = @{
    search =@"
    {
        "Filter":
        [
            {
                "field":"Id",
                "op":"gte",
                "value":0
            }
        ]
    }
"@
}


$autotaskServices= Invoke-RestMethod -Method Get -Headers $headers -Uri $autotaskBaseUri/ATServicesRest/v1.0/Services/query -Body $body
#Loop through the services

Write-Host("Printing services:")
foreach ($autotaskService in $autotaskServices.items){
    Write-Host("ServiceId: " + $autotaskService.Id + " serviceName: " + $autotaskService.name )  

}
}

function autotask-getContractServiceUnits {
    param(
        $ContractID,
        $ServiceID
    )


$headers = @{
    "accept" = "application/json"
    "Username" = "$autotaskUsername"
    "Secret" = "$autotaskSecret"
    "ApiIntegrationCode" = "$autotaskApiIntegrationCode"
}
$body = @{
    search =@"
    {
        "Filter":
        [
            {
                "field":"ContractID",
                "op":"eq",
                "value":$ContractID
            },
            {
                "field":"ServiceID",
                "op":"eq",
                "value":$ServiceID               
            }
        ]
    }
"@
}


$autotaskContractServices = Invoke-RestMethod -Method Get -Headers $headers -Uri $autotaskBaseUri/ATServicesRest/v1.0/ContractServiceUnits/query -Body $body
#Loop through the contracts
$autotaskContractServices | ConvertTo-Json
return $autotaskcontractServices.items[0]

}


function ema-authenticate {
    $body = @"
    {
        "username": "$emausername",
        "password": "$emapassword"
    }
"@
    
    $authResponse = Invoke-RestMethod -Uri 'https://mspapi.eset.com/api/Token/Get' -Method Post -Headers @{'accept'= '*/*'} -Body $body -ContentType 'application/json'
    
    #accessToken for further API reqs
    $JWT = $authResponse.accessToken
    Set-Variable -name headers -scope Script -value @{
        "accept" = "*/*"
        "Authorization" = "Bearer $JWT"
    }
}

function ema-SyncCompanies {
    ema-authenticate
#Get Current User
$currentUserResponse = Invoke-RestMethod -Uri 'https://mspapi.eset.com/api/User/Current' -Method Get -Headers $headers
#Master Company ID
$masterCompanyId = $currentUserResponse.company.companyId

#Get list of child companies (customers)


$body = @"
{
    "skip": 0,
    "take": 100,
    "companyId": "$MastercompanyId"
}
"@
$childrenResponse = Invoke-RestMethod -Uri 'https://mspapi.eset.com/api/Company/Children' -method Post -Headers $headers -Body $body -ContentType 'application/json'
$companies = $childrenResponse.companies

foreach ($company in $companies) {
#Get Activated Devices from companies
Write-Host("used seats for Customer: " + $Company.name + " company ID: " + $company.publicId) -ForegroundColor Green

$companyPublicId = $company.publicId

    $body = @"
    {
        "skip": 0,
        "take": 100,
        "customerId": "$companyPublicId"
    }
"@

    $activatedDevicesResponse = Invoke-RestMethod -Uri 'https://mspapi.eset.com/api/Search/Licenses' -method Post -Headers $headers -Body $body -ContentType 'application/json'
    $publicLicenseId = $activatedDevicesResponse.Search.PublicLicenseKey


    foreach ($publicId in $publicLicenseId) {
        $body = @"
        {
            "publicLicenseKey": "$publicId"
        } 
"@
    $licenseDetails = Invoke-Restmethod -Uri 'https://mspapi.eset.com/api/License/Detail' -method Post -Headers $headers -Body $body -ContentType 'application/json'
    Write-Host($licenseDetails.productName + " - " + $licenseDetails.publicLicenseKey + " seats:" + $licenseDetails.usage + " productCode: " + $licenseDetails.productCode)

    #Find Autotask Contract for this company
    $contractID = $mappings.companyMappings | Where-Object -Property "EmaCompanyPublicId" -eq "$companyPublicId"
    #$contractID
    if ($null -ne $contractID) {

         #Find Autotask Service ID for current license 
        $serviceID = $mappings.licenseProductMappings | Where-Object -Property "EmaLicenseProductCode" -eq $licenseDetails.ProductCode

        if ($null -ne $serviceID) {
            Write-Host("Comparing count in AutoTask") -ForegroundColor Cyan
            $AutotaskUnits = autotask-getContractServiceUnits -ContractID $contractID.AutoTaskContractId -ServiceID $ServiceID.AutotaskServiceId
            #Write-Host("ContractID: " + $contractID + " ServiceId: " + $serviceID)
            #$AutotaskUnits.units
            if ($null -ne $AutotaskUnits) {
                $adjustment = ($licenseDetails.usage - $AutotaskUnits.units)
                if ($licenseDetails.usage -gt $AutotaskUnits.units){
                    
                    Write-Host("ESET Count higher than Autotask, adjustment to make: " + $adjustment)
                    Write-Host("Making Adjustment in autotask") -ForegroundColor Green
                    autotask-ContractServiceadjustments -serviceID $ServiceID.AutotaskServiceId -contractId $contractID.AutoTaskContractId -unitChange $adjustment
                    
                } 
                if ($licenseDetails.usage -lt $AutotaskUnits.units) {
                    Write-Host("ESET Count lower than Autotask, adjustment to make: " + $adjustment)
                    if ($AutotaskUnits.units -eq 1) {
                        Write-Host("AutotaskCount cannot be 0, skipping") -ForegroundColor DarkRed
                    } else {
                        write-Host("Making adjustment in autotask") -ForegroundColor Green
                        autotask-ContractServiceadjustments -serviceID $ServiceID.AutotaskServiceId -contractId $contractID.AutoTaskContractId -unitChange $adjustment
                    
                    }
                }
                if ($licenseDetails.usage -eq $AutotaskUnits.units) {
                    Write-Host("ESET Count matches Autotask Count, no update needed")
                }
            } else { 
                Write-Error("failed to get data from Autotask")
            }

        } else { 
            Write-Host("License not mapped to any service") -ForegroundColor DarkYellow
        }

    } else {
        Write-Host("Company not mapped") -ForegroundColor DarkYellow
    }

    
    }


 
}
}




