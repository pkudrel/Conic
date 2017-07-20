
function UpdateAssemblyInfo {
    Param(
        [Parameter(Mandatory=$true)][string]$workDir,

        [Parameter(Mandatory=$true)][string]$assemblyVersion,
        [Parameter(Mandatory=$true)][string]$assemblyFileVersion,
        [Parameter(Mandatory=$true)][string]$assemblyInformationalVersion,
        
        [Parameter(Mandatory=$true)][string]$productName,
        [Parameter(Mandatory=$true)][string]$copyright,
        [Parameter(Mandatory=$true)][string]$companyName
    )
    $directory = Resolve-Path $workDir
    $pattern = "$directory\**\AssemblyInfo.cs"
    $items = Get-ChildItem $pattern -Recurse | ForEach-Object FullName
    foreach ($item in $items) {
        $dir = Split-Path  $item -parent
        $f2 = "$item.temporary-beckup-file"
        Copy-Item -Path $item -Destination $f2
        PatchAssemblyInfo $item $assemblyVersion $assemblyFileVersion $assemblyInformationalVersion $productName $copyright $companyName
    }


}

function PatchAssemblyInfo {
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