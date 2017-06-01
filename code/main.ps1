. "$PSScriptRoot\Logger.ps1"
. "$PSScriptRoot\PathFunctions.ps1"

Function Main {
[CmdletBinding()]
param( 
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()][string]$sConfigFilePath
)
    process{
        # Set power shell stream handling preferences
        $VerbosePreference = "Continue"
        $DebugPreference = "SilentlyContinue"
        $ErrorActionPreference = "Stop"

        # Define global variables
        $global:stepInitialize = 1
        $global:stepExecCmd = 2
        $global:stepValidate = 3
        $global:totalSteps = 3

        # Initialize log
        $global:logLevel = "Debug"   # Possible values: Error, Warning, Info and Debug
        New-OPSLogger -logPath "$PSScriptRoot\logs" -actionName 'Automation' | Out-Null
        Delete-OPSOldFiles -path "$PSScriptRoot\logs" -days 90 -filter *.log -ErrorAction $DebugPreference
        
        try {          
                
            Add-OPSLoggerInput "Step $global:stepInitialize of $global:totalSteps - Initializing Automation process" -summary -logLevel Info -invocation $MyInvocation

            Add-OPSLoggerInput "Changed PowerShell woking directory to $PSScriptRoot" -logLevel Debug -invocation $MyInvocation
            Add-OPSLoggerInput "Checking if parameters were set" -logLevel Debug -invocation $MyInvocation

            Add-OPSLoggerInput "Step $global:stepExecCmd of $global:totalSteps - Initializing Automation process - Loading MainConfig.xml" -summary -logLevel Info -invocation $MyInvocation
            Write-Host $sConfigFilePath

            Add-OPSLoggerInput "Step $global:stepValidate of $global:totalSteps - Initializing Validation process" -summary -logLevel Info -invocation $MyInvocation
            #Call Validation procedure      

        } catch [System.Exception] {
            throw Add-OPSLoggerException -detailedInput "An error has occured executing the main process: $($_.Exception.Message)" `
                                        -summaryInput "An error has occured while initializing package building process. Could not proceed with execution." `
                                        -step "Package building initialization process" -invocation $MyInvocation
        }
    }
}

Main -sConfigFilePath D:\git\Posh-Logger