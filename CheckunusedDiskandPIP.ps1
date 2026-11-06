
$subs=Get-AzSubscription


foreach($sub in $subs)
{
    Select-AzSubscription -Subscription $sub | Out-Null
    Write-Output "`nChecking subscription : $($sub.Name) ($($sub.id))"

    #Check for unconnected managed disks
    $disks = Get-AzDisk
    foreach($disk in $disks)
    {
    }
    $pubIPs = Get-AzPublicIpAddress
    $NATGWs = Get-AzNatGateway
    foreach($pubIP in $pubIPs)
    {
        if($pubIP.IpConfiguration -eq $null)
        {
            Write-Output "  Public IP $($pubIP.name) not connected to VM/LB, but could be used by different resource such as NAT Gateway"
            $foundWithResource = $false
            foreach($NATGW in $NATGWs)
            {
                foreach($GWPubIP in $NATGW.PublicIpAddresses)
                {
                    if($GWPubIP.Id -eq $PubIP.id)
                    {
                        Write-Output "    IP $($pubIP.name) used by NAT Gateway $($NATGW.Name)"
                        $foundWithResource = $true
                    }
                }
            }

        }
    }
}