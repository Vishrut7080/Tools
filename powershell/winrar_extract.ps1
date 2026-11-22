# # =================================================
# BULK ARCHIVE EXTRACTION UTILITY
# # =================================================

# -------------------------------------------------
# Loading env
# -------------------------------------------------

$envFilePath = Join-Path $PSScriptRoot "\..\env"

if (Test-Path $envFilePath) {
    Get-Content $envFilePath | ForEach-Object {
        # Ignore empty lines and comment lines starting with #
        if ($_ -match '^\s*([^#=]+)\s*=\s*(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Set as process-lelvel envirnment variable
            [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }
}
else {
    Write-Host "Configuration .env file was not found at $envFilePath"
    exit
}

# -------------------------------------------------
# Actual Task
# -------------------------------------------------

$winrar = $env:WINRAR_PATH
$targetFolder = $env:TARGET_FOLDER
# $PSScriptRoot is an automatic variable in PowerShell that contains the directory path of the currently executing script.
# $targetFolder = 'C:\'

# Test-Path checks whether a specified file or directory exists.
# -not is a logical NOT operator. It reverses a Boolean value.
# The message executes only if the path doesn't exist.
if (-not (Test-Path $winrar)) {
    # Yes, double quotes ("") in PowerShell work very much like Python's f-strings.
    # Write-Error: displays messages.
    Write-Error "WinRAR executable not found at $winrar. Please check your installation path"
    # exit: Terminates the PowerShell script or session.
    exit
}

if (-not (Test-Path $targetFolder)) {
    Write-Error "The specified target folder does not exist: $targetFolder"
    exit
}

# Get-ChildItem:	Lists files and directories
# -Path is a parameter that specifies the path to a file, directory, or another filesystem location that a cmdlet should operate on.
$archives = Get-ChildItem -Path $targetFolder -Include *.rar, *.zip, *.7z -Recurse

# To get type of $archives
# $archives.GetType()

# To print the components of archives
# -------------------------------------------------
# $archives | ForEach-Object {
#     # $_ represents the current file object.
#     Write-Host $_.FullName
# }
# -------------------------------------------------

foreach ($archive in $archives) {
    $destination = Join-Path $archive.DirectoryName $archive.BaseName
    # Inside double-quoted strings ("), PowerShell looks for $ to automatically replace variables with their values. 
    # However, how it reads them depends on complexity:
    # $($expression): This is a subexpression. It is required when you need to access a property or method of an object inside a string 
    # (e.g., "$($archive.Name)" or "$($archive.FullName)").
    Write-Host "Extracting $($archive.Name) -> $destination" -ForegroundColor Cyan
    
    # Ensure destinaion exists
    if (-not(Test-Path $destination)) {
        # In PowerShell, the hyphen (-) is used to denote a named parameter (or switch) for a command (cmdlet).
        # Why we use it: PowerShell cmdlets often accept parameters. For example, -ItemType tells 
        # New-Item what kind of object to create, and -Path tells it where to create it.
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    # Execute WinRAR command-line extraction
    # x = extract with full paths
    # -y = assume Yes on all queries (overwrite, etc.)

    # While $ is used to define or reference variables, & is the Call Operator (or invocation operator).
    # Why we use it: If you just type a string variable like $winrar in PowerShell, it treats it as plain text. 
    # To tell PowerShell "Hey, take the executable path stored inside this variable and actually run/execute it as a command," you must prefix it with &.
    & $winrar x -y "$($archive.FullName)" "$destination\"
}

Write-Host "All extractions completed successfully!" -ForegroundColor Green