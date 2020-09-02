# README #

A credential manager module for PowerShell. Securely stores and retrieves credentials using the Windows Data Protection API (DPAPI).

This module contains the Get-StoredCredentials cmdlet - use this cmdlet to securely store credentials used by your script. The cmdlet has inline documentation. To use use it, start PowerShell and type:
``` PowerShell
Import-Module CredentialManager.psm1
```

To get help, type:
```PowerShell
Get-Help Get-StoredCredential -Detailed
```

This module was forked, modified and distributed with the kind permission of it's original author, Theo Hardendood.

# Version History
1.1 - 2020-09-02 - [@GraemeMeyer](https://github.com/GraemeMeyer) forks the project. - Graeme Meyer  
    - Minor changes including relocating the credential store to the UserProfile to avoid problems with  
    corporate OneDrives.  
    - Creation of the .psd1 manifest in preparation for upload to the PowerShell Gallery.  
    - Code formatting to align with my preferences.  
    - Refined the in-line documentation and README

1.0 - 06-07-2016 - Initial release - Theo Hardendood, Metis IT B.V.  