# Powershell script for syncing EMA License usage to Autotask PSA Contracts
Script aims to provide the billing functionality of https://www.eset.com/int/business/partner/integration/download-autotask-plugin/ for customers using ESET PROTECT Cloud

**Tested with Powershell 7.2.6**

- Note: this script connects to the Autotask pre-release server (webservices2.autotask.net) change the url's if needed. 
- Note2: Expiremental, use at own risk
- Note3: Script currently does not take into account a single company having multiple license-types mapped to the same Autotask Service.e.g. "ESET Protect Entry" and "ESET PROTECT Advanced" both mapped to "IT: Security Software"  in autotask. (the usage value from last license in the list will be the end result of units sent to Autotask PSA for that service. )

**You will have to set up mappings in order to sync data between EMA and Autotask PSA**

to get the relevant information to create mappings you can use: 

- autotask-GetContracts - to get contractId's 
- autotask-GetServices - to get ServiceId's
- ema-SyncCompanies - to get companyPublicId and LicenseProductCode


See mappings.json for example. More detailed instructions can be found in [mappings.md](mappings.md)

once mappings are set-up running ema-SyncCompanies will sync data to Autotask PSA.
see sync.ps1 for example on how to run/configure needed variables

script in action: 
![adjustments](images/adjustments.png)
