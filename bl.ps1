#requires -Version 3.0
<#
.Synopsis
	Build luncher for (https://github.com/nightroman/Invoke-Build)
#>


[CmdletBinding()]
param(
		[Parameter(Mandatory=$false)]
		$repoPath = (Resolve-Path ( & git rev-parse --show-toplevel)),
		$scriptsPath = ($PSScriptRoot),
		$buildPath = (Join-Path $repoPath "\build-out" ),
		$toolsPath = (Join-Path $repoPath "\tools" ),
		$configPath = (Join-Path $repoPath "\.config\build.json" ),
		$buildScriptsPath = (Join-Path $scriptsPath  "default.ps1" ),
		$buildTarget = "Release",
		$buildEnv = "local",
		$buildNumber = 0,
		$buildMiscInfo = "",
		$buildDateTime = ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")),
		$gitCommitNumber = 0,
		$gitBranch = "",
		$ib = (Join-Path $scriptsPath "\tools\ib\Invoke-Build.ps1")
    )


$ValueNamesToExport =@("repoPath", "configPath", "scriptsPath",
 "toolsPath", "buildEnv", "buildTarget",  "buildPath","buildNumber", "gitCommitNumber",
 "buildDateTime" , "gitBranch", "buildMiscInfo")

 # tools
. (Join-Path $scriptsPath "ps\misc.ps1")
. (Join-Path $scriptsPath "ps\psgitversion.ps1")

# make 
$config = Get-Content $configPath | Out-String | ConvertFrom-Json
$v = ([PSCustomObject]$config.SemVer)
$bv = Get-GitVersion  $v.major $v.minor $v.patch $buildNumber $v.special  $buildEnv
$global:psgitversion = $bv 


$buildNumber = $bv.Build
$gitCommitNumber = $bv.CommitsCounter
$gitBranch = $bv.BranchName
$buildMiscInfo = $bv.AssemblyInformationalVersion



# Export to Invoke-Build
$ParameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters;
# http://www.powershelladmin.com/wiki/PowerShell_foreach_loops_and_ForEach-Object
$parms = $ParameterList.keys |  %  {Get-Variable -Name $_ -ErrorAction SilentlyContinue | ?{$_} } 
$parmsToExport = $parms.GetEnumerator() `
					| Where-Object { $_.Name -in $ValueNamesToExport}  `
					| %  { $hash=@{} } { $hash.Add($_.Name,$_.Value) } { $hash }

Write-Output "Bulid luncher parms:"
$parmsToExport.GetEnumerator()| Sort-Object -Property name | Format-Table Name, Value -AutoSize

try {
        # Invoke the build and keep results in the variable Result
        & $ib -File $buildScriptsPath -Parameters $parmsToExport -Result Result 
    }
catch {
 Write $Result.Error
 exit 1 # Failure
}


$Result.Tasks | Format-Table Elapsed, Name -AutoSize
exit 0