
Select-AzSubscription -SubscriptionId '<name>'

Remove-AzSqlVM -ResourceGroupName <name> -Name <name>

$vm = Get-AzVM -Name <name>-ResourceGroupName <name>
New-AzSqlVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Location $vm.Location `  -LicenseType PAYG -SqlManagementType LightWeight