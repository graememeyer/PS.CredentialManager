# README #

A credential manager module for PowerShell. Securely stores and retrieves credentials using the Windows Data Protection API (DPAPI).

This module contains the Get-StoredCredentials cmdlet - use this cmdlet to securely store credentials used by your script. The cmdlet has inline documentation. 

# Installation 
This module is now hosted in the [PowerShell Gallery](https://www.powershellgallery.com/packages/PS.CredentialManager/), so to install it you just need to use:
``` PowerShell
Install-Module -Name PS.CredentialManager
```

You can also download it directly from this GitHub repository, and then import the module manually with: 
To use use it, start PowerShell and type:
``` PowerShell
Import-Module PS.CredentialManager.psm1
```

# Usage
## Example 1
``` PowerShell
$cred = Get-StoredCredential -Name vCenter
```
Read credential for vCenter and return as PSCredential object. The cmdlet will prompt for username and password if the credential cannot be read.


## Example 2
``` PowerShell
$cred = Get-StoredCredential -Name JustAName -UserName 'Administrator'
```
If it must ask for a new credential, the user name field will be filled in as a suggestion.
    
## Help and Additional Examples
To get help, including additonal examples, type:
```PowerShell
Get-Help Get-StoredCredential -Detailed
```

# Version History:
1.2 - 2022-02-27 - Fixed name regex. Added "-" char at least.

1.1 - 2020-09-02 - [@GraemeMeyer](https://github.com/GraemeMeyer) forks the project. - Graeme Meyer  
    - Minor changes including relocating the credential store to the UserProfile to avoid problems with  
    corporate OneDrives.  
    - Creation of the .psd1 manifest in preparation for upload to the PowerShell Gallery.  
    - Code formatting to align with my preferences.  
    - Refined the in-line documentation and README

1.0 - 06-07-2016 - Initial release - Theo Hardendood, Metis IT B.V.  

# Credit and Authorship
This module was forked, modified and distributed with the kind permission of it's original author, Theo Hardendood.