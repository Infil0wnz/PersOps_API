# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
# INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.


# Personalization Operations - Delete All User Profile Data - From External Text File
# Written by Thomas Price - Technical Relationship Manager

CLS
# Function for Reading User Names From External Text File
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "TXT (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$server = Read-Host "Please Enter Personalization Server Name e.g. [Localhost:7771]: "

# Set Personalization Server API
$serverURL = "http://$server/PWCAPI/api"

# Call Function to Read User Names
$inputfile = Get-FileName "C:\temp"
$batchUsers = get-content $inputfile

# Create Array for User IDs
$userids = @()

# Lookup User GUID for Each Users Account Read from Text File
foreach ($batchUser in $batchUsers)
{
    $userid = Invoke-WebRequest -Uri "$serverURL/user?search=$batchUser" -UseDefaultCredentials | ConvertFrom-Json | Select users
    $userids += $userid.users.id
}

#  List all the Application Groups available to the logged in user
$AppGroups = Invoke-WebRequest -Uri "$serverURL/applicationgroup" -UseDefaultCredentials | ConvertFrom-Json
# Return all Application Group GUIDs
$appGroupGUIDs = $AppGroups.applicationGroups.id
# Return all Windows Settings Group Names
$WSGroupNames = $AppGroups.wsgNames

# Apply Advanced Settings to Execution Job
$keepArchives = "true"
$taskDelay = Read-Host "How may hours to delay the task?"
$taskDescription = Read-Host "Enter a description for the task"

# Create JSON Template for Delete User Task Operation 
# Create Array for JSON Template
$jsonDeleteUser = @()
# Set Array Index
$h = 0
$i = 0
$j = 0

# Define JSON File Header
$jsonDeleteUser += (@"

{
  "scope": {
        "users": [
"@)

# Define Scope of Users for JSON File
while ($h -le ($userids.Count -1))
{
$jsonDeleteUser += (@"
            "$($userids[$h])",
"@)
$h++
}

# Define affected User
$jsonDeleteUser += (@"
        ],
    },
  "operations": [
"@)

# Define Application Group ID and Delete Settings
While ($i -le ($appGroupGUIDs.Count -1))
{
$jsonDeleteUser += (@"
     {   
        "applicationGroupId": "$($appGroupGUIDs[$i])",
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
  ],
  "hoursDelay": $taskDelay,
  "description": "$taskDescription"
}
"@)

#  Delete Application Group Data Using POST api/ImmediateTask - http://localhost:7771/PWCAPI/Help/Api/POST-api-ImmediateTask
$response = Invoke-WebRequest -Uri "$serverURL/Task" -Method Post -Body $jsonDeleteUser -ContentType "application/json" -UseDefaultCredentials 

if ($response.StatusCode -eq 200)
{
    write-host -BackgroundColor DarkGreen "All User Profile Data Successfully Deleted"

}
else
{
    write-host -BackgroundColor DarkYellow "Request did not return a success ("$response.StatusCode"), please try again if unsuccessful"
}
