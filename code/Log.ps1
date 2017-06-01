<#New-OPSLogFile
.SYNOPSIS
    Create new log file

.DESCRIPTION
    Creates a new log file on $logPath directory following the naming convention below.
    [Current date as dd-MM-yyyy] [$actionName] [$logType].log
    Examples:
        11-02-2016 Update detailed.log
        11-02-2016 Update summary.log
    
    If the log file already exists, it will rename the existing file with a number version at the end
    unless explicitly requesting to replace existing file with the alwaysReplace parameter.

.PARAMETER logPath
    Path to where the log file will be created
    
.PARAMETER actionName
    Name of the package to use as part of the file name to identify which package processing created the log file
    
.PARAMETER logType
    Type of the log (summary or detailed)
    
    This is an optional parameter. If not included, the log file name will be just [Current date as dd-MM-yyyy] [$actionName].log
    
.PARAMETER alwaysReplace
    This is a switch parameter. If set, will always replace log file if one exists with the same name.
    
.NOTES
    Author: Otto Gori
    Data: 06/2017
    testVersion: 0.1
    Application user must have permition to create and rename files on the directory specified by $logPath parameter
    Should be run on systems with PS >= 3.0

.INPUT EX
    New-OPSLogFile -logPath "C:\logs" -actionName "AllinOne_5.0.3.5_Update" -logType detailed
    New-OPSLogFile -logPath "C:\logs" -actionName "AllinOne_5.0.3.5_Update" -logType summary -alwaysReplace
    
.OUTPUTS
    String with the full path to the newly created log file
    
#>
function New-OPSLogFile{
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()][string]$logPath = $(throw "logPath is mandatory and was not set."),
    [ValidateNotNullOrEmpty()][string]$actionName = $(throw "actionName is mandatory and was not set."),
    [string]$logType,
    [switch]$alwaysReplace
)
    [string]$dateString = (Get-Date -UFormat %d-%b-%Y)

    if ($logType){
        [string]$logFileName = "$dateString $actionName $logType"
    }
    else {
        [string]$logFileName = "$dateString $actionName"
    }
    [string]$logFullName = "$logFileName.log"
    
    if ($alwaysReplace) {
        Format-OPSLogInput "Creating log file at '$logPath\$logFullName' overriding if exists" | Write-Verbose
        New-Item "$logPath\$logFullName" -ItemType file -Force | Out-Null
    }
    else {
        if (Test-Path "$logPath\$logFullName") {
            Format-OPSLogInput "'$logPath\$logFullName' already exists. Attempting to rename old log file." | Write-Verbose
            Rename-OPSLastLogFile -logPath $logPath -logFileName $logFileName
        }
        
        Format-OPSLogInput "Creating log file at '$logPath\$logFullName'" | Write-Verbose
        New-Item "$logPath\$logFullName" -ItemType file -Force | Out-Null
    }
    Format-OPSLogInput "File '$logPath\$logFullName' created" | Write-Verbose
    return "$logPath\$logFullName"
}

<#Rename-OPSLastLogFile
.SYNOPSIS
    Adds a version number to the name of an old log file.

.DESCRIPTION
    Renames a log file adding a version number to keep log files from being replaced.
    It searches for all the log files that has the same name already with a version number
    and picks the next number to the maximum version number found to use as the version number.
    
    It is used by New-OPSLogFile to keep all log files for the same date, package and log type.

.PARAMETER logPath
    Path to where the log file will be created.
    
.PARAMETER logFileName
    Name of the log file without the extension.
    
.NOTES
    Author: Otto Gori
    Data: 06/2017
    testVersion: 0.0
    Application user must have permition to create and rename files on the directory specified by $logPath parameter
    Should be run on systems with PS >= 3.0

.INPUT EX
    Rename-OPSLastLogFile -logPath "C:\logs" -logFileName "11-02-2016 AllinOne_5.0.3.5_Update detailed"
    Rename-OPSLastLogFile -logPath "C:\logs" -logFileName "11-02-2016 AllinOne_5.0.3.5_Update summary"
    
.OUTPUTS
    Null
    
#>
function Rename-OPSLastLogFile{
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()][string]$logPath = $(throw "logPath is mandatory and was not set."),
    [ValidateNotNullOrEmpty()][string]$logFileName = $(throw "logFileName is mandatory and was not set.")
)
    $files = get-childitem "$logPath\${logFileName}_*.log"
    [int]$lastFileNum = 0
    
    if ($files) {
        Format-OPSLogInput "Additional old log files for '$logFileName' found. Searching for highest number suffix." | Write-Verbose
        $filesNumMeasure = $files | Select-Object -ExpandProperty BaseName `
                                  | Select-String -pattern '\d+$' `
                                  | Select-Object -ExpandProperty matches `
                                  | Select-Object -ExpandProperty value `
                                  | ForEach-Object {[int]$_} `
                                  | Measure-Object -Maximum
        
        [int]$filesNumCount = $filesNumMeasure | Select-Object -ExpandProperty Count
        
        if ($filesNumCount -gt 0) {
            $lastFileNum = $filesNumMeasure | Select-Object -ExpandProperty Maximum
        }
        
        Format-OPSLogInput "Highest number suffix found for '$logFileName' is $lastFileNum" | Write-Verbose
    }
    
    [int]$nextFileNum = $lastFileNum + 1
    
    [string]$oldFileName = "$logPath\$logFileName.log"
    [string]$newFileName = "${logFileName}_$nextFileNum.log"
    
    Format-OPSLogInput "Attepting to rename log file '$oldFileName' to '$newFileName'" | Write-Verbose
    Rename-Item $oldFileName $newFileName -Force
    Format-OPSLogInput "Succeeded renaming log file '$oldFileName' to '$newFileName'" | Write-Verbose
}

<#Format-OPSLogInput
.SYNOPSIS
    Formats a log input

.DESCRIPTION
    Formats the input of a log by adding to the input the current date and optionaly the log level and function name.

.PARAMETER logInput
    Log input that will be formated.
    
.PARAMETER logLevel
    Level of the log input.
    
    This is an optional parameter.
    
.PARAMETER invocation
    The invocation variable of the function that has the name to be put on the log input.
    
    This is an optional parameter.
    
.NOTES
    Author: Otto Gori
    Data: 06/2017
    testVersion: 0.0
    
.INPUT EX
    Format-OPSLogInput -logInput "Initiating foobar"
    Format-OPSLogInput -logInput "Error on foobar" -logLevel Error -invocation $MyInvocation
    
.OUTPUTS
    String with the formated log input.
    
#>
function Format-OPSLogInput{
[CmdletBinding()]
param(
    [parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()][string]$logInput = $(throw "logInput is mandatory and was not set."),
    [string]$logLevel,
    $invocation
)
    process {
        $dateTime = Get-Date -Format "dd-MM-yyyy HH:mm:ss.ffff"
        
        if ($invocation) {
            $functionName = $invocation.MyCommand.Name
            $formatedInput = "$dateTime - [$functionName] $logInput"
        }
        else {
            $formatedInput = "$dateTime - $logInput"
        }
        
        if ($logLevel) {
            return "[$logLevel]: $formatedInput"
        }
        else {
            return "$formatedInput"
        }
    }
}

<#Add-OPSLogInput
.SYNOPSIS
    Adds a log input to a log file.

.DESCRIPTION
    This function formats the input adding the current date and log level to the input, adds it to the log file
    and optionaly writes the input to a stream according to the log level.

.PARAMETER logFileName
    Full path to the log's file.
    
.PARAMETER logInput
    Input to write to the log. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input.
    
.PARAMETER logLevel
    Level of the log input. This parameter is also used to determine which stream to write to.
    - Info and Verbose writes to the Verbose stream.
    - Debug writes to the Debug stream
    - Warning writes to the Warning stream
    - Error writes to the Error stream
    
    This is an optional parameter. If not set, only the current date will be added to the input.
    
.PARAMETER invocation
    The invocation variable of the function that has the name to be put on the log input.
    
    This is an optional parameter.
    
.PARAMETER silent
    This is a switch parameter. If set, nothing will be written to any stream.
    If omitted the input (without formating) will be sent to a stream.
    
.NOTES
    Author: Otto Gori
    Data: 06/2017
    testVersion: 0.1
    Application user must have write permition to the log file
    Should be run on systems with PS >= 3.0
    
.INPUT EX
    Add-OPSLogInput -logFileName "C:\logs\11-02-2016 AllinOne_5.0.3.5_Update detailed" -logInput "Initiating foobar" -logLevel Info -silent
    Add-OPSLogInput -logFileName "C:\logs\11-02-2016 AllinOne_5.0.3.5_Update summary" -logInput "Error on foobar" -logLevel Error -invocation $MyInvocation
    
.OUTPUTS
    Null
    
#>
function Add-OPSLogInput{
[CmdletBinding()]
param(
    [parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()][string]$logInput = $(throw "logInput is mandatory and was not set."),
    [ValidateNotNullOrEmpty()][string]$logFileName = $(throw "logFileName is mandatory and was not set."),
    [string]$logLevel = "Info",
    $invocation,
    [switch]$silent
)
    begin {
        $globalLevelNum = Convert-OPSLogLevel $global:logLevel
        $levelNum = Convert-OPSLogLevel $logLevel
    }
    process {        
        if ($levelNum -ge $globalLevelNum) {
            [string]$formatedInput = Format-OPSLogInput -logInput $logInput -logLevel $logLevel -invocation $invocation
            Add-Content $logFileName "$formatedInput"
        }        
        if (-not $silent) {
            Write-OPSLogInput -logInput $logInput -logLevel $logLevel
        }
    }
}

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

<#Convert-OPSLogLevel
.SYNOPSIS
    Converts a string log level into a numeric log level.

.DESCRIPTION
    Converts the strings for log levels (Error, Warning, Info, Verbose and Debug) into numeric representation
    to facilitate in log level calculations to determine whether a log input should be logged.

.PARAMETER logLevel
    Level to convert. The conversions are as follows
    - Error: 3
    - Warning: 2
    - Info and Verbose: 1
    - Debug: 0
    
.NOTES
    Author: Otto Gori
    Data: 06/2017
    testVersion: 0.0
    
.INPUT EX
    Convert-OPSLogLevel Error
    Convert-OPSLogLevel -logLevel Debug
    
.OUTPUTS
    Numeric representation of the log level.
    
#>
function Convert-OPSLogLevel {
[CmdletBinding()]
param(
    [parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateSet('verbose','info','debug','warning','error')][string]$logLevel = $(throw "logLevel is mandatory and was not set.")
)
    process{
        switch ($logLevel) {
            debug{return 0}
            {(($_ -eq 'verbose') -or ($_ -eq 'info'))}{return 1}
            warning{return 2}
            error{return 3}
            Default{return 0}
        }
    }
}