# Azure Information Protection: Bulk Encryption Script
This repo contains a database schema and PowerShell scripts to enable an organisation to rapidly protect a list of known documents using Azure Information Protection (AIP).

**NOTICE: The scripts here are NOT developed or supported by Microsoft and come with NO warranty or assurance. Use at your own risk, and always test thoroughly in a Dev and Test environment first.**

>This repo should only be used in instances where the AIP Scanner cannot be used - the AIP Scanner is the fully developed and supported mechanism to protect files across the enterprise.

The database contains the list of files to be processed. The script can run concurrently on any number of servers. Each script instance will retrieve a batch of rows from the database and label/protect those files using AIP.  Success / failure for each file is logged back to the database. 

## Setup
**1. Setup Azure Authentication**. This script uses the mechanism outlined in the docs here: https://docs.microsoft.com/en-us/azure/information-protection/rms-client/client-admin-guide-powershell#how-to-label-files-non-interactively-for-azure-information-protection . Follow the steps in that doc to set up:
- AAD Web App
- AAD Native App

When the apps are created and have permission to AIP in Azure, you'll need the Web App Id, Web App Key and Native App Id. Use those values to manually run:
```PowerShell
Set-AIPAuthentication -WebAppId "web app guid" -WebAppKey "web app key" -NativeAppId "native app guid"
```
This command will return a token string. Extract that token. 

You can use the Web App / Native App + token to authenticate to AIP by modifying the ```AIPConnector.ps1``` script to supply the appropriate values to the Set-AIPAuthentication cmdlet.

> NOTE: The script also caters for the scenario of storing those values centrally in the database (in the [GlobalConfig] table). To do so I'd suggest encrypting those strings first. There is a script to help. In the token files folder in the script directory, paste your Web App Key and Token values into the appropriate 'original-' files. Then run the ```TokenUtility.ps1``` script to generate a new encryption key file, encrypt the values and store the encrypted results in the encrypted- files in the same directory. Store those values in the appropriate rows in the [GlobalConfig] table.

**2. Deploy & Populate the Database.**
The database can be directly deployed to a local or remote SQL server. The database contains configuration as well as the list of files to process. Use the PostDeployment SQL script to populate the following tables:
- [Servers]: Add the name of each server that this script will execute on
- [FileServers]: The root name / identifier of each file server that will contain files to be encrypted
- [ServersFileServers]: Map the execution Server where the script will run against a file server. 
- [Labels]: Add the labels and GUID's (found via the Azure Portal) 
- [GlobalConfig]: Add the encrypted string values from step 1) here.

**3. Update config.json**. Update the config.json file in the script directory to set:
- SqlConnectionString - *standard SQL connection string to your SQL database*
- TokenDecryptKeyFile - *location of keyfile.txt used to decrypt the token and web app key (if that approach was used). Use the same keyfile across servers*
- ScriptDirectory - *location of script*

## Running the Script
The script can be run in a number of ways:
- Run the ```BulkEncryptionScript.ps1``` directly in PowerShell, interactively.
  - This will run the script without trying to authenticate to Azure, so you can do this if you have a downloaded AIP Policy already.
  - Add the ```-verbose``` and ```-debug``` switches as appropriate.
- Run the ```MultiThreader.ps1 -threadCount 5``` script. This will spin up a number of threads to run the Bulk script concurrently in a runspace.
- **[Recommended]**: Run the ```LocalBulkOrchestrator.ps1``` script. This could also be run from a scheduled task in Windows. This script will:
  - Check to see if the current server *should* be executing (ie. it's within the Start / End times defined for the server in the database)
  - Check the number of threads the server should be running (from the ```NumberInstances``` column in the [Servers] table)
  - Authenticate to AAD and download a fresh AIP policy
  - Spin up a number of threads to run the Bulk Encryption Script.