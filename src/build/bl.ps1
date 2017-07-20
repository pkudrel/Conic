#requires -Version 3.0
<#
.Synopsis
	Build luncher for (https://github.com/nightroman/Invoke-Build)
#>


[CmdletBinding()]
param(
		[Parameter(Mandatory=$false)]
		$repoPath = (Resolve-Path ( & git rev-parse --show-toplevel)),
		$scriptsPath = (Split-Path $MyInvocation.MyCommand.Path -Parent) ,
		$buildPath = (Join-Path $repoPath "\build-out" ),
		$toolsPath = (Join-Path $repoPath "\tools" ),
		$configPath = (Join-Path $repoPath "\.config\build.json" ),
		$config = (Get-Content $configPath | Out-String | ConvertFrom-Json),
		$psGitVersionConfig = ([PSCustomObject]$config.PsGitVersion),
		$buildVersion,
		$buildScriptsPath = (Join-Path $scriptsPath  "default.ps1" ),
		$buildTarget = "Release",
		$buildEnv = "local",
		$buildMiscInfo = "",
		$buildCounter = 0,
		$buildMajor = $( if ($psGitVersionConfig.Major -ne $null) { $psGitVersionConfig.Major } else {0} ),
		$buildMinor = $( if ($psGitVersionConfig.Minor -ne $null) { $psGitVersionConfig.Minor } else {0} ),
		$buildPatch =  $( if ($psGitVersionConfig.Patch -ne $null) { $psGitVersionConfig.Patch } else {0} ),
		$buildSpecial = $( if ($psGitVersionConfig.Special -ne $null) { $psGitVersionConfig.Special } else {""} ),
		$psGitVersionStrategy = $( if ($psGitVersionConfig.Strategy -ne $null) { $psGitVersionConfig.Strategy } else {"standard"} ),
		$buildDateTime = ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")),
		$gitCommitNumber = 0,
		$gitBranch = "",
		$helpersPath = $(If (Test-Path (Join-Path $scriptsPath "vendor\ps-auto-helpers\")) { (Join-Path $scriptsPath "vendor\ps-auto-helpers\") } else { $scriptsPath } ),
		$ib = (Join-Path $helpersPath "\tools\ib\Invoke-Build.ps1")
    )

$ValueNamesToExport =@("repoPath", "configPath", "scriptsPath",
 "toolsPath", "buildEnv", "buildTarget",  "buildPath","buildNumber", "gitCommitNumber",
 "buildDateTime" , "gitBranch", "buildMiscInfo", "buildVersion")

 # tools
. (Join-Path $helpersPath "ps\misc.ps1")
. (Join-Path $helpersPath "ps\psgitversion.ps1")


# make 

$buildVersion = Get-GitVersion $psGitVersionStrategy $buildMajor $buildMinor $buildPatch $buildCounter $buildSpecial $buildEnv $gitBranch

$buildNumber = $buildVersion.BuildCounter
$gitCommitNumber = $buildVersion.CommitsCounter
$gitBranch = $buildVersion.BranchName
$buildMiscInfo = $buildVersion.AssemblyInformationalVersion



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
		& $ib @parmsToExport -File $buildScriptsPath  -Result Result 
    }
catch {
 Write $Result.Error
 Write $_
 exit 1 # Failure
}


$Result.Tasks | Format-Table Elapsed, Name -AutoSize
exit 0