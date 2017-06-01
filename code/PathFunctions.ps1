. "$PSScriptRoot\Logger.ps1"

function Test-ValidPath([string]$PathToTest){
    
    if(Test-Path $PathToTest){
        return $PathToTest
    } else {
        Throw [System.Exception] "$PathToTest not found"
    }
}

function New-OPSDirectory {
    [CmdletBinding()]
    Param(
        [parameter(Position = 0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )][Alias('FullName')]
        [ValidateNotNullOrEmpty()][string]$path = $(throw "path is mandatory and was not set."),
        [switch]$ignoreIfExists
    )
    process {
        if (-not $ignoreIfExists -or -not (test-path $path)) {
            New-Item -path $path -ItemType Directory
            Add-OPSLoggerInput "Directory $path created" -logLevel Debug -invocation $MyInvocation
        }
        else {
            $directory = Get-Item -path $path
            if ($directory.PSIsContainer) {
                Add-OPSLoggerInput "Directory $path already existed. Returned existing directory" -logLevel Debug -invocation $MyInvocation
                return $directory
            }
            else {
                throw [System.Exception] "Could not create directory $path because a file with this name already exists"
            }
        }
    }
}

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
