#throw the error to the caller (if any)
$errorActionPreference = "Stop" 

#Local Variables - need to be modified to match variables in Automation Account
$StartDateLocalInt                          =  Get-AutomationVariable   -Name Prod_StartDate #Number of days to look back from current day (e.g start 180 days back)
$EndDateLocalInt                            =  Get-AutomationVariable   -Name Prod_EndDate   #Number of days to look back from current day - use StartDate to calculate days outside the retention period

#For Databases such as EAI, BA3 (non critical)
$StartDateNonTransactionalLocalInt          =  Get-AutomationVariable   -Name Prod_StartDate_NonTransactional #Number of days to look back from current day (e.g start 180 days back)
$EndDateNonTransactionalLocalInt            =  Get-AutomationVariable   -Name Prod_EndDate_NonTransactional   #Number of days to look back from current day - use StartDate to calculate days outside the retention period

$StorageAccount  =  Get-AutomationVariable   -Name AccountKey
$ShareNameLocal                             =  "backup"
$DirectoryPathLocal                         =  "prod"

#DO NOT MODIFY BELOW!!

Write-Output "Starting Purge : $StorageAccoun "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_ Storage1"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccount  -StorageAccountKey $StorageAccountKeyLocalEnc_ Storage1 
$shareName = $ShareNameLocal
$directoryPath = $DirectoryPathLocal 
$DirIndex = 0
$dirsToList = New-Object System.Collections.Generic.List[System.Object]

$shareroot = Get-AzStorageFile -ShareName $shareName -Path $directoryPath -context $ctx 
$dirsToList += $shareroot 
$removedfilecount = 0

while ($dirsToList.Count -gt $DirIndex)
{
     $dir = $dirsToList[$DirIndex]
     $DirIndex ++
     $fileListItems = $dir | Get-AzStorageFile
     $dirsListOut = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFileDirectory"}
     $dirsToList += $dirsListOut
     $files = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFile"}
    
    foreach($file in $files)
    {
        $task = $file.CloudFile.FetchAttributesAsync()
        $task.Wait()
        
        #Transactional DBS (e.g. BPT)
        if ($file.CloudFile.Name  -like "*BPT*")
        {         
          if ($file.CloudFile.Properties.LastModified -ge $StartDate -and $file.CloudFile.Properties.LastModified -lt $EndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $startdate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
        
         #Non-Transactional DBS (e.g. EAI, BA3..)
        if ($file.CloudFile.Name -notlike "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $NonTranStartDate -and $file.CloudFile.Properties.LastModified -lt $NonTranEndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $NonTranStartDate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
       
    } 
}
Write-Output "Number of files removed $removedfilecount "
Write-Output "Completed... $StorageAccountNameLocal_ Storage1"
Write-Output "-----------------------------------------------------------" 

Write-Output "Starting Purge : $StorageAccountNameLocal_ Storage1b "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_ Storage1b"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountNameLocal_ Storage1b  -StorageAccountKey $StorageAccountKeyLocalEnc_ Storage1b 
$shareName = $ShareNameLocal
$directoryPath = $DirectoryPathLocal 
$DirIndex = 0
$dirsToList = New-Object System.Collections.Generic.List[System.Object]

$shareroot = Get-AzStorageFile -ShareName $shareName -Path $directoryPath -context $ctx 
$dirsToList += $shareroot 
$removedfilecount = 0

while ($dirsToList.Count -gt $DirIndex)
{
     $dir = $dirsToList[$DirIndex]
     $DirIndex ++
     $fileListItems = $dir | Get-AzStorageFile
     $dirsListOut = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFileDirectory"}
     $dirsToList += $dirsListOut
     $files = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFile"}
    
    foreach($file in $files)
    {
        $task = $file.CloudFile.FetchAttributesAsync()
        $task.Wait()
        
        #Transactional DBS (e.g. BPT)
        if ($file.CloudFile.Name  -like "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $StartDate -and $file.CloudFile.Properties.LastModified -lt $EndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $startdate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
        
         #Non-Transactional DBS (e.g. EAI, BA3..)
        if ($file.CloudFile.Name  -notlike "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $NonTranStartDate -and $file.CloudFile.Properties.LastModified -lt $NonTranEndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $NonTranStartDate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
       
    } 
}

Write-Output "Number of files removed $removedfilecount "
Write-Output "Completed... $StorageAccountNameLocal_ Storage1b"
Write-Output "-----------------------------------------------------------" 

Write-Output "Starting Purge : $StorageAccountNameLocal_ Storage2 "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_ Storage2"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccount
$shareName = $ShareNameLocal
$directoryPath = $DirectoryPathLocal 
$DirIndex = 0
$dirsToList = New-Object System.Collections.Generic.List[System.Object]

$shareroot = Get-AzStorageFile -ShareName $shareName -Path $directoryPath -context $ctx 
$dirsToList += $shareroot 
$removedfilecount = 0

while ($dirsToList.Count -gt $DirIndex)
{
     $dir = $dirsToList[$DirIndex]
     $DirIndex ++
     $fileListItems = $dir | Get-AzStorageFile
     $dirsListOut = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFileDirectory"}
     $dirsToList += $dirsListOut
     $files = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFile"}
    
    foreach($file in $files)
    {
        $task = $file.CloudFile.FetchAttributesAsync()
        $task.Wait()
        
        #Transactional DBS (e.g. BPT)
        if ($file.CloudFile.Name  -like "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $StartDate -and $file.CloudFile.Properties.LastModified -lt $EndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $startdate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
        
         #Non-Transactional DBS (e.g. EAI, BA3..)
        if ($file.CloudFile.Name  -notlike "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $NonTranStartDate -and $file.CloudFile.Properties.LastModified -lt $NonTranEndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $NonTranStartDate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
       
    } 
}
Write-Output "Number of files removed $removedfilecount "
Write-Output "Completed... $StorageAccountNameLocal_ Storage2"
Write-Output "-----------------------------------------------------------" 

Write-Output "Starting Purge : $StorageAccountNameLocal_ Storage3 "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_ Storage3"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountNameLocal -StorageAccountKey $StorageAccount
$shareName = $ShareNameLocal
$directoryPath = $DirectoryPathLocal 
$DirIndex = 0
$dirsToList = New-Object System.Collections.Generic.List[System.Object]

$shareroot = Get-AzStorageFile -ShareName $shareName -Path $directoryPath -context $ctx 
$dirsToList += $shareroot 
$removedfilecount = 0

while ($dirsToList.Count -gt $DirIndex)
{
     $dir = $dirsToList[$DirIndex]
     $DirIndex ++
     $fileListItems = $dir | Get-AzStorageFile
     $dirsListOut = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFileDirectory"}
     $dirsToList += $dirsListOut
     $files = $fileListItems | where {$_.GetType().Name -eq "AzureStorageFile"}
    
    foreach($file in $files)
    {
        $task = $file.CloudFile.FetchAttributesAsync()
        $task.Wait()
        
        #Transactional DBS (e.g. BPT)
        if ($file.CloudFile.Name  -like "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $StartDate -and $file.CloudFile.Properties.LastModified -lt $EndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $startdate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
        
         #Non-Transactional DBS (e.g. EAI, BA3..)
        if ($file.CloudFile.Name  -notlike "*BPT*")
        {
          if ($file.CloudFile.Properties.LastModified -ge $NonTranStartDate -and $file.CloudFile.Properties.LastModified -lt $NonTranEndDate)   
          {
              if ($file.CloudFile.Properties.LastModified.day -ne '01'  )
              {
                  $FileRemoved = $file.CloudFile.Name 
                  Write-Output "Removing File $FileRemoved"
                  $file | Remove-AzStorageFile
                  $removedfilecount ++ 
              }
          }
          if ($file.CloudFile.Properties.LastModified -lt $NonTranStartDate)
          {            
              $FileRemoved = $file.CloudFile.Name 
              Write-Output "Removing File $FileRemoved"
              $file | Remove-AzStorageFile
              $removedfilecount ++ 
          }
        }
       
    } 
}
Write-Output "Number of files removed $removedfilecount "
Write-Output "Completed... $StorageAccountNameLocal"
Write-Output "-----------------------------------------------------------" 
