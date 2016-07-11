#Borrowed from psake
Function Exec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][scriptblock]$Command,
        [Parameter(Mandatory=$false, Position=1)][string]$ErrorMessage = ("Failed executing {0}" -F $Command)
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw ("Exec: " + $ErrorMessage)
    }
}

# Borrowed from psake
Function Assert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]$ConditionToCheck,
        [Parameter(Mandatory=$true, Position=1)]$FailureMessage
    )
    if (!$ConditionToCheck) {
        throw ("Assert: " + $FailureMessage)
    }
}

Function Create-Dir ($path){

	if((Test-Path $path) -eq 0)
	{
			mkdir $final_local | out-null;
    }
}
Function Ensure-DirExistsAndIsEmpty ($path){

	if((Test-Path $path) -eq 0)
	{
			mkdir $path | out-null;
    } 
	else 
	{
		rd $path -rec -force | out-null
		mkdir $path | out-null;
	}
}
Function Patch-AssemblyInfo {
    Param(
        [Parameter(Mandatory=$true)][string]$assemblyInfoFilePath,
        [Parameter(Mandatory=$true)][string]$assemblyVersion,
        [Parameter(Mandatory=$true)][string]$assemblyFileVersion,
        [Parameter(Mandatory=$true)][string]$assemblyInformationalVersion,
        [Parameter(Mandatory=$true)][string]$productName,
        [Parameter(Mandatory=$true)][string]$copyright,
        [Parameter(Mandatory=$true)][string]$companyName
    )
    Process {
        $newAssemblyVersion = 'AssemblyVersion("' + $assemblyVersion + '")'
        $newAssemblyFileVersion = 'AssemblyFileVersion("' + $assemblyFileVersion + '")'
        $newAssemblyVersionInformational = 'AssemblyInformationalVersion("' + $assemblyInformationalVersion + '")'
        $newAssemblyProductName = 'AssemblyProduct("' + $productName + '")'
        $newAssemblyCopyright = 'AssemblyCopyright("'+ $copyright + '")'
        $newAssemblyCompany = 'AssemblyCompany("' + $companyName + '")'

        $assemblyVersionPattern = 'AssemblyVersion\(".*"\)'
        $assemblyFileVersionPattern = 'AssemblyFileVersion\(".*"\)'
        $assemblyVersionInformationalPattern = 'AssemblyInformationalVersion\(".*"\)'
        $assemblyProductNamePattern = 'AssemblyProduct\(".*"\)'
        $assemblyCopyrightPattern = 'AssemblyCopyright\(".*"\)'
        $assemblyCompanyPattern = 'AssemblyCompany\(".*"\)'

        $edited = (Get-Content $assemblyInfoFilePath) | ForEach-Object {
            % {$_ -replace "\/\*+.*\*+\/", "" } |
            % {$_ -replace "\/\/+.*$", "" } |
            % {$_ -replace "\/\*+.*$", "" } |
            % {$_ -replace "^.*\*+\/\b*$", "" } |
            % {$_ -replace $assemblyVersionPattern, $newAssemblyVersion } |
            % {$_ -replace $assemblyFileVersionPattern, $newAssemblyFileVersion } |
            % {$_ -replace $assemblyVersionInformationalPattern, $newAssemblyVersionInformational } |
            % {$_ -replace $assemblyProductNamePattern, $newAssemblyProductName } |
            % {$_ -replace $assemblyCopyrightPattern, $newAssemblyCopyright } |
            % {$_ -replace $assemblyCompanyPattern, $newAssemblyCompany }
        }

        if (!(($edited -match $assemblyVersionInformationalPattern) -ne "")) {
            $edited += "[assembly: $newAssemblyVersionInformational]"
        }
		Write-Host "Path to file: $assemblyInfoFilePath"
		[System.IO.File]::WriteAllLines($assemblyInfoFilePath, $edited, [text.encoding]::UTF8)

    }
}
function Restore-AssemblyInfo {
 Param(
		[Parameter(Mandatory=$true)]
        [string]$directory,
        [Parameter(Mandatory=$true)]
        [string]$current,
		[Parameter(Mandatory=$true)]
        [string]$old
    )

	$pattern = "$directory\**\$old"
	$items = Get-ChildItem $pattern -Recurse | % FullName
	foreach ($item in $items) {
		Write-Host $item	
		$dir = Split-Path  $item -parent
		Move-Item -path $item -destination "$dir\$current" -Force
	}


}
function Update-AssemblyInfo {
 Param(
		[Parameter(Mandatory=$true)][string]$directory,
        [Parameter(Mandatory=$true)][string]$currentAssemblyInfo,

        [Parameter(Mandatory=$true)][string]$assemblyVersion,
        [Parameter(Mandatory=$true)][string]$assemblyFileVersion,
        [Parameter(Mandatory=$true)][string]$assemblyInformationalVersion,
        
		[Parameter(Mandatory=$true)][string]$productName,
        [Parameter(Mandatory=$true)][string]$copyright,
        [Parameter(Mandatory=$true)][string]$companyName
    )

	$pattern = "$directory\**\$currentAssemblyInfo"
	$items = Get-ChildItem $pattern -Recurse | % FullName
	foreach ($item in $items) {
		
		$dir = Split-Path  $item -parent
		Copy-Item -Path $item -Destination "$dir\$oldAssemblyInfo"
		Patch-AssemblyInfo $item  $assemblyVersion $assemblyFileVersion $assemblyInformationalVersion $productName $copyright $companyName
	}


}
