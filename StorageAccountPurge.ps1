#Script Purpose: Used to remove old files from the storage accounts. 
#Retention periods are set in the variables
#Ignores all files that occur on the first day of the month.

#Instructions: Deploy script onto automation Account
#Create the following Variables in the Auatomation account
<#
        --Params for Transactional DB (e.g. BPT)
        XXXX_StartDate #Number of days to look back from current day (e.g start 180 days back)h
        XXXX_EndDate   #Number of days to look back from current day - use StartDate to calculate days outside the retention period
        
        --Params for Non-Transactional DB (e.g. BPA, EAI, BPM, BA3)
        XXXX_StartDate_NonTransactional #Number of days to look back from current day (e.g start 180 days back)
        XXXX_EndDate_NonTransactional   #Number of days to look back from current day - use StartDate to calculate days outside the retention period
        
        AccountKey_UpclearStorage1     #MAKE SURE THESE ARE ENCRYPTED!!!!
        AccountKey_UpclearStorage1b    #MAKE SURE THESE ARE ENCRYPTED!!!!
        AccountKey_UpclearStorage2 	   #MAKE SURE THESE ARE ENCRYPTED!!!!
        AccountKey_UpclearStorage3 	   #MAKE SURE THESE ARE ENCRYPTED!!!!
#>

#throw the error to the caller (if any)
$errorActionPreference = "Stop" 

#Local Variables - need to be modified to match variables in Automation Account
$StartDateLocalInt                          =  Get-AutomationVariable   -Name Prod_StartDate #Number of days to look back from current day (e.g start 180 days back)
$EndDateLocalInt                            =  Get-AutomationVariable   -Name Prod_EndDate   #Number of days to look back from current day - use StartDate to calculate days outside the retention period

#For Databases such as EAI, BA3 (non critical)
$StartDateNonTransactionalLocalInt          =  Get-AutomationVariable   -Name Prod_StartDate_NonTransactional #Number of days to look back from current day (e.g start 180 days back)
$EndDateNonTransactionalLocalInt            =  Get-AutomationVariable   -Name Prod_EndDate_NonTransactional   #Number of days to look back from current day - use StartDate to calculate days outside the retention period

$StorageAccountKeyLocalEnc_UpclearStorage1  =  Get-AutomationVariable   -Name AccountKey_UpclearStorage1 
$StorageAccountKeyLocalEnc_UpclearStorage1b =  Get-AutomationVariable   -Name AccountKey_UpclearStorage1b 
$StorageAccountKeyLocalEnc_UpclearStorage2  =  Get-AutomationVariable   -Name AccountKey_UpclearStorage2 
$StorageAccountKeyLocalEnc_UpclearStorage3  =  Get-AutomationVariable   -Name AccountKey_UpclearStorage3 
$StorageAccountNameLocal_UpclearStorage1    =  "upclearstorage1"
$StorageAccountNameLocal_UpclearStorage1b   =  "upclearstorage1b" 
$StorageAccountNameLocal_UpclearStorage2    =  "upclearstorage2"
$StorageAccountNameLocal_UpclearStorage3    =  "upclearstorage3"
$ShareNameLocal                             =  "backup"
$DirectoryPathLocal                         =  "prod"

#DO NOT MODIFY BELOW!!
#----------------------------------StorageAccountNameLocal_UpclearStorage1---------------------------------------------------#

Write-Output "Starting Purge : $StorageAccountNameLocal_UpclearStorage1 "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_UpclearStorage1"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountNameLocal_UpclearStorage1  -StorageAccountKey $StorageAccountKeyLocalEnc_UpclearStorage1 
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
Write-Output "Completed... $StorageAccountNameLocal_UpclearStorage1"
Write-Output "-----------------------------------------------------------" 
#>
#----------------------------------StorageAccountNameLocal_UpclearStorage1b---------------------------------------------------#

Write-Output "Starting Purge : $StorageAccountNameLocal_UpclearStorage1b "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_UpclearStorage1b"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountNameLocal_UpclearStorage1b  -StorageAccountKey $StorageAccountKeyLocalEnc_UpclearStorage1b 
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
Write-Output "Completed... $StorageAccountNameLocal_UpclearStorage1b"
Write-Output "-----------------------------------------------------------" 


#----------------------------------StorageAccountNameLocal_UpclearStorage2---------------------------------------------------#
Write-Output "Starting Purge : $StorageAccountNameLocal_UpclearStorage2 "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_UpclearStorage2"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountNameLocal_UpclearStorage2  -StorageAccountKey $StorageAccountKeyLocalEnc_UpclearStorage2 
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
Write-Output "Completed... $StorageAccountNameLocal_UpclearStorage2"
Write-Output "-----------------------------------------------------------" 

#----------------------------------StorageAccountNameLocal_UpclearStorage3---------------------------------------------------#
Write-Output "Starting Purge : $StorageAccountNameLocal_UpclearStorage3 "
$StartDate = (get-date).AddDays($StartDateLocalInt) 
$EndDate   = (get-date).AddDays($EndDateLocalInt) 

$NonTranStartDate = (get-date).AddDays($StartDateNonTransactionalLocalInt) 
$NonTranEndDate   = (get-date).AddDays($EndDateNonTransactionalLocalInt) 

Write-Output "Transactional DB Retention Period Start: $StartDate "
Write-Output "Transactional DB Retention Period End: $EndDate   "

Write-Output "Non-Transactional DBRetention Period Start: $NonTranStartDate "
Write-Output "Non-Transactional DBRetention Period End: $NonTranEndDate   "

Write-Output "Storage Account Name: $StorageAccountNameLocal_UpclearStorage3"
Write-Output "Share Name: $ShareNameLocal "
Write-Output "Share Name: $DirectoryPathLocal "

"Connecting to Storage Account..."
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountNameLocal_UpclearStorage3  -StorageAccountKey $StorageAccountKeyLocalEnc_UpclearStorage3 
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
Write-Output "Completed... $StorageAccountNameLocal_UpclearStorage3"
Write-Output "-----------------------------------------------------------" 
