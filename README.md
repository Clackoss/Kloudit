# Kloudit

Welcome to Kloudit, an open source tool to audit the security compliance of your Azure resources configurations !

## What is Kloudit ?

Kloudit is an open-source project to control the configurations of your resources hosted in Azure.

Based on Security referentials such as CIS & NIST, resources configurations are scanned and compared with good security practices.

Kloudit will then display the results of this scanning, giving you complete visibility into the configuration status of your Azure resources.

## Technical Informations

### 1. Identity & Authentication
Kloudit uses one of your identities to get data from Azure. Authentication is fully managed by Azure (Kloudit only uses the command: `Connect-AzAccount` provided by Microsoft).

Scans of your infrastructure will be performed using the name and permissions of the identity you use to log in.

### 2. How are Data managed ?

When you run Kloudit, the script will get your configuration data with API calls.
Then a display is done one a web format.
The data get by Kloudit are never published online, everything is stored locally on you machine ;
 - As json format in *ProjectPath/Reports/files.json*
 - As html format in *ProjectPath/Web/files.html* 


## Requirements
This is the requirements to run Kloudit.

### 1. Azure Account with READ Permission
You must have an Azure account with READ permissions on the scope you want to audit. This will be the identity used by Kloudit to perform the audit.
To add Read permission on a given scope you can do as this :
    - Go on portal.azure.com
    - Go on the scope you want to audit (Management Groups or Subscription)
    - select IAM -> Add role assignement -> Reader -> Identity used.
2. Have PowerShell 7 or upper installed.
There are several ways to install Powershell
To install Powershell 7 from command line :
On Windows : 








Powerhsell 7 mini
Azure powerhsell
An Azure account with Golbal Reader Right

All the security Controls points are based on the CIS brenchmark fundation for Azure (Version 1.4.0)

3.4 not doable
