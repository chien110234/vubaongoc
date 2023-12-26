﻿function Repair-LabDuplicateIpAddresses
{
    [CmdletBinding()]
    param ( )

    foreach ($machine in (Get-LabMachineDefinition))
    {
        foreach ($adapter in $machine.NetworkAdapters)
        {
            foreach ($ipAddress in $adapter.Ipv4Address | Where-Object { $_.IPAddress.IsAutoGenerated })
            {
                $currentIp = $ipAddress
                $otherIps = (Get-LabMachineDefinition | Where-Object Name -ne $machine.Name).NetworkAdapters.IPV4Address

                while ($ipAddress.IpAddress -in $otherIps.IpAddress)
                {
                    $ipAddress.IpAddress = $ipAddress.IpAddress.Increment()
                }

                $adapter.Ipv4Address.Remove($currentIp) | Out-Null
                $adapter.Ipv4Address.Add($ipAddress)
            }
        }
    }
}