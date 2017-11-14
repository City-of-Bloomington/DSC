$Config = Import-PowerShellDataFile $PSScriptRoot\config.psd1

[DscLocalConfigurationManager()]
Configuration LCMPullConfig {

    param ([string]$ComputerName)
    Node $ComputerName {
        Settings {
            RefreshMode = "PULL";
            RebootNodeIfNeeded = $false;
            RefreshFrequencyMins = 30;
            ConfigurationModeFrequencyMins = 30;
            ConfigurationMode = "ApplyAndAutoCorrect";
        }

        ConfigurationRepositoryWeb COB-PullSrv {
                ServerURL                       = $Config.DSCServer
                RegistrationKey                 = $Config.RegistrationKey
                ConfigurationNames              = @("$ComputerName")
                AllowUnsecureConnection         = $true
        
        }

        ReportServerWeb COB-ReportSrv
        {
            ServerURL               = '$DSCServer'
            AllowUnsecureConnection = $true
        }
    }
}