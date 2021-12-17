<#
    .SYNOPSIS
        This can be used to Stop and Set Autostart flag to False
    
    .DESCRIPTION
        This can be used to Stop and Set Autostart flag to False.
    
    .PARAMETER PlaceHolder
        PlaceHolder.
              
    .INPUTS
        Description of objects that can be piped to the script.

    .OUTPUTS
        Description of objects that are output by the script.
    
    .EXAMPLE
        Example of how to run the script.
    
    .LINK
        Links to further documentation.
    
    .NOTES  
        Author: Kevin Young
        Date: 12/16/2021
#>
    $ErrorActionPreference="SilentlyContinue"
    Stop-Transcript | out-null
    $ErrorActionPreference = "Continue"
    Start-Transcript -path F:\scriptoutput\stopdefaultsite-jmp-logs.txt -append
    $servers = Get-Content -Path "F:\scriptinput\jmpservers.txt"
    foreach ($server in $servers){
    Invoke-Command -ComputerName $server -ScriptBlock {
    ####Stop agent
    Write-Host "Stopping Default IIS Site on"$env:COMPUTERNAME"." -ForegroundColor Yellow
    Import-Module WebAdministration;Stop-IISSite -Name "Default Web Site" -Confirm:$false;Set-ItemProperty "IIS:\Sites\Default Web Site" serverAutoStart False
    }
    }
    Stop-Transcript