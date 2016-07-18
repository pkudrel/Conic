<#
.Synopsis
	Major: Breaking changes.
	Minor: New features, but backwards compatible.
	Patch: Backwards compatible bug fixes only.
#>
function Get-GitVersion() {
		param(
				[parameter(Mandatory=$false)] [int] $major = 0,
				[parameter(Mandatory=$false)] [int] $minor = 0,
				[parameter(Mandatory=$false)] [int] $patch = 0,
				[parameter(Mandatory=$false)] [int] $build = 0,
				[parameter(Mandatory=$false)] [string] $special = "",
				[parameter(Mandatory=$false)] [string] $env = ([Environment]::MachineName),
				[parameter(Mandatory=$false)] [int] $private = 0
			)


	# build number < 0			
	$build = if ($build -le 0) { Get-LocalBuildNumber } else { $build }


	# magic MagicMajorMinorPatchPrivate form build number			
	$magic = Get-MagicMajorMinorPatchPrivate $build

	# if all important items are equal zero use magic
	if ( ($major -eq 0) -and ($minor -eq 0) -and ($patch -eq 0) -and ($private -eq 0) ){
		$major = $magic.Major;
		$minor = $magic.Minor;
		$patch = $magic.Patch;
		$private = $magic.Private;
	}


	#hash and time				
	$sha = Get-GitCommitHash
	$dateTime = Get-GitCommitTimestamp

	#number of commit
	$commitNumber = [int](Get-GitCommitNumber)
	$commitNumberPad = "{0:D4}" -f $commitNumber
	
	#branch 
	$branch = Get-GitBranch
	$branch = if ($branch -ne "") { $branch } else {  $env  }

	#label 
	$label = if ($special -ne "") { $special } else { $branch }
	$preReleaseTag = "$label.$commitNumber" 
	
	#tag
	$tag = Get-GitTag
	$tag  = if ($tag -ne "") { $tag } else {  ""  }

	#MajorMinorPatch
	$majorMinorPatch = "$major.$minor.$patch";

	#SemVer 
	$semVer = "$majorMinorPatch"
	$semVer  = if ($special -ne "") { "$semVer-$special" } else {  "$semVer"  }
	$semVerExtend  = if ($special -ne "") { "$majorMinorPatch-$special+$build" } else {  "$majorMinorPatch+$build"  }
	
	#NuGetVersion
	$nugetSpacialExt = [string]$special.Replace(".","").Replace("-","")
	$NuGetVersion =   if ($nugetSpacialExt -ne "") { "$majorMinorPatch-$nugetSpacialExt" } else {  $majorMinorPatch  }
	$NuGetVersionExtend = if ($nugetSpacialExt -eq "") { "$majorMinorPatch-build$build" } else {  $NuGetVersion  } 

	#InformationalVersion 
	$fullBuildMetaData = "Build.$build.Branch.$branch.DateTime.$dateTime.Env.$env.Sha.$sha.CommitsCounter.$commitNumber"
	$informationalVersion = "$semVer+$fullBuildMetaData";


    


	 $result = [PSCustomObject]  @{
	"Major"= $major; "Minor"= $minor; "Patch" = $patch; "Build" = $build; "Special" = $special; "Env" = $env; "Private" = $private;
	"AssemblyVersion" = "$major.$minor.0.0"; "AssemblyFileVersion" = "$major.$minor.$build.0"; "AssemblyInformationalVersion" = $informationalVersion;
	"SemVer" = "$semVer" ; "SemVerExtend" = $semVerExtend; "SemVerAssembly" = "$major.$minor.$patch.0"; 
	"MajorMinorPatch" = "$major.$minor.$patch";"MajorMinorPatchPrivate" = "$major.$minor.$patch.$private"; "MajorMinorBuild" =   "$major.$minor.$build";
	"BranchName" = $branch; "Tag" = $tag; 
	"Label" = $label ; 
	"FullBuildMetaData" = "$fullBuildMetaData";

	"PreReleaseTag" = $preReleaseTag ; 
	"NuGetVersion" = "$NuGetVersion"	; "NuGetVersionExtend" = "$NuGetVersionExtend"	;
	"CommitsCounter" = $commitNumber ; "CommitsCounterPad" = $commitNumberPad;  "CommitsDateTime" = "$dateTime";
	"Sha" = "$sha" ; 
	"BuildMagicNumber" = "$($magic.Major).$($magic.Minor).$($magic.Patch).$($magic.Private)";
	
	
	
	}


	#if ($env:APPVEYOR) { $build = "$buildCommitNumber"}
	#ElseIf ($env:TEAMCITY_VERSION) {
	#	$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(8192,50)
	#	$build = "$buildCounter" 	} 
	#else {
	#	$build = Get-LocalBuildVersion  $filePath
	#	$semver.special = $semver.special + $env
	#}

	#$result.Build = $build
	#$result.Sem = ("{0}.{1}.{2}" -f $semver.major, $semver.minor, $semver.patch)	

	#if ($semver.special  -ne ""){
	#	$result.Sem = ("{0}-{1}" -f $result.Sem, $semver.special)	
	#}
	#$result.Sem = ("{0}.{1}" -f $result.Sem, $build)	 


	#if ($env:TEAMCITY_VERSION) {
	#	$s  = $result.Sem;
	#	Write-Host  "##teamcity[buildNumber '$s']"
	#}

	return $result
}



#Borrowed from psake
function Exec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][scriptblock]$Command,
        [Parameter(Mandatory=$false, Position=1)][string]$ErrorMessage = ("Failed executing {0}" -F $Command)
    )
	Write-Host "Command: $Command"
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
	Get "magic"  Major, Minor, Patch, Private number from build
#>
function Get-MagicMajorMinorPatchPrivate {
	
		param(
				[parameter(Mandatory=$true)] [int] $build
			)

			$r = [PSCustomObject]  @{"Major" = 0; "Minor" = 0; "Patch" = 0; "Private" = 0}
			$r.Major =  [math]::floor($build / 1000 )
			$rest =  ($build - ($r.Major * 1000))
			$r.Minor =  [math]::floor($rest/100)
			$rest =  ($rest - ($r.Minor * 100))
			$r.Patch =  [math]::floor($rest / 10 ) 
			$rest =  ($rest - ($r.Patch * 10))
			$r.Private =  [math]::floor( $rest / 1 ) 
			return $r
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
	 $revParse = Exec { git symbolic-ref --short -q HEAD } "Problem with git"
	 if ($revParse -ne "HEAD") { return $revParse } 
	 $revParse = Exec { git rev-parse --abbrev-ref HEAD } "Problem with git"
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
		$describeTags = Exec { git describe --tags } "Problem with git"
	}	
	catch {
	 
	}
    return $describeTags
}
