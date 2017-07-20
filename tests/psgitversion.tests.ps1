$scriptPath = ($PSScriptRoot)
$psgitversionScript =  Join-Path ((get-item $scriptPath ).parent.FullName) ("ps\psgitversion.ps1")
$miscScript =  Join-Path ((get-item $scriptPath ).parent.FullName) ("ps\misc.ps1")

# tools
. $psgitversionScript
. $miscScript

$v = Get-GitVersion "fromBuildCounterMMP"  0 0 0 1234 $v.special  $buildEnv

Assert ($v.BuildMagicShortNumber -eq "12.3.4") {"Invalid BuildMagicShortNumber. Should be '12.3.4'"}
Assert ($v.MajorMinorPatch -eq "12.3.4") {"Invalid MajorMinorPatch. Should be '12.3.4'"}
Assert ($v.NuGetVersion -eq "12.3.4") {"Invalid NuGetVersion. Should be '12.3.4'"}

$v = Get-GitVersion "standard"  1 2 3 999 $v.special  $buildEnv 4


