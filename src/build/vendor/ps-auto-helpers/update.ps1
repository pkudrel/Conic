#requires -Version 3.0
<#
.Synopsis
	Misc Updates
#>


[CmdletBinding()]
param(
    $scriptsPath = (Split-Path $MyInvocation.MyCommand.Path -Parent),
    $toolsPath = (Join-Path $scriptsPath "\tools\")
)

function UpdateInvokeBuild  {
    Write-Host "Update InvokeBuild"
    $ibDir = (Join-Path $toolsPath "\ib\")
    $ibDirTmp = (Join-Path $toolsPath "\Invoke-Build\")
    $ibTmpFile = (Join-Path $toolsPath "Invoke-Build.zip")
    If (Test-Path $ibDir){
        Remove-Item $ibDir -Force -Recurse
    
    }
    Push-Location 
    try {
        Set-Location  $toolsPath 
        Invoke-Expression "& {$((New-Object Net.WebClient).DownloadString('https://github.com/nightroman/PowerShelf/raw/master/Save-NuGetTool.ps1'))} Invoke-Build"
        Rename-Item -path $ibDirTmp -newname "ib"
        Remove-Item $ibTmpFile -Force
    }
    finally {
        Pop-Location
    }
    
}

UpdateInvokeBuild
