<#
.SYNOPSIS
    Read a credential object from the credential store. If no valid credential is available it will
    prompt for the credential and store it in the credential store.
.DESCRIPTION
    This cmdlet can be used in scripts to avoid prompting for a credential everytime the script runs. This method
    is much safer then storing the credential in the script itself or using your own method. The Windows Data
    Protection API (DPAPI) is used to encrypt the password. The password can only be decrypted by the same
    user who encrypted it. Resetting your password will void the decryption key and make the credential unusable.
    As the encryption key is tied to the user, the credential store must be personal, which means a seperate
    store for each user. The default store is the directory '$Env:USERPROFILE\Credentials'.
.NOTES
    Author: Graeme Meyer

    Version History:
    1.1 - 2020-09-02 - @GraemeMeyer forks - Graeme Meyer
        - Minor changes including relocating the credential store to the UserProfile to avoid problems with 
        corporate OneDrives.
        - Creation of the .psd1 manifest in preparation for upload to the PowerShell Gallery.
        - Code formatting to align with my preferences.

    1.0 - 06-07-2016 - Initial release - Theo Hardendood, Metis IT B.V.
        - NOTE: This module was forked, modified and distributed with the kind permission of it's original author,
        Theo Hardendood.
.PARAMETER Name
    The name of the credential. Used for naming the files in the credential store.
    The name is not case sensitive. Two files will be used for each credential: '<Name>.username'
    and '<Name>.password'. Whitespace or special characters are not allowed.
.PARAMETER StorePath
    The path to the credential store. Default is '$Env:USERPROFILE\Credentials'. This must be a writeable
    directory that will be created if it does not exist. 
.PARAMETER Credential
    Save the supplied credential in the credential store, overwriting an existing credential.
.PARAMETER UserName
    The user name used in the credential when prompting. This will only be used when asking for a new credential,
    and can be changed by the user.
.PARAMETER Message
    The message that appears in the credential prompt.
.PARAMETER DoNotPrompt
    Do not prompt for the credential if it cannot be found or read and throw an exception.
.PARAMETER Reset
    Reset credential by prompting for a new one.
.PARAMETER Delete
    Delete credential and do not prompt for a new one.
.EXAMPLE
    $cred = Get-StoredCredential -Name vCenter

    Read credential for vCenter and return as PSCredential object. The cmdlet will prompt for username and
    password if the credential cannot be read.
.EXAMPLE
    $cred = Get-StoredCredential -Name JustAName -UserName 'Administrator'

    If it must ask for a new credential, the user name field will be filled in as a suggestion.
.EXAMPLE
    $cred = Get-StoredCredential -Name JustAName -StorePath 'E:\Credentials\myname'

    Uses the file 'E:\Credentials\myname\JustAName.username' to store the user name and the file
    'E:\Credentials\myname\JustAName.password' to store the password.
.EXAMPLE
    Get-StoredCredential -Name JustAName -Credential $cred

    Store the credential $cred in the credential store. Use this method to store a credential if it is used
    in a script running under a service account and you cannot log in under that account. To make this work, create
    a script with the below contents (don't forget to use the correct UserName and Password) and run it under the
    service account. Make sure the path to the credential store is valid.

    $securePassword = ConvertTo-SecureString -String 'ThePassword' -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'TheUserName', $securePassword
    Get-StoredCredential -Name JustAName -StorePath 'E:\Credentials\ServiceAccount' -Credential $cred

    Do not forget to overwrite or delete this script afterward, or your password is still exposed.
.EXAMPLE
    Get-StoredCredential -Name JustAName -Delete

    Delete the credential JustAName. If the -Delete parameter is used then no PSCredential object will be returned.
#>
function Get-StoredCredential {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The name of the credential.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The path to the credential store.")]
        [string]$StorePath,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Save the supplied credential in the credential store, overwriting the existing credential.")]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "The user name used in the credential when prompting.")]
        [string]$UserName,
        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "The message that appears in the credential prompt.")]
        [string]$Message,
        [Parameter(Mandatory = $false, Position = 5, HelpMessage = "Do not prompt for the credential if it cannot be read and throw an exception.")]
        [Switch]$DoNotPrompt,
        [Parameter(Mandatory = $false, Position = 6, HelpMessage = "Reset credential by prompting for a new one.")]
        [Switch]$Reset,
        [Parameter(Mandatory = $false, Position = 7, HelpMessage = "Delete credential and do not prompt for a new one.")]
        [Switch]$Delete
    )

    begin {
    }

    process {
        $ErrorActionPreference = "Stop"
        try {
            if ($Name -notmatch "^\w\w*$") {
                throw "Name cannot contain whitespace or special characters."
            }
            if ([String]::IsNullOrEmpty($StorePath)) {
                $p_StorePath = $Env:USERPROFILE + "\Credentials"
            }
            else {
                $p_StorePath = $StorePath
            }
            if (-Not (Test-Path -Path $p_StorePath -PathType Container)) {
                New-Item -Path $p_StorePath -ItemType Directory | Out-Null
            }
            $p_UserNamePath = [String]::Format("{0}\{1}.username", $p_StorePath, $Name)
            $p_PasswordPath = [String]::Format("{0}\{1}.password", $p_StorePath, $Name)
            if ($Delete.IsPresent) {
                if (Test-Path -Path $p_UserNamePath -PathType Leaf) {
                    Remove-Item -Path $p_UserNamePath -Force
                }
                if (Test-Path -Path $p_PasswordPath -PathType Leaf) {
                    Remove-Item -Path $p_PasswordPath -Force
                }
                return
            }
            if ($Credential -ne $null) {
                $Credential.UserName | Out-File $p_UserNamePath -Force
                $Credential.Password | ConvertFrom-SecureString | Out-File $p_PasswordPath -Force
                return $Credential
            }
            try {
                if ($Reset.IsPresent) {
                    throw "Request new credential"
                }
                $p_UserName = Get-Content -Path $p_UserNamePath
                $p_Password = Get-Content -Path $p_PasswordPath | ConvertTo-SecureString
                $p_Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $p_UserName, $p_Password
                return $p_Credential
            }
            catch {
                if ($DoNotPrompt.IsPresent) {
                    throw "Cannot read credential, and prompting for a new credential is not allowed."
                }
                if ([String]::IsNullOrEmpty($Message)) {
                    $p_Message = "Please enter credential for $Name"
                }
                else {
                    $p_Message = $Message
                }
                $p_Args = @{}
                if ([String]::IsNullOrEmpty($UserName) -eq $false) {
                    $p_Args = @{ "UserName" = "$UserName" }
                }
                else {
                    if ([String]::IsNullOrEmpty($p_UserName) -eq $false) {
                        $p_Args = @{ "UserName" = "$p_UserName" }
                    }
                }
                $p_Credential = Get-Credential -Message $p_Message @p_Args
                if ($null -ne $p_Credential) {
                    $p_Credential.UserName | Out-File $p_UserNamePath -Force
                    $p_Credential.Password | ConvertFrom-SecureString | Out-File $p_PasswordPath -Force
                }
                return $p_Credential
            }
        }
        catch {
            Write-Host -BackgroundColor Black -ForegroundColor Red "Get-StoredCredential: $($_.Exception.Message)"
        }
    }
}