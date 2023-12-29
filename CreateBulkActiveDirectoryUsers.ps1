# Import active directory module for running AD cmdlets
# Import-Module ActiveDirectory
# $Session = New-PSSession -ComputerName ITPROHUBDC
# Invoke-Command -Session $Session {Import-Module ActiveDirectory}

# for printing input header
function HeaderPrint([string]$text) {
    Write-host "`n################### $text ################# "
}

#Validate OU
function OuValidation {
    [string]$OUPathDN = $((Write-Host "`n>> Specify the Organization Unit (OU) distinguishedName. Eg. CN=Dani,CN=Users,DC=ITPH,DC=lab : "-ForegroundColor yellow -NoNewLine );Read-Host)

    If([adsi]::Exists("LDAP://$OUPathDN") -eq $false){
        $OUPathDN = $((Write-Host "`n>> Ivalid! Organization Unit (OU) exist. Try again : "-ForegroundColor red -NoNewLine );Read-Host)
    }else{
        return $OUPathDN
    }
}

# Define UPN and OU
HeaderPrint -text "Define the domain and Organization Unit (OU)"
$Domain = $((Write-Host "`n>> Specify the domain. Eg. itpro.work.gd : "-ForegroundColor yellow -NoNewLine );Read-Host)

[string]$OuPath = 

# Store the data from NewUsersFinal.csv in the $ADUsers variable
$ADUsers = Import-Csv .\SampleUsersToBeCreated.csv ";"

$addressFormatInfo =@"

    Example user FirstName = Alex and LastName = Fox and domain = JesusLovesYou.com

    1 - alex.fox@JesusLovesYou.com
    2 - a.fox@JesusLovesYou.com
    3 - afox@JesusLovesYou.com
    4 - fox.alex@JesusLovesYou.com
    5 - f.alex@JesusLovesYou.com
    6 - falex@JesusLovesYou.com

"@


# Password for user creation

$AccPassword = $((Write-Host "`n>> Enter the password to create users : "-ForegroundColor yellow -NoNewLine );Read-Host)

# Define the eamil address forrmat to use if address formate is worng or invalid
Write-Host "`n############## Choose user address format ############`n $addressFormatInfo"
$UPNFormat = $((Write-Host "`n>> Chose UserPrincipalName format (Incase of incorrect addresses) : "-ForegroundColor yellow -NoNewLine );Read-Host)

#Same address for UPN and Eamil
$upnEqSMTP = $((Write-Host "`n>> Do you want the same address for UserPrincipalName (login) or Primary Email (SMTP) Address [Yes(Y)/No(N)? "-ForegroundColor yellow -NoNewLine );Read-Host)
if ($upnEqSMTP -in "Yes,Y".ToLower().Split(",")){
    $PSMTPFormate = $UPNFormat
}else {
    Write-Host "`n############## Choose user address format Primary Email(SMTP) Address ############`n $addressFormatInfo"
    $PSMTPFormate = $((Write-Host "`n>> Chose Primary Email(SMTP) Address format : "-ForegroundColor yellow -NoNewLine );Read-Host)
}


#address formate selection function
function CrateAddress ($addressFormat, $firstName, $lastName) {
    switch ($addressFormat) {
        1 { $addressFormat = "$($firstName+"."+$lastName)@$Domain"; break }
        2 { $addressFormat = "$($firstName[0]+"."+$lastName)@$Domain"; break }
        3 { $addressFormat = "$($firstName[0]+$lastName)@$Domain"; break }
        4 { $addressFormat = "$($lastName+"."+$firstName)@$Domain"; break }
        5 { $addressFormat = "$($lastName[0]+"."+$firstName)@$Domain"; break }
        6 { $addressFormat = "$($lastName[0]+$firstName)@$Domain"; break }
    }
    
    return $addressFormat
}


# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {

    #Read user data from each field in each row and assign the data to a variable as below
    $UserInfo = @{
        Name = "$($User.firstname +"."+ $User.lastname)"
        SamAccountName = "$($User.firstname +"."+ $User.lastname)"
        UserPrincipalName = $(if($null -eq $User.email){"$($User.firstname +"."+ $User.lastname)@$Domain"} else {$User.email})
        GivenName = $User.firstname
        Surname = $User.lastname
        Initials = $User.initials
        Path = $OuPath #This field refers to the OU the user account is to be created in
        EmailAddress = $(if($null -eq $User.email){"$($User.firstname +"."+ $User.lastname)@$UPN"} else {$User.email})
        City = $User.city
        PostalCode = $User.zipcode
        State = $User.state
        Country = $User.country
        Telephone = $User.telephone
        Title = $User.jobtitle
        Company = $User.company
        Department = $User.department
        DisplayName = "$($User.lastname +" "+ $User.firstname)"
        Enabled = $True
        ChangePasswordAtLogon = $True
        AccountPassword = (ConvertTo-secureString $AccPassword -AsPlainText -Force)
    }
}

    # Check to see if the user already exists in AD
    if (Get-ADUser -F { SamAccountName -eq $username }) {
        
        # If user does exist, give a warning
        Write-Warning "A user account with username $username already exists in Active Directory."
    }
    else {

        # User does not exist then proceed to create the new user account
        # Account will be created in the OU provided by the $OU variable read from the CSV file
        New-ADUser @UserInfo -

        # If user is created, show message.
        Write-Host "The user account $username is created." -ForegroundColor Cyan
    }
}

Read-Host -Prompt "Press Enter to exit"


