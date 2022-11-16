function Set-autotaskContractServiceadjustments {
    param(
        $ServiceID,
        $ContractID,
        $UnitChange
    )

    $Headers = @{
        "accept" = "application/json"
        "Username" = "$AutotaskUsername"
        "Secret" = "$AutotaskSecret"
        "apiIntegrationCode" = "$AutotaskApiIntegrationCode"
    }
    $timestamp = Get-Date -Format o -asUTC
    $Body = @"
    {
        "id": 0,
        "serviceId": $ServiceID,
        "ContractID": $ContractID,
        "unitChange": $UnitChange,
        "effectiveDate": "$Timestamp"
    }
"@
    
    
    Invoke-restMethod -Method Post -Headers $Headers -Body $Body -uri $autotaskBaseUri/aTServicesRest/V1.0/contractServiceAdjustments -contentType 'application/json'
    

}

function Get-autotaskCompanies {
    param(
        $Print
    )
#Get all companies from autotask
$Body = @{
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
$Headers = @{
    "accept" = "application/json"
    "Username" = "$AutotaskUsername"
    "Secret" = "$AutotaskSecret"
    "apiIntegrationCode" = "$AutotaskApiIntegrationCode"
}

$AutotaskCompanies = Invoke-restMethod -Method Get -Headers $Headers -Uri $autotaskBaseUri/aTServicesRest/v1.0/Companies/query -Body $Body
#Loop through the companies
if ($null -ne $print) {
    Write-Host("Printing Companies")
    foreach ($autotaskCompany in $AutotaskCompanies.items) {
       Write-Host("companyId: " + $autotaskCompany.Id + " companyName: " + $autotaskCompany.companyName) 
        #Add check for mapped companies, nothing else is really needed here
    }
}

return $AutotaskCompanies
}


function Get-autotaskContracts {
    
    $Body = @{
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
    
    $Headers = @{
        "accept" = "application/json"
        "Username" = "$AutotaskUsername"
        "Secret" = "$AutotaskSecret"
        "apiIntegrationCode" = "$AutotaskApiIntegrationCode"
    }   
    $AutotaskContracts = Invoke-restMethod -Method Get -Headers $Headers -Uri $AutotaskBaseUri/aTServicesRest/v1.0/Contracts/query -Body $Body
    #Loop through the contracts
    $AutotaskCompanies = autotask-getCompanies

    Write-Host("Printing contracts:")
    foreach ($AutotaskContract in $AutotaskContracts.items){
        $CompanyName = $AutotaskCompanies.items | Where-Object -Property Id -eq $AutotaskContract.companyID
        $CompanyName = $CompanyName[0].companyName
        Write-Host("ContractID: " + $AutotaskContract.Id + " contractCompany: " + $CompanyName + " contractName: " + $AutotaskContract.contractName)  
    }
}

function Get-autotaskServices {

    $Headers = @{
        "accept" = "application/json"
        "Username" = "$AutotaskUsername"
        "Secret" = "$AutotaskSecret"
        "apiIntegrationCode" = "$AutotaskApiIntegrationCode"
    }
#Get services, These will mapped to eSET pRODUCTS. 
$Body = @{
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


$AutotaskServices= Invoke-restMethod -Method Get -Headers $Headers -Uri $autotaskBaseUri/aTServicesRest/v1.0/Services/query -Body $Body
#Loop through the services

Write-Host("Printing services:")
foreach ($AutotaskService in $AutotaskServices.items){
    Write-Host("serviceId: " + $AutotaskService.Id + " serviceName: " + $AutotaskService.name )  

}
}

function Get-autotaskContractServiceUnits {
    param(
        $ContractID,
        $ServiceID
    )


$Headers = @{
    "accept" = "application/json"
    "Username" = "$AutotaskUsername"
    "Secret" = "$AutotaskSecret"
    "apiIntegrationCode" = "$AutotaskApiIntegrationCode"
}
$Body = @{
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
                "field":"serviceID",
                "op":"eq",
                "value":$ServiceID               
            }
        ]
    }
"@
}


$AutotaskContractServices = Invoke-restMethod -Method Get -Headers $Headers -Uri $autotaskBaseUri/aTServicesRest/v1.0/contractServiceUnits/query -Body $Body
#Loop through the contracts
$AutotaskContractServices | convertTo-Json
return $AutotaskContractServices.items[0]

}


function Invoke-EmaAuthenticate {
    $Body = @"
    {
        "username": "$EmaUserName",
        "password": "$EmaPassword"
    }
"@
    
    $AuthResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Token/Get' -Method Post -Headers @{'accept'= '*/*'} -Body $Body -contentType 'application/json'
    
    #accessToken for further aPI reqs
    $JWT = $AuthResponse.accessToken
    Set-Variable -name Headers -scope Script -value @{
        "accept" = "*/*"
        "Authorization" = "Bearer $JWT"
    }
}

function Get-EmaCompanies {
    param(
        $MasterCompanyId
    )
    $Body = @"
    {
        "skip": 0,
        "take": 100,
        "companyId": "$MastercompanyId"
    }
"@
    Write-Host($Body)
    $ChildrenResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Company/Children' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    $Companies = $ChildrenResponse.companies
    Return $Companies
}

function Get-EmaMasterCompanyID {

    #Get Current User
    $CurrentUserResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/User/Current' -Method Get -Headers $Headers
    #Master Company ID
    #$masterCompanyId = $currentUserResponse.company.companyId
    Write-Host ($CurrentUserResponse.company.companyId)
    Return $CurrentUserResponse.company.companyId
}

function Invoke-EmaSyncCompanies {

    $Companies = Get-EmaCompanies -MasterCompanyId (Get-EmaMasterCompanyID)

    foreach ($Company in $Companies) {
        #Get Activated Devices from companies
        Write-Host("used seats for Customer: " + $Company.name + " company ID: " + $company.publicId) -foregroundColor Green

        $CompanyPublicId = $Company.publicId

        $Body = @"
        {
            "skip": 0,
            "take": 100,
            "customerId": "$CompanyPublicId"
        }
"@

        $ActivatedDevicesResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Search/Licenses' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
        $PublicLicenseId = $ActivatedDevicesResponse.Search.publicLicenseKey


        foreach ($PublicId in $PublicLicenseId) {
            $Body = @"
            {
                "publicLicenseKey": "$PublicId"
            } 
"@
            Write-Host($body)
            $LicenseDetails = Invoke-Restmethod -Uri 'https://mspapi.eset.com/api/License/Detail' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
            Write-Host($LicenseDetails.productName + " - " + $LicenseDetails.publicLicenseKey + " seats:" + $LicenseDetails.usage + " productCode: " + $LicenseDetails.productCode)

            #Find Autotask Contract for this company
            $ContractID = $mappings.companyMappings | Where-Object -Property "emaCompanyPublicId" -eq "$companyPublicId"
            #$ContractID
            if ($null -ne $ContractID) {
                #Find Autotask Service ID for current license 
                $serviceID = $mappings.licenseProductMappings | Where-Object -Property "emaLicenseProductCode" -eq $LicenseDetails.productCode

                if ($null -ne $serviceID) {
                    Write-Host("Comparing count in autoTask") -foregroundColor Cyan
                    $AutotaskUnits = Get-AutotaskContractServiceUnits -ContractID $ContractID.autoTaskContractID -serviceID $ServiceID.autotaskServiceId
                    #Write-Host("ContractID: " + $ContractID + " serviceId: " + $serviceID)
                    #$AutotaskUnits.units
                    if ($null -ne $AutotaskUnits) {
                        $Adjustment = ($LicenseDetails.usage - $AutotaskUnits.units)
                        if ($LicenseDetails.usage -gt $AutotaskUnits.units){
                            Write-Host("eSET Count higher than Autotask, adjustment to make: " + $Adjustment)
                            Write-Host("Making Adjustment in autotask") -foregroundColor Green
                            Set-AutotaskContractServiceadjustments -ServiceID $ServiceID.autotaskServiceId -ContractID $ContractID.autoTaskContractID -unitChange $Adjustment
                        } 
                        if ($LicenseDetails.usage -lt $AutotaskUnits.units) {
                            Write-Host("eSET Count lower than Autotask, adjustment to make: " + $Adjustment)
                            if ($AutotaskUnits.units -eq 1) {
                                Write-Host("autotaskCount cannot be 0, skipping") -foregroundColor darkRed
                            } else {
                                write-Host("Making adjustment in autotask") -foregroundColor Green
                                Set-AutotaskContractServiceadjustments -erviceID $ServiceID.autotaskServiceId -ContractID $ContractID.autoTaskContractID -unitChange $Adjustment
                            
                            }
                        }
                        if ($LicenseDetails.usage -eq $AutotaskUnits.units) {
                            Write-Host("eSET Count matches Autotask Count, no update needed")
                        }
                    } else { 
                        Write-Error("failed to get data from Autotask")
                    }
                } else { 
                    Write-Host("License not mapped to any service") -foregroundColor darkYellow
                }
            } else {
                Write-Host("Company not mapped") -foregroundColor darkYellow
            }           
        }
    }
}




