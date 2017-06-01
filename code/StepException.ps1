function New-OPSStepException{
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()][string]$step = $(throw "step is mandatory and was not set."),
    [ValidateNotNullOrEmpty()][string]$message = $(throw "message is mandatory and was not set."),
    $invocation = $(throw "invocation is mandatory and was not set.")
)
    return @{
        step = $step
        message = $message
        invocation = $invocation
    }
}
