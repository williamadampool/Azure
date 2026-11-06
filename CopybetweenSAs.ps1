$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint   $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#"Set Azure Subscription.. "
#Set-AzContext -SubscriptionId "63ccb606-7c83-439a-8b89-219d2085df33"

#throw the error 
$errorActionPreference = "Stop" 

"Removing REF3Dev.."
Remove-AzureRmSqlDatabase -ResourceGroupName "ops-weur-infra-rg" -ServerName "ops-weu-azsql-ref-dev" -DatabaseName "REF3Dev" -Force

"Creating Database REF3Dev from REF3.."
New-AzureRmSqlDatabaseCopy -ResourceGroupName "ops-weur-infra-rg" -ServerName "ops-weu-azsql-ref" -DatabaseName "REF3" `
    -CopyResourceGroupName "ops-weur-infra-rg" -CopyServerName "ops-weu-azsql-ref-dev" -CopyDatabaseName "REF3Dev" -ElasticPoolName "ops-weu-azsql-ref-dev-elasticpool"

"Removing REF2Dev.."
Remove-AzureRmSqlDatabase -ResourceGroupName "ops-weur-infra-rg" -ServerName "ops-weu-azsql-ref-dev" -DatabaseName "REF2Dev" -Force

"Creating Database REF2Dev from REF2.."
New-AzureRmSqlDatabaseCopy -ResourceGroupName "ops-weur-infra-rg" -ServerName "ops-weu-azsql-ref" -DatabaseName "REF2" `
    -CopyResourceGroupName "ops-weur-infra-rg" -CopyServerName "ops-weu-azsql-ref-dev" -CopyDatabaseName "REF2Dev" -ElasticPoolName "ops-weu-azsql-ref-dev-elasticpool"