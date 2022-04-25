# Kloudit

Welcome to Kloudit, an open source tool to **audit the security compliance** of your Azure resources configurations !

NB : This project is still in developpement. For now, only control point from CIS benchmark for section Microsoft Defender for cloud and Storage Account are available.
Thanks :)

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

**Thus, only the script executor has access to the results of kloudit.**

### 3. Security control points
Currently only the CIS brenchmark fundation for Azure (Version 1.4.0) control points are implemented.



## Requirements
This are the requirements to run Kloudit.

### 1. Azure Account with READ Permission
You must have an Azure account with READ permissions on the scope you want to audit. This will be the identity used by Kloudit to perform the audit.
To add Read permission on a given scope you can do as this :

    - Go on portal.azure.com
    - Go on the scope you want to audit (Management Groups or Subscription)
    - select IAM -> Add role assignement -> Reader -> Identity used.

### 2. Allow Script Execution
Kloudit is a PowerShell script, so to use it you must allow the execution of scripts on you computer.

```Powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
```

After using Kloudit you can re-set Execution Policy to default
```Powershell
Set-ExecutionPolicy -ExecutionPolicy Default -Scope CurrentUser
```

### 3. Have PowerShell 7 or upper installed.
There are several ways to install Powershell
To install Powershell 7 from command line follow this.

**On Windows :**

```
msiexec.exe /package PowerShell-7.2.2-win-x64.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1
```

*Microsoft docs : https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2*

**On MacOs :**

```
brew install --cask powershell
```

*Microsoft docs : https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.2*

**On Linux (Ubuntu) :**

```
sudo dpkg -i powershell-lts_7.2.2-1.deb_amd64.deb
sudo apt-get install -f
```

*Microsoft docs : https://docs.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.2*

To check that Powershell 7 is properly installed, open a shell and run `pwsh`

### 4. Have Azure Powershell Installed
Install Azure PowerShell to use Azure cmdlet.

First open a shell and run `pwsh` to start powershell 7.

Then install Azure PowerShell Module :
```Powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

*Microsoft docs : https://docs.microsoft.com/fr-fr/powershell/azure/install-az-ps?view=azps-7.4.0*

## How to Use Kloudit
Once the requirements are done, this is how to used Kloudit.

1. Download the project from github.
    ```
    git clone https://github.com/Clackoss/Kloudit.git
    ```
2. Open a Shell and Run `pwsh`
3. From shell go on the project path `cd Path/Kloudit/` then run `./start-Audit.ps1`

Now the script is running. Once the scripts is over, it should open a web page displaying the results.

If no pages open you can open it manually by opening the html file in *ProjectPath/Kloudit/web/AuditResult.html*

## Next steps
This are the next steps for Kloudit :
    - Add the CIS security control points
    - Improve the documentation
    - Add Control point from other referentials
