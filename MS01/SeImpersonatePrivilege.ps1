$global:version = "1.0.0"

$ascii = @"

.____                        .__            .____          ___.     _________       __                
|    |    ____   ____ _____  |  |           |    |   _____ \_ |__  /   _____/ _____/  |_ __ ________  
|    |   /  _ \_/ ___\\__  \ |  |    ______ |    |   \__  \ | __ \ \_____  \_/ __ \   __\  |  \____ \ 
|    |__(  <_> )  \___ / __ \|  |__ /_____/ |    |___ / __ \| \_\ \/        \  ___/|  | |  |  /  |_> >
|_______ \____/ \___  >____  /____/         |_______ (____  /___  /_______  /\___  >__| |____/|   __/ 
        \/          \/     \/                       \/    \/    \/        \/     \/           |__|    

~ Created with <3 by @nickvourd
~ Version: $global:version
~ Type: SeImpersonatePrivilege

"@

Write-Host $ascii`n

Write-Host "[+] Installing IIS Web Server with required features`n"

# Check if Server or Workstation SKU
$os = Get-WmiObject -Class Win32_OperatingSystem
if ($os.Caption -match "Server") {
        Install-WindowsFeature -Name Web-Server, Web-Asp-Net45, NET-WCF-Services45, NET-HTTP-Activation
} else {
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer", "IIS-ASPNET45", "WCF-Services45", "WCF-HTTP-Activation" -All -NoRestart
}

# Set the destination path
$wwwRoot = "C:\inetpub\wwwroot"

Write-Host "[+] Cleaning $wwwRoot`n"
$excludedFolder = "$wwwRoot\aspnet_client"
Get-ChildItem -Path "$wwwRoot\*" | Where-Object { $_.FullName -ne $excludedFolder } | Remove-Item -Force -Recurse

Write-Host "[+] Set new files to IIS Web Server`n"

# Disable AV
Write-Host "[+] Adding AV exclusion for $wwwRoot`n"
Add-MpPreference -ExclusionPath $wwwRoot


# Define the application pool name and folder path
$appPoolName = "wwwroot"
$folderPath = "C:\inetpub"

# Load IIS module
Import-Module WebAdministration

# Retrieve the application pool identity
$appPool = Get-Item IIS:\AppPools\$appPoolName
$identity = $appPool.processModel.identityType
$userName = $appPool.processModel.userName

# Determine the user based on identity type
if ($identity -eq "SpecificUser") {
    $userAccount = $userName
} elseif ($identity -eq "ApplicationPoolIdentity") {
    $userAccount = "IIS AppPool\$appPoolName"
} else {
    Write-Error "Unsupported identity type for permissions: $identity"
    exit
}

# Grant Full Control permissions to the folder
$acl = Get-Acl $folderPath
$permission = "$userAccount", "FullControl", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl -Path $folderPath -AclObject $acl

Write-Host "Full control permissions set successfully for $userAccount on $folderPath"


# Set the URLs of the files to download
$urlIndexHtml = "https://raw.githubusercontent.com/phulelouch/Active_Directory_Labsetup/main/MS01/index.aspx"  
#$urlCmdAspx = "https://raw.githubusercontent.com/nickvourd/Windows-Local-Privilege-Escalation-Cookbook/master/Lab-Setup-Source-Code/cmdasp.aspx"  

# Download index.html
Invoke-WebRequest -Uri $urlIndexHtml -OutFile "$wwwRoot\index.aspx"

# Download cmdasp.aspx
#Invoke-WebRequest -Uri $urlCmdAspx -OutFile "$wwwRoot\cmdasp.aspx"
