#Variable to hold variable  
param(
    [Parameter(Mandatory=$true)]    
    [string]$SQLServer,
    [Parameter(Mandatory=$true)]    
    [string]$SQLDBName
)

$ErrorActionPreference = "Stop"

$ScriptFolderList = New-Object Collections.Generic.List[String]
$mypath = Split-Path $MyInvocation.MyCommand.Path
$executionLogFile = ".\Execution_log.log"
$configFile = "config.json"
$configPath = Join-Path $mypath $configFile

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# $SQLServer = "CODEPLACER\SQLEXPRESS"
# $SQLDBName = "My_Database"


#Main
function Main() {
    Clear-LogFile
    Read-Script-Folder
    Start-Execution
}

#Clear Log File
function Clear-LogFile() {
    Add-Process-Start-Log-Entry "Clearing Log file"
    Remove-Item $executionLogFile -ErrorAction Ignore
    Add-Process-End-Log-Entry
}

#Read Script folders from config
function Read-Script-Folder() {
    Add-Process-Start-Log-Entry "Reading Script Folders from config"
    foreach ($folder in  $config.ScriptFolder) {
        $resolvedFolder = Join-Path $mypath $folder
        $ScriptFolderList.Add($resolvedFolder)
    }
    Add-Process-End-Log-Entry
}

#Start SQL Script Execution
function Start-Execution() {
    Write-Host "Starting Custom Script Execution"
    foreach ($folder in $ScriptFolderList) {
        Invoke-Execute-SQL-Script -scriptFolder $folder
    }
}

# Execute SQL files in a folder
function Invoke-Execute-SQL-Script($scriptFolder) {
    Get-ChildItem -Path $scriptFolder -Filter *.sql | ForEach-Object {
        $scriptFileName = $_.FullName
        try {
            Add-Process-Start-Log-Entry "Executing $_ from $scriptFolder"
            Invoke-Execute-SqlCommand $scriptFileName
            Add-Process-End-Log-Entry
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            throw $ErrorMessage
        }
        
    }   
}

# Execute SQL Query
function Invoke-Execute-SqlCommand($scriptFileName) {
    Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDBName -InputFile $scriptFileName -QueryTimeout 0
}

# Add log entry
function Add-Process-Start-Log-Entry($message) {
    Write-Host "$message..." -NoNewline 
    $dateTime = Get-Date
    Add-Content -Path $executionLogFile -Value  "$dateTime : $message"   -NoNewline
}

function Add-Process-End-Log-Entry($message = "") {
    if ($message -eq "") { 
        $message = "Pass" 
    }    
    Write-Host " - $message" -ForegroundColor Green
    Add-Content -Path $executionLogFile -Value  " - $message"   
}


try {
    Main
    Write-Host "Execution Completed" -ForegroundColor Green
}
catch {
    Write-Host " - Fail" -ForegroundColor Red
    $ErrorMessage = $_.Exception.Message
    if ([String]$ErrorMessage.Trim() -ne "".Trim()) {
        Add-Content -Path $executionLogFile -Value " - Fail"
        Add-Content -Path $executionLogFile -Value "Message: $ErrorMessage"
    }
    throw $ErrorMessage
}

