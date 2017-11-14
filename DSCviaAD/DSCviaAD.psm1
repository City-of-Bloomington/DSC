Function Configure-LCMRemotely ($ComputerName)
{
    $ProgressPreference = ’SilentlyContinue’ # stop the annoying progress bar
    Import-Module $PSScriptRoot\LCM_PullConfig.ps1 -force
    Set-Location $PSScriptRoot
    
    if (!$ComputerName)
    {
        $NodeData = (Select-DSCNodes -nodeSet Servers)

        ForEach ($pc in $NodeData.AllNodes.Where{$_.Roles -like "*"}.NodeName) 
        {
            LCMPullConfig -ComputerName $pc
            Set-DscLocalConfigurationManager -ComputerName $pc -Verbose -Path $PSScriptRoot\LCMPullConfig
        }
    }

    else
    {
        LCMPullConfig -ComputerName $ComputerName
        Set-DscLocalConfigurationManager -ComputerName $ComputerName -Verbose -Path $PSScriptRoot\LCMPullConfig
    }
}

Function Add-ConfigurationsToPullServer
{
    $productionPath = "C:\Program Files\WindowsPowerShell\DscService\Configuration"
    $stagingPath = "$PSScriptRoot\mof"

    Copy-Item -Path "$stagingPath\Servers\*" -Destination $productionPath -Force -Verbose
    Copy-Item -Path "$stagingPath\Workstations\*" -Destination $productionPath -Force -Verbose
}

Function Initialize-DSCConfigurations ($nodeSet)
{
    Import-Module ActiveDirectory
    $MOFPath = $PSScriptRoot + "\mof"

    Write-Host "Please wait while the DSC Configs are built..."

    # Build list of nodes
    $Nodes = Select-DSCNodes -nodeSet $nodeSet -Verbose

    Switch ($nodeSet)
    {
        Servers 
        { 
            Remove-Item "$MOFPath\Servers\*" -Recurse
            Import-Module "$PSScriptRoot\DSCserverConfig.ps1" -Force
            DSCServerConfig -OutputPath "$PSScriptRoot\mof\Servers" -Verbose -ConfigurationData $Nodes
        }
        Workstations 
        { 
            Remove-Item "$MOFPath\Workstations\*" -Recurse
            Import-Module "$PSScriptRoot\DSCWorkstationConfig.ps1" -Force
            DSCWorkstationConfig -OutputPath "$PSScriptRoot\mof\Workstations" -Verbose -ConfigurationData $Nodes
        }
    }

    # Generate checksum files for change tracking
    New-DscChecksum "$MOFPath" -Verbose
}
Function Update-PullClients
{
    $Nodes = Select-DSCNodes -Servers -Verbose

    Write-Host "Forcing configuration update on clients..."

    ForEach ($pc in $Nodes.AllNodes.Where{$_.Roles -like "*"}.NodeName) 
    {
        Invoke-Command -ComputerName $pc -ScriptBlock { Update-DscConfiguration } | Format-Table
    }
}
Function Select-DSCNodes
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)] 
        [ValidateSet("Servers", "Workstations")]
        [string]$nodeSet
    )

    $Config = Import-PowerShellDataFile $PSScriptRoot\config.psd1

    Write-Host $nodeSet selected.

    switch ($nodeSet)
    {
        'Servers' { $SearchBase = $Config.ServerSearchBase} 
        'Workstations' { $SearchBase = $Config.WorkstationSearchBase }
    }

    $Nodes = Get-ADComputer -Properties MemberOf -SearchBase $SearchBase -Filter "*"

    $ConfigData = @{
        AllNodes = @(
            foreach ($Node in $Nodes)
            {
                Write-Verbose "Adding Node $Node"
                $Groups = foreach ($group in $Node.MemberOf) 
                { 
                    $strGroup = $group.split(',')[0] 
                    $strGroup = $strGroup.split('=')[1] 
                    $strGroup
                    Get-ADNestedGroups -strGroup $strGroup
                }

                @{
                    NodeName                    = $Node.Name;
                    PSDscAllowPlainTextPassword = $true
                    Roles                       = $Groups.Where{$_ -like "DSC-*"}
                }
            }
        )
    }

    return $ConfigData
}
function Get-ADNestedGroups ( $strGroup )
{
    $CurrentGroupGroups = (Get-ADGroup –Identity $strGroup –Properties MemberOf | Select-Object MemberOf).MemberOf 
    foreach ($Memgroup in $CurrentGroupGroups) 
    { 
        $strMemGroup = $Memgroup.split(',')[0] 
        $strMemGroup = $strMemGroup.split('=')[1] 
        $strMemGroup
        Get-ADNestedGroups -strGroup $strMemGroup 
    }
}