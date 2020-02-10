<#
.SYNOPSIS
Remove-Employee completely offboards a user when they leave the company.

.DESCRIPTION
Remove-Employee will disable the users account and move it to the Disabled Accounts OU. It will also remove the employee from all AD Security Groups and take that information and store it in a CSV file. 
This script will also remove all assigned Office 365 licenses from the user. This requires you to log into

#>

##Connect to Microsoft Online Services and import the module for MSOnline + ActiveDirectory
Connect-MsolService
Install-Module MSOnline
Import-module ActiveDirectory
Write-Host "Offboard a user" -ForegroundColor Red

#Enter the name of the AD account to disable
$AD = read-host "Account name to disable"

#Set the Variables for where to move users account after disabling + where to store their AD membership information
$Getuser = get-aduser -identity $AD -properties *
$UserMember = $Getuser | select -expand memberof
$GetDN = $Getuser.distinguishedname
$DisplayName = $Getuser.DisplayName
$DisabledOU = "YOUR DISABLED OU PATH"
$DisabledPath = "PATH TO STORE CSV FILE"
$Email = 'YOUR COMPANYS EMAIL DOMAIN'

#Reset AD Account Password
set-adaccountpassword -reset -NewPassword (ConvertTo-SecureString -AsPlainText "peaceout12!" -Force) -Identity $AD
Write-Host ("*" + $DisplayName + "'s Active Directory Password has been changed") -ForegroundColor Red

#Clear AD telephone number and ipphone
Set-ADUser -Identity $AD -clear telephonenumber,ipphone

#Get a list of AD group memberships and export to CSV
Get-ADPrincipalGroupMembership -Identity $AD | Select-Object name | Export-Csv -Path $DisabledPath

#Strip group memberships from disabled user
$UserMember | Remove-ADGroupMember -Members $AD -Confirm:$true

#Move user to disabled OU
Move-adobject -Identity $GetDN -TargetPath $DisabledOU
Write-Host ("*" + $DisplayName + "'s account moved to disabled OU") -ForegroundColor Red


##Unassign all Office 365 licenses from the user
Get-MsolUser -UserPrincipalName ($AD + $Email)
$license = Get-MsolUser -UserPrincipalName ($AD + $Email) | select -ExpandProperty licenses 
Set-MsolUserLicense -UserPrincipalName ($AD + $Email) -RemoveLicenses $license.AccountSkuId 
Write-Host "All licenses have been unassigned from $DisplayName" -BackgroundColor Red | Out-Null