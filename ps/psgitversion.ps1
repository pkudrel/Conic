<#
.Synopsis
	Major: Breaking changes.
	Minor: New features, but backwards compatible.
	Patch: Backwards compatible bug fixes only.
#>

# Import magic
. (Join-Path $PSScriptRoot "magicnumber.ps1")

function Get-GitVersion() {
		param(
				[parameter(Mandatory=$true)] [ValidateSet('standard','fromBuildCounterMMP','combinateMajorAndBuildSlice3', 'standardOrCombinateMajorAndBuildSlice3')] [string] $strategy = "standard",
				[parameter(Mandatory=$false)] [int] $major = 0,
				[parameter(Mandatory=$false)] [int] $minor = 0,
				[parameter(Mandatory=$false)] [int] $patch = 0,
				[parameter(Mandatory=$false)] [int] $buildCounter = 0,
				[parameter(Mandatory=$false)] [string] $special = "",
				[parameter(Mandatory=$false)] [string] $buildEnv = "",
				[parameter(Mandatory=$false)] [string] $gitBranch = "",
				[parameter(Mandatory=$false)] [int] $private = 0
			)
 	
	#Write-Host "Arguments: major: $major; minor: $minor; patch: $patch; buildCounter: $buildCounter; strategy: $strategy  "

	# set build ENV if needed
	$buildEnv = if ($buildEnv -eq "") { [Environment]::MachineName } else {  $buildEnv  }
	
	# build Counter < 0			
	$buildCounter = if ($buildCounter -le 0) { Get-LocalBuildNumber } else { $buildCounter }


	# magic MagicMajorMinorPatchPrivate form build number		
	$magicVersion =   (Get-MagicNumber $major $minor $patch $private $buildCounter $strategy)	
	$magic = $magicVersion.MagicVersionExtend
	$magicSimple = $magicVersion.MagicVersion
	
	$major = $magic.Major;
	$minor = $magic.Minor;
	$patch = $magic.Patch;
	$private = $magic.Private;



	#hash and time				
	$sha = Get-GitCommitHash
	$dateTime = Get-GitCommitTimestamp

	#number of commit
	$commitNumber = [int](Get-GitCommitNumber)
	$commitNumberPad = "{0:D4}" -f $commitNumber
	
	#branch 
	$gitBranch = if ($gitBranch -ne "") { $gitBranch } else {  Get-GitBranch  }
	$gitBranch = if ($gitBranch -ne "") { $gitBranch } else {  $buildEnv  }

	#label 
	$label = if ($special -ne "") { $special } else { $gitBranch }
	$preReleaseTag = "$label.$commitNumber" 
	
	#tag
	$tag = Get-GitTag
	$tag  = if ($tag -ne "") { $tag } else {  ""  }

	#MajorMinorPatch
	$majorMinorPatch = "$major.$minor.$patch";

	#SemVer 
	$semVer = "$majorMinorPatch"
	$semVer  = if ($special -ne "") { "$semVer-$special" } else {  "$semVer"  }
	$semVerExtend  = if ($special -ne "") { "$majorMinorPatch-$special+$buildCounter" } else {  "$majorMinorPatch+$buildCounter"  }
	
	#NuGetVersion
	$nugetSpacialExt = [string]$special.Replace(".","").Replace("-","")
	$NuGetVersion =   if ($nugetSpacialExt -ne "") { "$majorMinorPatch-$nugetSpacialExt" } else {  $majorMinorPatch  }
	$NuGetVersionExtend = if ($nugetSpacialExt -eq "") { "$majorMinorPatch-build$buildCounter" } else {  $NuGetVersion  } 

	#InformationalVersion 
	$fullBuildMetaData = "BuildCounter.$buildCounter.Branch.$gitBranch.DateTime.$dateTime.Env.$buildEnv.Sha.$sha.CommitsCounter.$commitNumber"
	$informationalVersion = "$semVer+$fullBuildMetaData";


	 $result = [PSCustomObject]  @{
	"Major"= $major; "Minor"= $minor; "Patch" = $patch; "BuildCounter" = $buildCounter; "Special" = $special; "Env" = $buildEnv; "Private" = $private;
	"AssemblyVersion" = "$major.$minor.0.0"; "AssemblyFileVersion" = "$major.$minor.$buildCounter.0"; "AssemblyInformationalVersion" = $informationalVersion;
	"SemVer" = "$semVer" ; "SemVerExtend" = $semVerExtend; "SemVerAssembly" = "$major.$minor.$patch.0"; 
	"MajorMinorPatch" = "$major.$minor.$patch";"MajorMinorPatchPrivate" = "$major.$minor.$patch.$private"; "MajorMinorBuild" =   "$major.$minor.$buildCounter";
	"BranchName" = $gitBranch; "Tag" = $tag; 
	"Label" = $label ; 
	"FullBuildMetaData" = "$fullBuildMetaData";

	"PreReleaseTag" = $preReleaseTag ; 
	"NuGetVersion" = "$NuGetVersion"	; "NuGetVersionExtend" = "$NuGetVersionExtend"	;
	"CommitsCounter" = $commitNumber ; "CommitsCounterPad" = $commitNumberPad;  "CommitsDateTime" = "$dateTime";
	"Sha" = "$sha" ; 
	"BuildMagicNumber" = "$($magic.Major).$($magic.Minor).$($magic.Patch).$($magic.Private)";
	"BuildMagicShortNumber" = "$($magicSimple.Major).$($magicSimple.Minor).$($magicSimple.Patch)"
	}
	return $result
}



#Borrowed from psake
function Exec {
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
function Assert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]$ConditionToCheck,
        [Parameter(Mandatory=$true, Position=1)]$FailureMessage
    )
    if (!$ConditionToCheck) {
        throw ("Assert: " + $FailureMessage)
    }
}
function Ensure-DirExists ($path){

	if((Test-Path $path) -eq 0)
	{
			mkdir $path | out-null;
    }
}

<#
.Synopsis
	Get total number commits of commits in current bruch
#>
function Get-GitCommitNumber
{
    $commitNumber = Exec { git rev-list --all --count } "Cannot execute git log. Ensure that the current directory is a git repository and that git is available on PATH."
    return $commitNumber 
}

<#
.Synopsis
	Get work dir psgitversion
#>
function Get-PsGitVersionWorkDirPath
{
	$repoRootPath =	Get-GitRepoRoot
	$gitDirPath = Join-Path $repoRootPath ".git"
	if((Test-Path $gitDirPath) -eq 0){ throw ("Git dir not found")} 
	$GitVersionDirPath = Join-Path $gitDirPath "psgitversion"
	Ensure-DirExists $GitVersionDirPath
	return $GitVersionDirPath
}

<#
.Synopsis
	Use local build counter
#>

function Get-LocalBuildNumber {

	$GitVersionDirPath = Get-PsGitVersionWorkDirPath
	$counterFilePath = Join-Path $GitVersionDirPath "local-counter.txt"
	
	$defauleValue = 1;
	$result = $defauleValue;
	if (Test-Path $counterFilePath) 
	{
		$firstline = Get-Content $counterFilePath -totalcount 1
		[int]$b = $null #used after as refence
		if(([int32]::TryParse($firstline, [ref]$b )) -eq  $true)
		{
			$next = $b + 1;
			$result = $next	
		}
	}
	$result | Out-File $counterFilePath
	return $result
}

<#
.Synopsis
	Get current repository root
#>
function Get-GitRepoRoot
{
	 $path = Exec { git rev-parse --show-toplevel } "Problem with git"
	 return $path 
}






<#
.Synopsis
	Get commit Timestamp from current branch
#>
function Get-GitCommitTimestamp
{
	$lastCommitLog = Exec { git log --max-count=1 --pretty=format:%cI HEAD } "Problem with git"
	$convertedDate = [DateTime]::Parse($lastCommitLog).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ");
    return $convertedDate
}

<#
.Synopsis
	Get commit sha from current branch
#>
function Get-GitCommitHash
{
    $lastCommitLog = Exec { git log --max-count=1 --pretty=format:%H HEAD } "Problem with git"
    return $lastCommitLog
}

<#
.Synopsis
	Get current branch name
#>
function Get-GitBranch
{
	 $revParse = Exec { git rev-parse --abbrev-ref HEAD } "Problem with git"
	 if ($revParse -ne "HEAD") { return $revParse } 
	 $revParse = Exec { git symbolic-ref --short -q HEAD } "Problem with git"
	 if ($revParse -ne "HEAD") { return $revParse } 
	 return "" 
}

<#
.Synopsis
	Get commit tag from current branch
#>
function Get-GitTag
{
	$describeTags = ""
	try {
		$describeTags = Exec { git for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)' --count=1 } "Problem with git"
	}	
	catch {
	 
	}
    return $describeTags
}
