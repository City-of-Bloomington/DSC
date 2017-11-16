[DscLocalConfigurationManager()]
Configuration LCMPullConfig 
{
    param ([string]$ComputerName)
    
    Node $ComputerName 
    {
        Settings 
        {
            RefreshMode = "PULL";
            RebootNodeIfNeeded = $false;
            RefreshFrequencyMins = 30;
            ConfigurationModeFrequencyMins = 30;
            ConfigurationMode = "ApplyAndAutoCorrect";
        }

        ConfigurationRepositoryWeb COB-PullSrv
        {
                ServerURL                       = "http://DSC:8080/PSDSCPullServer.svc"
                RegistrationKey                 = "990c410f-e849-42f8-8e42-42a8a1d67e6c"
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