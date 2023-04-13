<#PSScriptInfo
.VERSION 1.0.0
.GUID 1000d8c2-73b3-48a8-b1ec-f894fec7df58
.AUTHOR AndrewTaylor
.DESCRIPTION Alerts when a certificate is due to expire
.COMPANYNAME
.COPYRIGHT GPL
.TAGS intune endpoint MEM environment
.LICENSEURI https://github.com/andrew-s-taylor/public/blob/main/LICENSE
.PROJECTURI https://github.com/andrew-s-taylor/public
.ICONURI
.EXTERNALMODULEDEPENDENCIES microsoft.graph.intune, microsoft.graph.users.actions
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>
<# 

.DESCRIPTION 
Alerts on expiry of Apple Certificates with AAD App Registration, Azure Blob and Azure Automation Account

#> 


##############################################################################################################################################
##### UPDATE THESE VALUES #################################################################################################################
##############################################################################################################################################
## Your Azure Tenant Name
$tenant = "<YOUR TENANT NAME>"

##Your Azure Tenant ID
$tenantid = "<YOUR TENANT ID>"

##Your App Registration Details
$clientId = "<YOUR CLIENT ID>"
$clientSecret = "<YOUR CLIENT SECRET>"

$EmailAddress = "<YOUR EMAIL ADDRESS>"

##From Address
$MailSender = "<YOUR FROM ADDRESS>"


##############################################################################################################################################

Function Get-ScriptVersion(){
    
  <#
  .SYNOPSIS
  This function is used to check if the running script is the latest version
  .DESCRIPTION
  This function checks GitHub and compares the 'live' version with the one running
  .EXAMPLE
  Get-ScriptVersion
  Returns a warning and URL if outdated
  .NOTES
  NAME: Get-ScriptVersion
  #>
  
  [cmdletbinding()]
  
  param
  (
      $liveuri
  )
$contentheaderraw = (Invoke-WebRequest -Uri $liveuri -Method Get)
$contentheader = $contentheaderraw.Content.Split([Environment]::NewLine)
$liveversion = (($contentheader | Select-String 'Version:') -replace '[^0-9.]','') | Select-Object -First 1
$currentversion = ((Get-Content -Path $PSCommandPath | Select-String -Pattern "Version: *") -replace '[^0-9.]','') | Select-Object -First 1
if ($liveversion -ne $currentversion) {
write-host "Script has been updated, please download the latest version from $liveuri" -ForegroundColor Red
}
}
Get-ScriptVersion -liveuri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/Powershell%20Scripts/Intune/detect-cert-expiry.ps1"




#Connect to GRAPH API
$body = @{
    grant_type    = "client_credentials";
    client_id     = $clientId;
    client_secret = $clientSecret;
    scope         = "https://graph.microsoft.com/.default";
}
 
$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $body
$accessToken = $response.access_token
 
$accessToken

#Get Creds and connect
#Connect to Graph
write-host "Connecting to Graph"
write-host $body
Select-MgProfile -Name Beta
Connect-MgGraph  -AccessToken $accessToken
write-host "Graph Connection Established"

#MDM Push
$30days = ((get-date).AddDays(30)).ToString("yyyy-MM-dd")
$pushuri = "https://graph.microsoft.com/beta/deviceManagement/applePushNotificationCertificate"
$pushcert = (Invoke-RestMethod -Uri $pushuri -Headers $headers -Method Get)
$pushexpiryplaintext = $pushcert.expirationDateTime
$pushexpiry = ($pushcert.expirationDateTime).ToString("yyyy-MM-dd")
if ($pushexpiry -lt $30days) {
write-host "Cert Expiring" -ForegroundColor Red

#Send Mail    
$URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"
$BodyJsonsend = @"
                    {
                        "message": {
                          "subject": "Apple Push Certificate Expiry",
                          "body": {
                            "contentType": "HTML",
                            "content": "Your Apple Push Certificate is due to expire on <br>
                            $pushexpiryplaintext <br>
                            Please Renew before this date
                            "
                          },
                          "toRecipients": [
                            {
                              "emailAddress": {
                                "address": "$EmailAddress"
                              }
                            }
                          ]
                        },
                        "saveToSentItems": "false"
                      }
"@

Invoke-MgGraphRequest -Method POST -Uri $URLsend -Body $BodyJsonsend -ContentType "application/json"

}
else {
write-host "All fine" -ForegroundColor Green
}


#VPP
$30days = ((get-date).AddDays(30)).ToString("yyyy-MM-dd")
$vppuri = "https://graph.microsoft.com/beta/deviceAppManagement/vppTokens"
$vppcert = (Invoke-RestMethod -Uri $vppuri -Headers $headers -Method Get)
$vppexpiryvalue = $vppcert.value
$vppexpiryplaintext = $vppexpiryvalue.expirationDateTime
$vppexpiry = ($vppexpiryvalue.expirationDateTime).ToString("yyyy-MM-dd")
if ($vppexpiry -lt $30days) {
write-host "Cert Expiring" -ForegroundColor Red
#Send Mail    
$URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"
$BodyJsonsend = @"
                    {
                        "message": {
                          "subject": "Apple VPP Certificate Expiry",
                          "body": {
                            "contentType": "HTML",
                            "content": "Your Apple VPP Certificate is due to expire on <br>
                            $vppexpiryplaintext <br>
                            Please Renew before this date
                            "
                          },
                          "toRecipients": [
                            {
                              "emailAddress": {
                                "address": "$EmailAddress"
                              }
                            }
                          ]
                        },
                        "saveToSentItems": "false"
                      }
"@

Invoke-RestMethod -Method POST -Uri $URLsend -Headers $headers -Body $BodyJsonsend
}
else {
write-host "All fine" -ForegroundColor Green
}






#DEP
$30days = ((get-date).AddDays(30)).ToString("yyyy-MM-dd")
$depuri = "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings"
$depcert = (Invoke-RestMethod -Uri $depuri -Headers $headers -Method Get)
$depexpiryvalue = $depcert.value
$depexpiryplaintext = $depexpiryvalue.tokenexpirationDateTime

$depexpiry = ($depexpiryvalue.tokenExpirationDateTime).ToString("yyyy-MM-dd")
if ($depexpiry -lt $30days) {
write-host "Cert Expiring" -ForegroundColor Red

#Send Mail    
$URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"
$BodyJsonsend = @"
                    {
                        "message": {
                          "subject": "Apple DEP Certificate Expiry",
                          "body": {
                            "contentType": "HTML",
                            "content": "Your Apple DEP Certificate is due to expire on <br>
                            $depexpiryplaintext <br>
                            Please Renew before this date
                            "
                          },
                          "toRecipients": [
                            {
                              "emailAddress": {
                                "address": "$EmailAddress"
                              }
                            }
                          ]
                        },
                        "saveToSentItems": "false"
                      }
"@

Invoke-MgGraphRequest -Method POST -Uri $URLsend -Body $BodyJsonsend
}
else {
write-host "All fine" -ForegroundColor Green
}
