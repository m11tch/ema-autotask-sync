Powershell script for syncing EMA License usage to Autotask PSA Contracts

Note: this script connects to the Autotask pre-release server (webservices2.autotask.net) change the url's if needed. 

Note2: Expiremental, use at own risk

Note3: Script currently does not take into account a single company having multiple license-types mapped to the same Autotask Service. (the value from last license in the list will be the end result of units sent to Autotask PSA for that service. )


You will have to set up mappings in order to sync data between EMA and Autotask PSA

to get the relevant information to create mappings you can use: 

autotask-GetContracts - to get contractId's 

autotask-GetServices - to get ServiceId's

ema-SyncCompanies - to get companyPublicId and LicenseProductCode


see mappings.json for example

once mappings are set-up running ema-SyncCompanies will sync data to Autotask PSA.