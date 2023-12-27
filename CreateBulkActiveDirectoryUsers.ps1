# Import active directory module for running AD cmdlets
Import-Module ActiveDirectory

# Define UPN and OU
$UPN = "itpro.work.gd"
$OuPath = "CN=Dani,CN=Users,DC=ITPH,DC=lab"
$Password = $((Write-Host "`n>> Enter the password to create users : "-ForegroundColor yellow -NoNewLine );Read-Host)

# Store the data from NewUsersFinal.csv in the $ADUsers variable
$ADUsers = Import-Csv .\SampleUsersToBeCreated.csv ";"

# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {

    #Read user data from each field in each row and assign the data to a variable as below
    $UserInfo = @{
        Name = "$($User.firstname +"."+ $User.lastname)"
        SamAccountName = "$($User.firstname +"."+ $User.lastname)"
        UserPrincipalName = $(if($null -eq $User.mail){"$($User.firstname +"."+ $User.lastname)@$UPN"} else {$User.email})
        GivenName = $User.firstname
        Surname = $User.lastname
        Initials = $User.initials
        Path = $OuPath #This field refers to the OU the user account is to be created in
        EmailAddress = $(if($null -eq $User.mail){"$($User.firstname +"."+ $User.lastname)@$UPN"} else {$User.email})
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
        AccountPassword = (ConvertTo-secureString $Password -AsPlainText -Force)
    }

    $UserInfo
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


