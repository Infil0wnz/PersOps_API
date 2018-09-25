# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
# INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.


# Personalization Operations - Delete All User Profile Data - Individual User
# Written by Thomas Price - Technical Relationship Manager

cls
$server = Read-Host "Please Enter Personalization Server Name e.g. [Localhost:7771]: "

# Set Personalization Server API
$ServerURL = "http://$server/PWCAPI/api"

#  Prompt for Username
$user = read-host "Enter User to query eg. DOMAIN\Username"
$keepArchives = "true"

#  Invoke the User/Search to obtain the users ID
#  http://localhost:7771/PWCAPI/Help/Api/GET-api-user_search
$userid = Invoke-WebRequest -Uri "$serverURL/user?search=$user" -UseDefaultCredentials | ConvertFrom-Json | Select users
$userid = $userid.users.id

#  Invoke the Application Group Search to Return Application Group GUIDs
$userAppGroups = Invoke-WebRequest -Uri "$serverURL/user/$userid" -UseDefaultCredentials | ConvertFrom-Json
$appGroupGUIDs = $userAppGroups.applicationGroups.id
$WSGroupNames = $userAppGroups.windowsSettingsGroups.name


# Create JSON Template for Delete User Task Operation 
# Create Array for JSON Template
$jsonDeleteUser = @()
# Set Array Index
$i = 0
$j = 0

# Define affected User
$jsonDeleteUser += (@"

{
  "id": "$userid",
  "operations": [
"@)

# Define Application Group ID and Delete Settings
While ($i -le ($appGroupGUIDs.Count -1))
{
$jsonDeleteUser += (@"
     {   
        "applicationGroupProfileId": "$($appGroupGUIDs[$i])",
        "operation": {
            "liveSettingsDelete": {
                "deleteRegistry": true,
                "deleteFiles": true,
                "preserveArchives": $keepArchives
                }
            }
        },
"@)
$i++
}

# Define Application Group ID and Delete Settings
While ($j -le ($WSGroupNames.Count -1))
{
$jsonDeleteUser += (@"
     {   
        "windowsSettingsGroupDisplayName": "$($WSGroupNames[$j])",
        "operation": {
            "liveSettingsDelete": {
                "deleteRegistry": true,
                "deleteFiles": true,
                "preserveArchives": $keepArchives
                }
            }
        },
"@)
$j++
}

# Define JSON Template End
$jsonDeleteUser += (@"
  ]
}
"@)

#  Delete Application Group Data Using POST api/ImmediateTask - http://localhost:7771/PWCAPI/Help/Api/POST-api-ImmediateTask
$response = Invoke-WebRequest -Uri "$serverURL/ImmediateTask" -Method Post -Body $jsonDeleteUser -ContentType "application/json" -UseDefaultCredentials 

if ($response.StatusCode -eq 200)
{
    write-host -BackgroundColor DarkGreen "All User Profile Data Successfully Deleted"

}
else
{
    write-host -BackgroundColor DarkYellow "Request did not return a success ("$response.StatusCode"), please try again if unsuccessful"
}