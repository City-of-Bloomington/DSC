$Config = Import-PowerShellDataFile $PSScriptRoot\config.conf

Function Configure-LCMRemotely ($ComputerName)
{
    $Config = Import-PowerShellDataFile $PSScriptRoot\config.conf
    $ProgressPreference = 'SilentlyContinue' # stop the annoying progress bar
    Import-Module $PSScriptRoot\LCM_PullConfig.ps1 -force
    Set-Location $PSScriptRoot
    
    if (!$ComputerName)
    {
        $NodeData = (Select-DSCNodes -nodeSet Servers)
        ForEach ($pc in $NodeData.AllNodes.Where{
                $_.Roles -like "*"
            }.NodeName)
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
    Copy-Item -Path ("{0}\Servers\*" -f $Config.MOFPath) -Destination $Config.PullServerConfigPath -Force -Verbose
    Copy-Item -Path ("{0}\Workstations\*" -f $Config.MOFPath) -Destination $Config.PullServerConfigPath -Force -Verbose
}

function Initialize-DSCConfigurations
{
    param
    (
        $nodeSet
    )
    
    Import-Module ActiveDirectory
    $Config = Import-PowerShellDataFile $PSScriptRoot\config.conf
    
    Write-Output "Please wait while the DSC Configs are built..."
    
    # Build list of nodes
    $Nodes = Select-DSCNodes -nodeSet $nodeSet
    
    Switch ($nodeSet)
    {
        Servers
        {
            Remove-Item ("{0}\Servers\*" -f $Config.MOFPath) -Recurse
            Import-Module "$PSScriptRoot\DSCserverConfig.ps1" -Force
            DSCServerConfig -OutputPath ("{0}\Servers\" -f $Config.MOFPath) -Verbose -ConfigurationData $Nodes
        }
        Workstations
        {
            Remove-Item ("{0}\Workstations\*" -f $Config.MOFPath) -Recurse
            Import-Module "$PSScriptRoot\DSCWorkstationConfig.ps1" -Force
            DSCWorkstationConfig -OutputPath ("{0}\Workstations\" -f $Config.MOFPath) -Verbose -ConfigurationData $Nodes
        }
    }
    
    # Generate checksum files for change tracking
    New-DscChecksum $Config.MOFPath -Verbose
}

Function Update-PullClients
{
    $Nodes = Select-DSCNodes -Servers -Verbose
    
    Write-Output "Forcing configuration update on clients..."
    
    ForEach ($pc in $Nodes.AllNodes.Where{
            $_.Roles -like "*"
        }.NodeName)
    {
        Invoke-Command -ComputerName $pc -ScriptBlock {
            Update-DscConfiguration
        } | Format-Table
    }
}

function Select-DSCNodes
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Servers', 'Workstations')]
        [string]$nodeSet
    )
    
    $Config = Import-PowerShellDataFile $PSScriptRoot\config.conf
    
    Write-Verbose "$nodeSet selected."
    
    switch ($nodeSet)
    {
        'Servers' {
            $SearchBase = $Config.ServerSearchBase
        }
        'Workstations' {
            $SearchBase = $Config.WorkstationSearchBase
        }
    }
    
    $Nodes = Get-ADComputer -Properties MemberOf -SearchBase $SearchBase -Filter "*"
    
    $ConfigData = @{
        AllNodes   = @(
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
                    NodeName                      = $Node.Name;
                    PSDscAllowPlainTextPassword   = $true
                    Roles                         = $Groups.Where{
                        $_ -like "DSC-*"
                    }
                }
            }
        )
    }
    
    return $ConfigData
}

function Get-ADNestedGroups ($strGroup)
{
    $NestedGroups = (Get-ADGroup –Identity $strGroup –Properties MemberOf | Select-Object MemberOf).MemberOf
    foreach ($ChildGroup in $NestedGroups)
    {
        $MemberGroup = $ChildGroup.split(',')[0]
        $MemberGroup = $MemberGroup.split('=')[1]
        $MemberGroup
        Get-ADNestedGroups -strGroup $MemberGroup
    }
}