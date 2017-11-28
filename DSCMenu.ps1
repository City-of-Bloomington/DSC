#Requires -RunAsAdministrator
Set-Location $PSScriptRoot
Import-Module DSCviaAD

try
{
    if (Get-Module -ListAvailable -Name "Write-Menu")
    {
        Import-Module Write-Menu
    }
    else
    {
        Install-Module "Write-Menu" -Scope CurrentUser
    }
}
catch
{
    Write-Host "This menu requires the PowerShell module 'Write-Menu' to be installed to function. You can install it via the PSGallery."
}

Function Show-DSCMenu
{
    While (1) {
        Write-Menu -Title "Seth's DSC Menu: Select multiple entries below (with spacebar) and press Enter to run." -Sort -MultiSelect -Entries @{

            "1a. Generate MOF Files (Servers)" = "Initialize-DSCConfigurations -nodeSet Servers"
            "1b. Generate MOF Files (Workstations)" = "Initialize-DSCConfigurations -nodeSet Workstations"
            "2. Add MOF configurations to Pull Server" = "Add-ConfigurationsToPullServer"
            "3. Configure LCM of all Nodes" = "Configure-LCMRemotely"
            "4. Configure LCM of Single Node" = "Configure-LCMRemotely (Read-Host 'Enter PC name')"
            "5. Force Nodes to Update" = "Update-PullClients"
        }
        Write-Host "Done! Returning to menu." -ForegroundColor Green
        Read-Host "Press Enter to Continue"
    }
}

Show-DSCMenu