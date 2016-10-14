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
		$buildScriptsPath = (Join-Path $scriptsPath  "default.ps1" ),
		$buildTarget = "Release",
		$buildEnv = "local",
		$buildMiscInfo = "",
		$buildCounter = 0,
		$buildMajor = $( if ($psGitVersionConfig.Major -ne $null) { $psGitVersionConfig.Major } else {0} ),
		$buildMinor = $( if ($psGitVersionConfig.Minor -ne $null) { $psGitVersionConfig.Minor } else {0} ),
		$buildPatch =  $( if ($psGitVersionConfig.Patch -ne $null) { $psGitVersionConfig.Patch } else {0} ),
		$buildSpecial = $( if ($psGitVersionConfig.Special -ne $null) { $psGitVersionConfig.Special } else {""} ),
		$buildDateTime = ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")),
		$gitCommitNumber = 0,
		$gitBranch = "",
		
		$psGitVersionStrategy = "standard",
		$ib = (Join-Path $scriptsPath "\tools\ib\Invoke-Build.ps1")
    )


$ValueNamesToExport =@("repoPath", "configPath", "scriptsPath",
 "toolsPath", "buildEnv", "buildTarget",  "buildPath","buildNumber", "gitCommitNumber",
 "buildDateTime" , "gitBranch", "buildMiscInfo")

 # tools
. (Join-Path $scriptsPath "ps\misc.ps1")
. (Join-Path $scriptsPath "ps\psgitversion.ps1")


# make 

$bv = Get-GitVersion $psGitVersionStrategy $buildMajor $buildMinor $buildPatch $buildCounter $v.Special $buildEnv $gitBranch
$global:psgitversion = $bv 


$buildNumber = $bv.BuildCounter
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