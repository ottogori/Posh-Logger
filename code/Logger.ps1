. "$PSScriptRoot\Log.ps1"
. "$PSScriptRoot\StepException.ps1"

<#New-OPSLogger
.SYNOPSIS
    Create a new pair of summary and detailed log files.

.DESCRIPTION
    Creates two new log files on $logPath directory, one for detailed log and one for summary log, following the naming convention below.
    [Current date as dd-MM-yyyy] [$packageName] detailed.log
    [Current date as dd-MM-yyyy] [$packageName] summary.log
    Examples:
        11-02-2016 AllinOne_5.0.3.5_Update detailed.log
        11-02-2016 AllinOne_5.0.3.5_Update summary.log
    
    If any of the log files already exists, it will rename the existing file with a number version at the end
    unless explicitly requesting to replace any existing file with the alwaysReplace parameter.

.PARAMETER logPath
    Path to where the log file will be created
    
.PARAMETER packageName
    Name of the package to use as part of the file name to identify which package processing created the log file
    
.PARAMETER alwaysReplace
    This is a switch parameter. If set, will always replace log file if one exists with the same name.
    
.PARAMETER alwaysReplace
    This is a switch parameter. If set, The logger object stored in $global:logger will be returned.
    
.NOTES
    Author: Otto Gori
    Data: 07/2016
    testVersion: 0.0
    Application user must have permition to create and rename files on the directory specified by $logPath parameter
    Should be run on systems with PS >= 3.0

.INPUT EX
    New-OPSLogger -logPath "C:\logs" -packageName "AllinOne_5.0.3.5_Update"
    New-OPSLogger -logPath "C:\logs" -packageName "AllinOne_5.0.3.5_Update" -alwaysReplace
    
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
    [ValidateNotNullOrEmpty()][string]$packageName = $(throw "packageName is mandatory and was not set."),
    [switch]$alwaysReplace,
    [switch]$passthru
)
    $summaryLogFile = New-OPSLogFile -logPath $logPath -packageName $packageName -logType summarized -alwaysReplace:$alwaysReplace
    $detailedLogFile = New-OPSLogFile -logPath $logPath -packageName $packageName -logType detailed -alwaysReplace:$alwaysReplace
    
    $global:logger = @{
        LogPath = $logPath
        SummaryLogFile = $summaryLogFile
        DetailedLogFile = $detailedLogFile
    }
    
    if ($passthru) {
        Write-Output $global:logger
    }
}

<#Add-OPSLoggerInput
.SYNOPSIS
    Adds a log input to log files.

.DESCRIPTION
    This function formats the input adding the current date, log level and caller's function name to the input,
    adds it to the log files and optionaly writes the input to a stream according to the log level.
    
    It can add the input only to the detailed log file, only to the summary log file or to both detailed and log file
    and can also add different inputs to the summary and detailed log files.
    
    The parameter $logInput is used as the input of both detailed and summary log, with the switch parameter $summary
    indicating if the input should be added to the summary log.
    Or the parameters detailedInput and summaryInput can be used to add different inputs to each log or only one of them.

.PARAMETER logInput
    Input to write to the log files. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input.
    Used in conjunction with $summary, indicates if the logInput will be written only to the detailed log or to both logs.
    
.PARAMETER logger
    Dictionary returned from New-OPSLogger containing the Full path to both detailed and summarized log files.
    
    This parameter is optional. If ommited, uses the $global:logger set by the last call to New-OPSLogger
    
.PARAMETER summaryInput
    Input to write to the summary log. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input. If $logInput is set and the switch parameter $summary is also set
    this parameter will be replaced with the $logInput parameter value as the input to write to the summary log.
    
.PARAMETER detailedInput
    Input to write to the detailed log. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input. If $logInput is set this parameter will be replaced with the
    $logInput parameter value as the input to write to the detailed log.
    
.PARAMETER format
    The logged information will be formated using this string replacing {0} with value from logInput.
    The output information (when $output parameter is set) will not be affected by this parameter as it passes through the input as is.
    
    This parameter is optional. If ommited, the string "{0}" will be used resulting in the logInput being logged as is.
    
.PARAMETER summaryFormat
    The logged information for the summary log will be formated using this string replacing {0} with value from logInput.
    The information is only formated if logInput is used. If summaryInput is used, the logged information will be summaryInput as is.
    This is done because summaryInput does not come from pipe and will always be a single line of string.
    So it can easily be formated prior to calling this function, which is not the case when piping the input to logInput and passing through the output without any modification.
    The output information (when $output parameter is set) will not be affected by this parameter as it passes through the input as is.
    
    This parameter is optional. If ommited, the string "{0}" will be used resulting in the logInput being logged as is.
    
.PARAMETER detailedFormat
    The logged information for the detailed log will be formated using this string replacing {0} with value from logInput.
    The information is only formated if logInput is used. If detailedInput is used, the logged information will be detailedInput as is.
    This is done because detailedInput does not come from pipe and will always be a single line of string.
    So it can easily be formated prior to calling this function, which is not the case when piping the input to logInput and passing through the output without any modification.
    The output information (when $output parameter is set) will not be affected by this parameter as it passes through the input as is.
    
    This parameter is optional. If ommited, the string "{0}" will be used resulting in the logInput being logged as is.
    
.PARAMETER logLevel
    Level of the log input. This parameter is also used to determine which stream to write to.
    - Info and Verbose writes to the Verbose stream.
    - Debug writes to the Debug stream
    - Warning writes to the Warning stream
    - Error writes to the Error stream
    
    This is an optional parameter. If not set, only the current date will be added to the input.
    
.PARAMETER invocation
    The invocation variable of the function that has the name to be put on the log input.
    The name of the function will be put only on the detailed log.
    
    This is an optional parameter.
    
.PARAMETER summary
    This is a switch parameter. It is used to indicate if the logInput parameter will be written only to the detailed log
    or to both detailed and summary log.
    
.PARAMETER passthru
    This is a switch parameter. It is used to passthru the input when piping.
    This allows adding the Add-OPSLoggerInput call in the middle of a piped instruction to log what information is being piped.
    
.PARAMETER silent
    This is a switch parameter. If set, nothing will be written to any stream.
    If ommited the input (without formating) will be sent to a stream.
    
.NOTES
    Author: Otto Gori
    Data: 07/2016
    testVersion: 0.1
    Application user must have write permition to the log file
    Should be run on systems with PS >= 3.0
    
.INPUT EX
    Add-OPSLoggerInput -logInput "Initiating foobar" -logLevel Info -silent -invocation $MyInvocation
    Add-OPSLoggerInput -logger $logger -logInput "Error on foobar" -logLevel Error -summary -invocation $MyInvocation
    Add-OPSLoggerInput -logger $logger -detailedInput "Done processing foobar with warnings" -summaryInput "Done processing foobar" -logLevel Warning
    
.OUTPUTS
    Null
    
#>
function Add-OPSLoggerInput{
[CmdletBinding()]
param(
    [parameter(Position = 0, ValueFromPipeline = $true)]$logInput,
    $logger = $global:logger,
    [string]$summaryInput,
    [string]$detailedInput,
    [string]$format,
    [string]$summaryFormat = "{0}",
    [string]$detailedFormat = "{0}",
    [string]$logLevel = "Info",
    $invocation,
    [switch]$summary,
    [switch]$passthru,
    [switch]$silent
)
    process {
        if ($format) {
            $detailedFormat = $format
            if ($summary) {
                $summaryFormat = $format
            }
        }
        
        if ($logInput) {
            $detailedInput = "$detailedFormat" -f "$logInput"
            if ($summary) {
                $summaryInput = "$summaryFormat" -f "$logInput"
            }
        }
        
        if ($logger) {
            if ($detailedInput -and $logger.DetailedLogFile) {
                $detailedFileName = $logger.DetailedLogFile
                Add-OPSLogInput -logFileName $detailedFileName -logInput $detailedInput -logLevel $logLevel -invocation $invocation -silent
            }
            
            if ($summaryInput -and $logger.SummaryLogFile) {
                $summaryFileName = $logger.SummaryLogFile
                Add-OPSLogInput -logFileName $summaryFileName -logInput $summaryInput -logLevel $logLevel -silent
            }
        }
        
        if (-not $silent) {
            if ($detailedInput) {
                Write-OPSLogInput -logInput $detailedInput -logLevel $logLevel
            }
            elseif ($summaryInput) {
                Write-OPSLogInput -logInput $summaryInput -logLevel $logLevel
            }
        }
        
        if ($passthru) {
            Write-Output $logInput
        }
    }
}

<#Add-OPSLoggerException
.SYNOPSIS
    Adds a error log input to log files and creates an object for exceptions.

.DESCRIPTION
    This function calls Add-OPSLoggerInput with log level as error, but without stoping execution.
    
    It also creates an object with details of the error that can be used by throwing it and catching on caller's function
    
    This function does not accept piping like Add-OPSLoggerInput, so it doesn't have the format parameters.
    And it always sets log level to Error, so it neither has the logLevel parameter.
    
    Besides these things, the behaviour is the same as Add-OPSLoggerInput

.PARAMETER logInput
    Input to write to the log files. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input.
    Used in conjunction with $summary, indicates if the logInput will be written only to the detailed log or to both logs.
    
.PARAMETER logger
    Dictionary returned from New-OPSLogger containing the Full path to both detailed and summarized log files.
    
    This parameter is optional. If ommited, uses the $global:logger set by the last call to New-OPSLogger
    
.PARAMETER step
    Step that was being executed when the error happened. This value is added to the object returned and if thrown,
    can be retrived in the catch block with $_.TargetObject.step.
    
.PARAMETER summaryInput
    Input to write to the summary log. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input. If $logInput is set and the switch parameter $summary is also set
    this parameter will be replaced with the $logInput parameter value as the input to write to the summary log.
    
.PARAMETER detailedInput
    Input to write to the detailed log. This input will be formated using the Format-OPSLogInput function which adds
    the current date and log level to the input. If $logInput is set this parameter will be replaced with the
    $logInput parameter value as the input to write to the detailed log.
    
.PARAMETER exceptionMessage
    Message to add to the object returned and if thrown can be retrived in the catch block with $_.TargetObject.message
    
    This parameter is optional. If ommited, one of the input parameters will be used following the order of which one has value
    in the order logInput, detailedInput and summaryInput
    
.PARAMETER invocation
    The invocation variable of the function that has the name to be put on the log input and on the object returned.
    The name of the function will be put only on the detailed log.
    
    This is an optional parameter.
    
.PARAMETER summary
    This is a switch parameter. It is used to indicate if the logInput parameter will be written only to the detailed log
    or to both detailed and summary log.
    
.PARAMETER silent
    This is a switch parameter. If set, nothing will be written to the error stream.
    If ommited the input will be sent to the error stream.
    
.NOTES
    Author: Otto Gori
    Data: 07/2016
    testVersion: 0.0
    Application user must have write permition to the log file
    Should be run on systems with PS >= 3.0
    
.INPUT EX
    Add-OPSLoggerException "Error on foobar" -step "foobar" -invocation $MyInvocation
    
.OUTPUTS
    Ditionary containing the keys step, message and invocation
    
#>
function Add-OPSLoggerException{
[CmdletBinding()]
param(
    [parameter(Position = 0)]$logInput,
    $logger = $global:logger,
    [ValidateNotNullOrEmpty()][string]$step = $(throw "step is mandatory and was not set."),
    [string]$summaryInput,
    [string]$detailedInput,
    [string]$exceptionMessage,
    $invocation,
    [switch]$summary,
    [switch]$silent
)
    if ($logInput) {
        $detailedInput = $logInput
        if ($summary) {
            $summaryInput = $logInput
        }
    }
    
    if (-not $exceptionMessage) {
        if ($detailedInput) {
            $exceptionMessage = $detailedInput
        } else {
            $exceptionMessage = $summaryInput
        }
    }
    
    Add-OPSLoggerInput -logger $logger -summaryInput $summaryInput -detailedInput $detailedInput `
                       -logLevel Error -invocation $invocation -summary:$summary -silent:$silent -ErrorAction "Continue"
    
    return New-OPSStepException -step $step -message $exceptionMessage -invocation $invocation
}
