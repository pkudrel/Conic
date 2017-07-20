$scriptPath = ($PSScriptRoot)

$magicNumberScript =  Join-Path ((get-item $scriptPath ).parent.FullName) ("ps\magicnumber.ps1")
$miscScript =  Join-Path ((get-item $scriptPath ).parent.FullName) ("ps\misc.ps1")

# tools
. $magicNumberScript
. $miscScript

$mn = [PSCustomObject] (Get-MagicNumber 1 2 3 4 56789 "combinateMajorAndBuildSlice3")
Write-Host ($mn | Sort-Object -Property Name  | Format-List  | Out-String)