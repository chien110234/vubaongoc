﻿function Enable-LWHypervVMRemoting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName
    )

    $machines = Get-LabVM -ComputerName $ComputerName

    $script = {
        param ($DomainName, $UserName, $Password)

        $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

        Set-ItemProperty -Path $RegPath -Name AutoAdminLogon -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultUserName -Value $UserName -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultPassword -Value $Password -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $DomainName -ErrorAction SilentlyContinue

        Enable-WSManCredSSP -Role Server -Force | Out-Null
    }

    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))
        try
        {
            Invoke-LabCommand -ComputerName $machine -ActivityName SetLabVMRemoting -ScriptBlock $script -DoNotUseCredSsp -NoDisplay  `
            -ArgumentList $machine.DomainName, $cred.UserName, $cred.GetNetworkCredential().Password -ErrorAction Stop
        }
        catch
        {
            Connect-WSMan -ComputerName $machine -Credential $cred
            Set-Item -Path "WSMan:\$machine\Service\Auth\CredSSP" -Value $true
            Disconnect-WSMan -ComputerName $machine
        }
    }
}
