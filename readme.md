# City of Bloomington PowerShell DSC
## Introduction
This is a small selection of PowerShell code that interacts with an Active Directory environment to configure a set of roles for DSC. It uses the same principles as outlined in Microsoft's [Separating configuration and environment data] article, except it generates the list of nodes and roles from Active Directory using groups instead of a static configuration file.

## Execution
The primary means of interaction is via the included Module, DSCviaAD. It exposes a series of functions related to configuration of the DSC environment.

If you have the [Write-Menu] module installed, you can display a menu via the [DSCMenu.ps1] script.

No means are included to configure a DSC pull server from scratch, but Microsoft's [Setting up a DSC web pull server] article will be useful in guiding the setup.

## Node selection
Nodes are generated via a [Get-ADComputer] query and their groups are filtered for ones containing a specific keyword, in this case "DSC-".

The nodes are placed into a hashtable and fed into the configuration using the -ConfigurationData parameter.

## Node Configuration
Each node's configuration is built via a configuration ([DSCServerConfig] or [DSCWorkstationConfig]), piecing together different roles depending on the data gathered in the AD query process.

There are multiple ways to approach configuration building, so adjusting the method to your environment is highly recommended. This is an adaptation of Microsoft's suggested method on their wiki.

## Internals
The most important functions from the DSCviaAD module:

| Name                              | Description   |
| ----------------------------------|-------------|
| Configure-LCMRemotely             | PSRemotes into nodes and configures their LCM to connect to the pull server |
| Initialize-DSCConfigurations      | Grabs a list of machines from AD, validates their group membership, and generates MOF files      |
| Update-PullClients                | PSRemotes into nodes and forces them to pull          |


[Separating configuration and environment data]: https://docs.microsoft.com/en-us/powershell/dsc/separatingenvdata
[Get-ADComputer]: https://technet.microsoft.com/en-us/library/ee617192.aspx?f=255&MSPPError=-2147217396
[Setting up a DSC web pull server]: https://docs.microsoft.com/en-us/powershell/dsc/pullserver
[DSCServerConfig]: https://github.com/City-of-Bloomington/DSC/blob/master/DSCviaAD/DSCServerConfig.ps1
[DSCWorkstationConfig]: https://github.com/City-of-Bloomington/DSC/blob/master/DSCviaAD/DSCWorkstationConfig.ps1
[Write-Menu]: https://github.com/QuietusPlus/Write-Menu
[DSCMenu.ps1]: https://github.com/City-of-Bloomington/DSC/blob/master/DSCMenu.ps1