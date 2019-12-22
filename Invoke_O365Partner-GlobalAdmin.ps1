# Config Settings
$AdministratorFirstName = "FIRST"
$AdministratorLastName = "LAST"
$AdministratorUserName = "USER"
# Set-MsolUserPassword : You must choose a strong password that contains 8 to 16 characters, 
# a combination of letters, and at least one number or symbol.
$AdministratorPassword = "SIRONG PASSWORD"
$MFAPhone = "PHONENUMBER FOR TEXT"

# ------ DO NOT CHANGE ANYTHING BELOW THIS LINE ------

# Role Settings
$RoleCompanyAdministrator = "Company Administrator"
$RoleCompanyAdministratorId = "62e90394-69f5-4237-9190-012177145e10"

# MFA Requirement Object
$mf= New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mf.RelyingParty = "*"
$mfa = @($mf)

# MFA Types
$SMS = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$SMS.IsDefault = $true
$SMS.MethodType = "OneWaySMS"
$Phone = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$Phone.IsDefault = $false
$Phone.MethodType = "TwoWayVoiceMobile"
$PrePopulate = @($SMS, $Phone)

Get-MsolPartnerContract -All | Select-Object TenantId | ForEach-Object {
    $TenantId = $_.TenantId
    # $TenantId = "d5f8d8a5-7ae9-4b37-a156-e0063446b977"
    Get-MsolDomain -TenantId $TenantId | Where-Object {$_.Name -clike "*.onmicrosoft.com"} | ForEach-Object {

        $domain = $_.Name
        $upn = "$($AdministratorUserName)@$($domain)" 

        # create user if not exists
        if ( -not (Get-MsolUser -TenantId $TenantId -UserPrincipalName $upn -ErrorAction SilentlyContinue)){
            Write-Output "Create new user."
            New-MsolUser -TenantId $TenantId -UserPrincipalName $upn -DisplayName "$AdministratorFirstName $AdministratorLastName" -FirstName $AdministratorFirstName -LastName $AdministratorLastName
        }
        #set password
        Write-Output "Setting password for $upn"
        Set-MsolUserPassword -TenantId $TenantId -UserPrincipalName $upn -NewPassword $AdministratorPassword -ForceChangePassword $False

        #set role if not set
        # this seems more complicated than is should be; gotta be a simpler way to check?
        if  ( -not (Get-MsolRoleMember -TenantId $TenantId -RoleObjectId $RoleCompanyAdministratorId | Where-Object {$_.EmailAddress -clike $upn})){
            Write-Output "Adding $upn to Global Administrators"
            Add-MsolRoleMember -TenantId $TenantId -RoleMemberEmailAddress $upn -RoleName $RoleCompanyAdministrator
        }

        # Require MFA
        Set-MsolUser -TenantId $TenantId -UserPrincipalName $upn -StrongAuthenticationRequirements $mfa -StrongAuthenticationMethods $PrePopulate -MobilePhone $MFAPhone
        
        Write-Output ""
    }
}
