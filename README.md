# Posh-Logger
Logging module written in Power Shell

Originally, this solution was conceived to meet the need for "logging" the execution of any procedure, and it can be imported into any solution where PowerShell code can be used. This solution was originally written during free time between projects to keep my mind occupied and to continue using my development skills. The entire module was designed and written in 4 full days of work, and this represents the initial release of the solution as a product.

Considering Microsoft's significant effort towards integrating with Linux systems, we can confidently state that this solution can be imported into various platforms and solutions, supporting a wide range of languages and architectures.

You can obtain it by cloning the repository: https://github.com/ottogori/Posh-Logger.git

Along with the code, an extensive "how to" has been written through comments formalized in the "help" section of each of the complex functions. Therefore, I will focus on demonstrating the functionality of its main modules without delving too much into the explanation of the encapsulated and/or secondary procedures. These "how to" guides can be accessed using the get-help function for each of the procedures. An example of this is shown below: 

~~~powershell
    <#Write-OPSLogInput
    .SYNOPSIS
        Writes a log input to a stream based on the log level.

    .DESCRIPTION
        This function chooses the stream to write to based on the log level parameter and writes the input to the chosen stream.

    .PARAMETER logInput
        Input to write to the stream.
        
    .PARAMETER logLevel
        Level of the log input to determine which stream to write to.
        - Info and Verbose writes to the Verbose stream.
        - Debug writes to the Debug stream
        - Warning writes to the Warning stream
        - Error writes to the Error stream
        
        This is an optional parameter. If not set, it will write to the verbose stream.
        
    .NOTES
        Author: Otto Gori
        Data: 06/2017
        testVersion: 0.0
        Should be run on systems with PS >= 3.0
        
    .INPUT EX
        Add-OPSLogInput -logInput "Initiating foobar"
        Add-OPSLogInput -logInput "Error on foobar" -logLevel Error
        
    .OUTPUTS
        Null
        
    #>
    function Write-OPSLogInput{
    [CmdletBinding()]
    param(
        [parameter(Position=0, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()][string]$logInput = $(throw "logInput is mandatory and was not set."),
        [ValidateSet('verbose','info','debug','warning','error')][string]$logLevel = "verbose"
    )
        process {
            switch ($logLevel) {
                warning{Write-Warning $logInput}
                error{Write-Error $logInput}
                debug{Write-Debug $logInput}
                {(($_ -eq 'verbose') -or ($_ -eq 'info'))}{Write-Verbose $logInput}
                Default{Write-Verbose $logInput}
            }
        }
    }
~~~

That said, let's move on to the initialization of the logging procedure, which requires the parameters demonstrated below and is initiated on the last line of the code snippet.

~~~powershell
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
~~~

The architecture of this solution allows you to create logging with different complexities simultaneously.

This is achieved by providing the option to log in "debug" or "info" mode, which allows for detailed logging as well as a simpler and more user-friendly log, which can be attached to an email, for example, at the end of a deployment procedure or environment preparation. A third option is the error state log, which, in addition to the developer's comments, includes the original error message, enabling an accurate diagnosis of the problem.

The debug-level log includes everything from the execution step listed by the developer to the function where the error originated. On the other hand, the informational-level log is more descriptive and easier to interpret, making it suitable for business reporting, if required (though in rare situations).

The solution even includes a log rotation procedure, filtering the logs by date and name.

~~~powershell
    function Delete-OPSOldFiles {
        [CmdletBinding()]
        Param(
            [parameter(Position = 0,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true
                    )][Alias('FullName')]
            [ValidateNotNullOrEmpty()][string]$path = $(throw "path is mandatory and was not set."),
            [parameter(Mandatory=$true)]
            [int]$days,
            [string]$filter = "*"
        )
        begin {
            $limit = (Get-Date).AddDays(-$days)
        }
        process {
            Add-OPSLoggerInput "Deleting files from $path\$filter older then $limit ($days)..." -logLevel Info -invocation $MyInvocation
            Get-ChildItem "$path" -filter $filter | `
                        Where-Object { -not $_.PSIsContainer -and $_.CreationTime -lt $limit } | `
                        Add-OPSLoggerInput -format "Deleting file {0}" -logLevel Debug -invocation $MyInvocation -passthru | `
                        Remove-Item
        }
    }

    #Call for this function
    Delete-OPSOldFiles -path "$PSScriptRoot\logs" -days 90 -filter *.log -ErrorAction $DebugPreference
~~~

The execution of the log files initialization:

~~~powershell
    <#New-OPSLogger
    .SYNOPSIS
        Create a new pair of summary and detailed log files.

    .DESCRIPTION
        Creates two new log files on $logPath directory, one for detailed log and one for summary log, following the naming convention below.
        [Current date as dd-MM-yyyy] [$actionName] detailed.log
        [Current date as dd-MM-yyyy] [$actionName] summary.log
        Examples:
            11-02-2016 AllinOne_5.0.3.5_Update detailed.log
            11-02-2016 AllinOne_5.0.3.5_Update summary.log
        
        If any of the log files already exists, it will rename the existing file with a number version at the end
        unless explicitly requesting to replace any existing file with the alwaysReplace parameter.

    .PARAMETER logPath
        Path to where the log file will be created
        
    .PARAMETER actionName
        Name of the package to use as part of the file name to identify which package processing created the log file
        
    .PARAMETER alwaysReplace
        This is a switch parameter. If set, will always replace log file if one exists with the same name.
        
    .PARAMETER alwaysReplace
        This is a switch parameter. If set, The logger object stored in $global:logger will be returned.
        
    .NOTES
        Author: Otto Gori
        Data: 06/2017
        testVersion: 0.0
        Application user must have permition to create and rename files on the directory specified by $logPath parameter
        Should be run on systems with PS >= 3.0

    .INPUT EX
        New-OPSLogger -logPath "C:\logs" -actionName "AllinOne_5.0.3.5_Update"
        New-OPSLogger -logPath "C:\logs" -actionName "AllinOne_5.0.3.5_Update" -alwaysReplace
        
    .OUTPUTS
        If passthru is set, a Dictionary with a SummaryLogFile member containg the log path, the full path to the newly created summary log file
        and a DetailedLogFile member containg the full path to the newly created detailed log file will be returned.
        The returned object is also stored in $global:logger
        If passthru is not set, the Dictionary will just be stored in $global:logger and not be returned.
        
    #>
    function New-OPSLogger{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()][string]$logPath = $(throw "logPath is mandatory and was not set."),
        [ValidateNotNullOrEmpty()][string]$actionName = $(throw "actionName is mandatory and was not set."),
        [switch]$alwaysReplace,
        [switch]$passthru
    )
        $summaryLogFile = New-OPSLogFile -logPath $logPath -actionName $actionName -logType summarized -alwaysReplace:$alwaysReplace
        $detailedLogFile = New-OPSLogFile -logPath $logPath -actionName $actionName -logType detailed -alwaysReplace:$alwaysReplace
        
        $global:logger = @{
            LogPath = $logPath
            SummaryLogFile = $summaryLogFile
            DetailedLogFile = $detailedLogFile
        }
        
        if ($passthru) {
            Write-Output $global:logger
        }
    }
~~~ 

It will create two logs following the standard nomenclature described below:
[Current date as dd-MM-yyyy] [$actionName] detailed.log
[Current date as dd-MM-yyyy] [$actionName] summary.log

Example:
11-02-2016 AllinOne_5.0.3.5_Update detailed.log
11-02-2016 AllinOne_5.0.3.5_Update summary.log

With the contents shown below, where a call to the nonexistent function "asd" was included to illustrate the third case, an error.
![](./img/log.png)

To include more data in the logs, simply use the following function calls: 
~~~powershell
Add-OPSLoggerInput -logInput "Initiating foobar" -logLevel Info -silent -invocation $MyInvocation
~~~

Or for errors:
~~~powershell
Add-OPSLoggerException "Error on foobar" -step "foobar" -invocation $MyInvocation
~~~
