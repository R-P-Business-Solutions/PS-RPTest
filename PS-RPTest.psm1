function Test-RPPsVersion
{
    <#
    .SYNOPSIS
        Checks if a session is elevated

    .NOTES
        Name: Test-RPSessionIsElevated
        Author: David Porcher

    .EXAMPLE
        Test-PSSessionIsElevated
    #>

    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            Position = 0
        )]
        [version] $version
    )
    
    BEGIN
    {
        [version] $runningPsVersion = $PSVersionTable.PSVersion
    }

    PROCESS
    {
        return $version -le $runningPsVersion
    }

    END
    {

    }
}
function Test-RPIsOS
{
    <#
    .SYNOPSIS
        Checks if a session is elevated

    .NOTES
        Name: Test-RPSessionIsElevated
        Author: David Porcher

    .EXAMPLE
        Test-PSSessionIsElevated
    #>

    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            Position = 0
        )]
        [ValidateSet('Windows', 'Linux', 'MacOS')]
        [string] $os
    )

    BEGIN
    {
        $AfterPs6 = Test-RPPsVersion -version 6.0
    }

    PROCESS
    {
        if($AfterPs6)
        {
            if($os -eq 'Windows')
            {
                return $IsWindows
            }
            elseif($os -eq 'Linux')
            {
                return $IsLinux
            }
            elseif($os -eq 'MacOS')
            {
                return $IsMacOS
            }
            else
            {
                Write-Error "Unknown OS $($os)"
            }
        }
        else
        {
            if($os -eq 'Windows')
            {
                try
                {
                    $null = (Get-CimInstance Win32_OperatingSystem)
                    return $true
                }
                catch
                {
                    return $false
                }
            }
            else
            {
                Write-Error -Message "Test-RPIsOS is not supported on this plattform prior to PS version 6.0"
            }
        }
    }

    END
    {

    }
}
Function Test-RPSessionIsElevated
{
    <#
    .SYNOPSIS
        Checks if a session is elevated

    .NOTES
        Name: Test-RPSessionIsElevated
        Author: David Porcher

    .EXAMPLE
        Test-PSSessionIsElevated
    #>

    [CmdletBinding()]

    param
    (
        
    )

    BEGIN
    {
        [Security.Principal.WindowsPrincipal] $WindowsPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        [string] $builtInAdminRoleName                          = "Administrator";
    }

    PROCESS
    {
        if ($WindowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole] $builtInAdminRoleName))
        {
            return $true;
        }
        else
        {
            return $false;
        }
    }

    END
    {

    }
}
Function Test-CommandExists
{
    <#
    .SYNOPSIS
        Checks if the maschine can run the given command

    .NOTES
        Name: Test-CommandExists
        Author: David Porcher

    .EXAMPLE
        Test-CommandExists -command "ping"
    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            Position = 0
        )]
        [string] $command
    )

    BEGIN {
        [string] $errorAction = "stop";
    }

    PROCESS {
        try {
            if (Get-Command $command -ErrorAction $errorAction) {
                return $true;
            }
        }
        Catch {
            return $false;
        }
    }

    END {}
}
Function Test-NetAdapterIsUp
{
    <#
    .SYNOPSIS
        Checks if at least one Network Adapter is connected to a network

    .NOTES
        Name: Test-NetAdapterIsUp
        Author: David Porcher

    .EXAMPLE
        Test-NetAdapterIsUp
    #>

    [CmdletBinding()]

    param
    (

    )

    BEGIN
    {
        [string] $statusUp = "Up";
    }

    PROCESS
    {
        foreach($adapter in Get-NetAdapter)
        {
            if($adapter.status -eq $statusUp)
            {
                return $true;
            }
        }
        return $false;
    }

    END
    {

    }
}
Function Test-NetIsMetered
{
    <#
    .SYNOPSIS
        Checks if the network connection is metered

    .NOTES
        Name: Test-NetIsMetered
        Author: David Porcher

    .EXAMPLE
        Test-NetIsMetered
    #>

    [CmdletBinding()]

    param
    (

    )

    BEGIN
    {
        [string] $networkCostTypeUnrestricted   = "Unrestricted"; # Default value
        [string] $networkCostTypeUnknown        = "Unknown";      # Default value in Windows Server 2016

        if(-not (Test-RPIsOS -os "Windows")) { Write-Error -Message "Test-RPNetIsMetered is not supported on this plattform" }
    }

    PROCESS
    {
        if(Test-NetAdapterIsUp)
        {
            [void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime];
            $cost = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile().GetConnectionCost();
            
            return  $cost.ApproachingDataLimit -or
                    $cost.OverDataLimit -or
                    $cost.Roaming -or
                    $cost.BackgroundDataUsageRestricted -or
                    (($cost.NetworkCostType -ne $networkCostTypeUnrestricted) -and ($cost.NetworkCostType -ne $networkCostTypeUnknown));
        }
        else
        {
            return $false;
        }
    }

    END
    {

    }
}