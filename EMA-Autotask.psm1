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
#Get services, These will mapped to ESET pRODUCTS. 
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
    search = @"
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
    Write-Debug($Body)
    $ChildrenResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Company/Children' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    $Companies = $ChildrenResponse.companies
    Return $Companies
}

function Get-EmaMasterCompanyID {

    #Get Current User
    $CurrentUserResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/User/Current' -Method Get -Headers $Headers
    #Master Company ID
    #$masterCompanyId = $currentUserResponse.company.companyId
    Write-Debug ($CurrentUserResponse.company.companyId)
    Return $CurrentUserResponse.company.companyId
}

function Get-EmaCompanyLicenses {
    param(
        $CompanyPublicId
    )
    $Body = @"
    {
        "skip": 0,
        "take": 100,
        "customerId": "$CompanyPublicId"
    }
"@

    $LicensesResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Search/Licenses' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    $PublicLicenseId = $LicensesResponse.Search.publicLicenseKey

    return $PublicLicenseId
}

function Get-EmaLicenseDetails {
    param(
        $PublicLicenseKey
    )
    $Body = @"
    {
        "publicLicenseKey": "$PublicId"
    } 
"@
    Write-Debug($body)
    $LicenseDetails = Invoke-Restmethod -Uri 'https://mspapi.eset.com/api/License/Detail' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    Return $LicenseDetails
}
function Invoke-EmaSyncCompanies {
    param(
        [switch]$DryRun
    )

    $Companies = Get-EmaCompanies -MasterCompanyId (Get-EmaMasterCompanyID)

    foreach ($Company in $Companies) {
        #Get Activated Devices from companies
        Write-Host("used seats for Customer: " + $Company.name + " company ID: " + $company.publicId) -foregroundColor Green

        foreach ($PublicId in (Get-EmaCompanyLicenses -CompanyPublicId $Company.publicId)) {
            $LicenseDetails = (Get-EmaLicenseDetails -PublicLicenseKey $PublicId)
            Write-Host($LicenseDetails.productName + " - " + $LicenseDetails.publicLicenseKey + " seats:" + $LicenseDetails.usage + " productCode: " + $LicenseDetails.productCode)

            #Find Autotask Contract for this company
            $ContractID = $Mappings.companyMappings | Where-Object -Property "emaCompanyPublicId" -eq "$companyPublicId"
            #$ContractID
            if ($null -ne $ContractID) {
                #Find Autotask Service ID for current license 
                $serviceID = $Mappings.licenseProductMappings | Where-Object -Property "emaLicenseProductCode" -eq $LicenseDetails.productCode

                if ($null -ne $serviceID) {
                    Write-Host("Comparing count in autoTask") -foregroundColor Cyan
                    $AutotaskUnits = Get-AutotaskContractServiceUnits -ContractID $ContractID.AutoTaskContractID -serviceID $ServiceID.autotaskServiceId
                    #Write-Host("ContractID: " + $ContractID + " serviceId: " + $serviceID)
                    #$AutotaskUnits.units
                    if ($null -ne $AutotaskUnits) {
                        $Adjustment = ($LicenseDetails.usage - $AutotaskUnits.units)
                        if ($LicenseDetails.usage -gt $AutotaskUnits.units){
                            Write-Host("ESET Count higher than Autotask, adjustment to make: " + $Adjustment)
                            if (!$DryRun) {
                                Write-Host("Making Adjustment in autotask") -foregroundColor Green
                                Set-AutotaskContractServiceadjustments -ServiceID $ServiceID.autotaskServiceId -ContractID $ContractID.autoTaskContractID -unitChange $Adjustment
                            }

                        } 
                        if ($LicenseDetails.usage -lt $AutotaskUnits.units) {
                            Write-Host("ESET Count lower than Autotask, adjustment to make: " + $Adjustment)
                            if (!$DryRun) {
                                if ($AutotaskUnits.units -eq 1) {
                                    Write-Host("AutotaskCount cannot be 0, skipping") -foregroundColor darkRed
                                } else {
                                    write-Host("Making adjustment in autotask") -foregroundColor Green
                                    Set-AutotaskContractServiceadjustments -ServiceID $ServiceID.autotaskServiceId -ContractID $ContractID.autoTaskContractID -unitChange $Adjustment
                                
                                }
                            }

                        }
                        if ($LicenseDetails.usage -eq $AutotaskUnits.units) {
                            Write-Host("ESET Count matches Autotask Count, no update needed")
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

function Invoke-EmaSyncCompaniesExperimental {
    param(
        [switch]$DryRun
    )
    #Get all companies in EMA
    $Companies = Get-EmaCompanies -MasterCompanyId (Get-EmaMasterCompanyID)
    #Loop through all companies
    foreach ($Company in $Companies) {
        #Find Autotask Contract for this company
        $ContractID = $null
        $CompanyPublicId = $Company.publicId
        $ContractID = $Mappings.companyMappings | Where-Object -Property "EmaCompanyPublicId" -eq "$CompanyPublicId"
        Write-Host ($mappings.companyMappings | Where-Object {$_.EmaCompanyPublicId -eq "b3991cba-e3a6-45d6-b260-201139220069"})
        Write-Host("used seats for Customer: " + $Company.name + " company ID: " + $CompanyPublicId) -foregroundColor Green
        #Check if there the company has a mapped contract
        if ($null -ne $ContractID) {
            #Get ActivatedDevices for company
            $ActivatedDevices = Get-MSPActivatedDevices -CompanyPublicId "$CompanyPublicId"
            Write-Host("Total activated devices: " + $ActivatedDevices.Count)
            #Find Activated devices count for mapped products
            $ActivatedDevicesPerServiceCount = @{}

            foreach ($Product in $Mappings.ProductServiceMappings) {
                
                #Get Count of activated devices for this product
                $EsetProductName = $Product.EsetProductName
                $FilteredActivatedDevices = $ActivatedDevices | Where-Object {$_.ProductName -eq "$EsetProductName"}
                Write-Host("Number of activated " + $EsetProductName + ": " + $FilteredActivatedDevices.Count)
                #Store Activated devices in relevant service for later use
                $AutotaskServiceId = $Product.AutotaskServiceId
                $ActivatedDevicesPerServiceCount.$AutotaskServiceId += $FilteredActivatedDevices.Count
                #$ActivatedDevicesPerServiceCount
            }

            #Check if Autotask Contracts need updating:
            foreach ($ServiceId in $ActivatedDevicesPerServiceCount.Keys) {
                
                Write-Host("Comparing count in autoTask") -foregroundColor Cyan
                Write-Host("ContractId :" + $ContractID.AutoTaskContractID + " ServiceID :" + $ServiceId)
                $AutotaskUnits = Get-AutotaskContractServiceUnits -ContractID $ContractID.autoTaskContractID -serviceID $ServiceId
                
                if ($null -ne $AutotaskUnits) {
                    $Adjustment = ($ActivatedDevicesPerServiceCount[$ServiceId] - $AutotaskUnits.units)
                    if ($ActivatedDevicesPerServiceCount[$ServiceId] -gt $AutotaskUnits.units) {
                        Write-Host("ESET Count higher than Autotask, adjustment to make: " + $Adjustment)
                        if (!$DryRun) {
                            Write-Host("Making Adjustment in autotask") -foregroundColor Green
                            Set-AutotaskContractServiceadjustments -ServiceID $Service -ContractID $ContractID.autoTaskContractID -unitChange $Adjustment
                        }
                    }
                    if ($ActivatedDevicesPerServiceCount[$Service] -lt $AutotaskUnits.units) {
                        Write-Host("ESET Count lower than Autotask, adjustment to make: " + $Adjustment)
                        if (!$DryRun) {
                            if ($AutotaskUnits.units -eq 1) {
                                Write-Host("AutotaskCount cannot be 0, skipping") -foregroundColor darkRed
                            } else {
                                write-Host("Making adjustment in autotask") -foregroundColor Green
                                Set-AutotaskContractServiceadjustments -ServiceID $Service.Keys -ContractID $ContractID.autoTaskContractID -unitChange $Adjustment                    
                            }
                        }  
                    }
                    if ($LicenseDetails.usage -eq $AutotaskUnits.units) {
                             Write-Host("ESET Count matches Autotask Count, no update needed")
                    }
                } else { 
                    Write-Error("failed to get data from Autotask")
                }
            }
        } else {
            Write-Host("Company not mapped") -foregroundColor darkYellow
        }           
    }  
}
Function Invoke-MSPAuth {
    param(
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials = [System.Management.Automation.PSCredential]::Empty
    )

    $EMAUsername = $Credentials.UserName
    $EMAPassword = $Credentials.GetNetworkCredential().Password

    $Req1 = Invoke-RestMethod -Uri "https://msp.eset.com/" -SessionVariable "MSPWebSession" -Method Get 

    $String = ""
    foreach ($Input in $Req1.html.body.form.input) {
        $String += $Input.name + "=" + $Input.value + "&"
    }
    
    $Headers = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }   

    $Req2 = Invoke-RestMethod -Uri "https://identity.eset.com/connect/authorize" -Headers $Headers -Body $String -WebSession $MSPWebSession  -Method Post
    Write-Debug($Req2)

    $AuthRequestBody = @"

    {
        "email":"$EMAUsername",
        "password":"$EMAPassword",
        "returnUrl":"/connect/authorize/callback?client_id=Eset.EMA&redirect_uri=https%3A%2F%2Fmsp.eset.com%2Fsignin-oidc&response_type=id_token&scope=openid%20profile%20eset_id%20email&response_mode=form_post&nonce=638037494342872703.ZjY2ZGVhZmItNTg0OS00YjY4LWI1MjItMDdiYTUwMThiYjBhMTAwOGE0NGEtNTA0Ni00NTQ2LTk4NjctYTVhM2VjY2NjMDVh&state=CfDJ8Nnqx--2_JFPowt7UuOn-xONtIG2keuTLqVbrjfhlqenUEL5SwohdOAIFiddj6olw6bquyRMfRbNSwzGNrMjeFOseIlFLmXZpkkFKn4i_nXMR2loTaFZIKH3g4zLQUBPma6UFqo1okXvGCKfA8ketVrGYERPVZh6s-9tR0uYqLriR3z6TOrOyqOQOpoGw81DwSGFF6nAevx8Hzfa49ojRW66jyiJscjW6WMyNCGtBipbRK_AeFzRUN6_kpAV2F2VemfwHZXQ860v2mdqO11QJ8gn83DqBQd1LRfL-kPXTYjL"
    }
"@


    $Headers = @{
        "Content-Type" = "application/json"
    }
    $AuthReq = Invoke-RestMethod -uri "https://identity.eset.com/api/login/pwd" -Method Post -Headers $Headers -WebSession $MSPWebSession -Body $AuthRequestBody 
    Write-debug($AuthReq)

    $Req3 = Invoke-Restmethod -uri "https://identity.eset.com/connect/authorize/callback?$String" -Method Get -WebSession $MSPWebSession 

    $String = ""
    foreach ($Input in $Req3.html.body.form.input) {
        $String += $Input.name + "=" + $Input.value + "&"
    }

    $Headers = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }
    $Req4 = Invoke-RestMethod -uri "https://msp.eset.com/signin-oidc" -Method Post -WebSession $MSPWebSession -Body $string -Headers $Headers 
    Write-Debug($Req4)

    Set-Variable -Scope Script -Name MSPWebSession -Value $MSPWebSession
}

Function Get-MSPActivatedDevices {
    param(
        $CompanyPublicId
    )
    $ActivatedDevicesBody = @"
    {
        "ContinuationToken":null,
        "ItemsPerPage":20,
        "PublicLicenseKey":null,
        "LicenseProductCode":null,
        "SearchColumn":1,
        "SearchColumnContains":null,
        "CompanyPublicId":"$CompanyPublicId",
        "SortColumn":null,
        "SortDescending":null,
        "Statuses":null,
        "IgnoreLicensePool":true,
        "ExtendQuery":
        {
            "skip":0,
            "take":5000,
            "filters":{},
            "orderBy":0,
            "orderAsc":true,
            "publicId":null
        }
    }
"@
    $Headers = @{
        "Content-Type" = "application/json"
    }
    $ActivatedDevicesReq = Invoke-RestMethod -Uri "https://msp.eset.com/api/seats/search" -Method Post -Headers $Headers -WebSession $MSPWebSession -Body $ActivatedDevicesBody
    $ActivatedDevicesReq.Units.Applications
}


