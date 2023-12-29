#CSV file should containt the following column EmailAddress Address Search
$ActiveUsers = Import-csv C:\Users\itproadmin\Downloads\UsersList.csv

#definethe new domain
$newdomain = "@techjollof.net"


$ActiveUsers | % {

    $UserAddress = $_.EmailAddress

    $ActiveUsers = get-aduser -filter  "(Mail -eq '$UserAddress') -or (UserPrincipalName -eq '$UserAddress')" -Properties *

    Write-Host "`n`nProcessing $($ActiveUsers.EmailAddress) information"

    #get, remove and add the curremt SMTP address as alias
    $crrtSMT = $ActiveUsers.proxyAddresses | ? { $_ -clike 'SMTP:*'}

    if($crrtSMT -eq $null){
        Write-host "User $($ActiveUsers.EmailAddress) does not have SMTP address type, not action is taken but stop the script and uncommnent the below line by removing # "

        #################   uncommend this if you want to force add the address ##################
        $newProxy = "SMTP:"+$ActiveUsers.SamAccountName+$newdomain
        Set-ADUser $ActiveUsers.SamAccountName -add @{ProxyAddresses= "$newProxy"} -EmailAddress $newProxy.split(':')[1]


    }else{
        Set-ADUser $ActiveUsers.SamAccountName -remove @{ProxyAddresses= "$crrtSMT"}

        #adding old as alias
        Set-ADUser $ActiveUsers.SamAccountName -add @{ProxyAddresses= "$crrtSMT".ToLower()}

        #adding new address
        Write-Host "Adding the new SMTP address and replace the MAIL address/EmailAddress"
        $newProxy = "$($crrtSMT.split('@')[0])"+$newdomain
        Write-Host "adding new address and updating mail property"
        Set-ADUser $ActiveUsers.SamAccountName -add @{ProxyAddresses= "$newProxy"} -EmailAddress $newProxy.split(':')[1]

        Write-Host "..............................Update completed`n"
    }

}