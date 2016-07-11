<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>


param(
		$configPath,
		$scriptsPath,
		$buildTarget,
		$buildPath,
		$buildEnv,
		$repoPath,
		$conf = (Get-Content $configPath | Out-String | ConvertFrom-Json),
		$buildTmpDir = (Join-Path $buildPath "tmp"),
		$buildDir = (Join-Path $buildTmpDir "build"),
		$buildExampleDir = (Join-Path $buildTmpDir "build-example"),
		$buildExampleReadyDir = (Join-Path $buildPath "example"),
		$buildConicReadyDir = (Join-Path $buildPath "conic"),
		$margeDir = (Join-Path $buildTmpDir "marge"),
		$margExampleDir = (Join-Path $buildTmpDir "marge-example"),
		$srcDir = (Join-Path  $repoPath $conf.SrcDir),
		$packagesDir = (Join-Path  $repoPath $conf.PackagesDir),
		$libz = (Join-Path $repoPath $conf.Libz),
		$nuget = (Join-Path $repoPath $conf.Nuget),
		$7zip = (Join-Path $repoPath $conf.Zip),
		$gitversion = (Join-Path $repoPath $conf.Gitversion),
		$currentAssemblyInfo = "AssemblyInfo.cs",
		$oldAssemblyInfo = "AssemblyInfo.cs.old",
		$nugetTempDir = (Join-Path $buildTmpDir "nuget-tmp"),
		$nugetDir = (Join-Path $buildPath "nuget"),
		$packtDir = (Join-Path $buildPath "pack")
    )
Write-Host "aa:$scriptsPath"

# inser tools
. (Join-Path $scriptsPath "ps\misc.ps1")

use 14.0 MSBuild

# Synopsis: Remove temp files.
task Clean {

	Write-Host $buildOutDir
	Ensure-Dir-Exists-And-Is-Empty $buildOutDir
}

# Synopsis: Download tools if needed
task Get-Tools {

	if((Test-Path $nuget) -eq 0)
	{
		$nugetDir = Split-Path  $nuget -parent
		Ensure-Dir-Exists $nugetDir
		wget "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -outfile $nuget
	}

	Ensure-Dir-Exists $packagesDir

	if((Test-Path $libz) -eq 0)
	{
		exec {  &$nuget install -excludeversion -pre LibZ.Tool -outputdirectory $packagesDir }
	}
}

# Synopsis: Build the project.
task Build-Conic {
	Write-Host "Build Conic"
	$projectFile = Join-Path $buildRepoRooDir  $conf.ProjectFile
	Ensure-Dir-Exists-And-Is-Empty $buildDir 
	Update-AssemblyInfo $srcDir $currentAssemblyInfo $buildVs $buildGitBranch $buildGitHashAndTime $conf.ProductName $conf.CompanyName $conf.Copyright

	try {
		exec { msbuild $projectFile /t:Build /p:Configuration=$buildTarget /v:quiet /p:OutDir=$buildDir    } 
	}
	catch {
		Restore-AssemblyInfo $srcDir $currentAssemblyInfo $oldAssemblyInfo
		throw $_.Exception
		exit 1
	}
	finally {
		Restore-AssemblyInfo $srcDir $currentAssemblyInfo $oldAssemblyInfo
	}

}

# Synopsis: Build the example.
task Build-Example {
	Write-Host "Build Example"
	$winformProjectFile = Join-Path $buildRepoRooDir  $conf.WinformProjectFile
	Ensure-Dir-Exists-And-Is-Empty $buildExampleDir
	exec { msbuild $winformProjectFile /t:Build /p:Configuration=$buildTarget /v:quiet /p:OutDir=$buildExampleDir    } 
}

# Synopsis: Package-Restore
task Package-Restore-Conic {

	Push-Location  $buildRepoRooDir
	$slnFile = Join-Path $buildRepoRooDir  $conf.SlnFile
	exec {  &$nuget restore $slnFile  }
	Pop-Location

}

# Synopsis: Package-Restore
task Package-Restore-Example {

	Push-Location  $buildRepoRooDir
	$slnFile = Join-Path $buildRepoRooDir  $conf.ExampleSlnFile
	exec {  &$nuget restore $slnFile  }
	Pop-Location

}

# Synopsis: Marge 
task Marge-Conic  {	

	Write-Host "Marge Conic"
	$src = $buildDir
	$dst = $margeDir
	Ensure-Dir-Exists-And-Is-Empty $dst
	Push-Location  $src
	& $libz inject-dll --assembly Conic.exe --include *.dll --move
	Pop-Location
	Copy-Item  "$src/Conic.exe" -Destination $dst 
	Copy-Item  "$src/NLog.config" -Destination $dst 
}

# Synopsis: Marge example
task Marge-Example  {	

	Write-Host "Marge example"
	$src = $buildExampleDir
	$dst = $margExampleDir
	Ensure-Dir-Exists-And-Is-Empty $dst
	Push-Location  $src
	& $libz inject-dll --assembly Conic.Example.WinForm.exe --include *.dll --move
	Pop-Location
	Copy-Item  "$src/Conic.Example.WinForm.exe" -Destination $dst 

}

# Synopsis: Marge example
task Copy-To-Ready-Example  {	

	$dst = $buildExampleReadyDir
	Ensure-Dir-Exists-And-Is-Empty $dst
	
	$winformDir = "$dst/winform"
	Ensure-Dir-Exists-And-Is-Empty $winformDir
	cp  "$margExampleDir/Conic.Example.WinForm.exe" -Destination "$winformDir"

	$extensionDir = "$dst/extension"
	Ensure-Dir-Exists-And-Is-Empty $extensionDir
	cp  "$buildRepoRooDir/src/Example/Conic.Example.ChromeExtension/app/*" -Recurse -Destination "$extensionDir"

	$conicDir = "$dst/conic"
	Ensure-Dir-Exists-And-Is-Empty $conicDir
	cp  "$margeDir/Conic.exe" -Destination "$conicDir"
	cp  "$margeDir/NLog.config" -Destination "$conicDir"
}

# Synopsis: Marge example
task Copy-To-Ready-Conic  {	

	$dst = $buildConicReadyDir
	Ensure-Dir-Exists-And-Is-Empty $dst
	cp  "$margeDir/Conic.exe" -Destination "$dst"
	cp  "$margeDir/NLog.config" -Destination "$dst"
}


# Synopsis: Make nuget file
task Prepare-Conic-Example-To-Work -If ($buildEnv -eq 'local') {

	$dst = "$buildExampleReadyDir/conic"
	$conicExe =  (Join-Path $dst "Conic.exe") 
	$manifestFile =  (Join-Path $dst "manifest.json") 
	$configFile = "$dst/conic.config.json"
	$nameMessagingHost = "default.conic.host"
	$conicPipeName = "default.conic.pipename"
	
	Write-Host "Manifest for Conic"
	$manifestJson = @"
	{
		"allowed_origins":[""],
		"description":"Conic ecam",
		"name":"",
		"path":"",
		"type":"stdio"
	}
"@

	$manifest = $manifestJson | ConvertFrom-Json
	$manifest.path = $conicExe
	$manifest.name = $nameMessagingHost
	$manifest.description = "Conic example"
	$manifest.type = "stdio"
	$manifest.allowed_origins[0] = "chrome-extension://dogdgedenbdbmillkeceelealeiedala/"
	$json = (ConvertTo-json $manifest)
	[System.IO.File]::WriteAllLines($manifestFile, $json, [text.encoding]::UTF8)

	Write-Host "Config for Conic"
	$configJson = @"
	{
		"PipeName":""
	}
"@
	$config = $configJson | ConvertFrom-Json
	$config.PipeName = $conicPipeName
	$json = (ConvertTo-json $config)
	[System.IO.File]::WriteAllLines($configFile, $json , [text.encoding]::UTF8)

	Write-Host "Registry for Conic"
	New-Item -Path "HKCU:\SOFTWARE\Google\Chrome\NativeMessagingHosts\$nameMessagingHost" -Value $manifestFile �Force

}

# Synopsis: Make nuget file
task Pack-Nuget  {

	Ensure-Dir-Exists-And-Is-Empty $nugetTempDir
	Ensure-Dir-Exists-And-Is-Empty $nugetDir
	Ensure-Dir-Exists-And-Is-Empty "$nugetTempDir\tools"
	
	$spacFilePath = Join-Path $buildScriptsDir "nuget\Conic.nuspec"
	$specFileOutPath = Join-Path $nugetTempDir "Conic.nuspec"
	
	cp "$margeDir\Conic.exe" "$nugetTempDir\tools"
	cp "$margeDir\NLog.config" "$nugetTempDir\tools"
    
    $spec = [xml](get-content $spacFilePath)
    $spec.package.metadata.version = ([string]$spec.package.metadata.version).Replace("{Version}", $buildVs)
    $spec.Save($specFileOutPath )
    exec { &$nuget pack $specFileOutPath -OutputDirectory $nugetDir }
}

# Synopsis: Make zip file.
task Pack-To-Zip  {

	Ensure-Dir-Exists-And-Is-Empty $packtDir
	
	$src = "$margeDir\Conic.exe"
	$dst =  "$packtDir\conic.zip"
    exec { &$7zip a -tzip  "$dst"  "$src" }
}

task Pack-To-Zip  {

	Ensure-Dir-Exists-And-Is-Empty $packtDir
	
	$src = "$margeDir\Conic.exe"
	$dst =  "$packtDir\conic.zip"
    exec { &$7zip a -tzip  "$dst"  "$src" }
}

task Copy-Local -If ($buildEnv -eq 'local')  {

	Ensure-Dir-Exists-And-Is-Empty $packtDir
	
	$src = "$margeDir\Conic.exe"
	$dst =  "$buildRepoRooDir\stuff\working-version\"
    cp $src $dst -Force
}
# Synopsis: Do all
#task . Clean, Get-Tools, Package-Restore-Conic, Update-AssemblyInfo, Build-Conic,  Marge, Pack-To-Zip, Pack-Nuget, Copy-Local 
#task Example Clean, Get-Tools, Package-Restore-Example, Update-AssemblyInfo, Build,  Marge, Pack-To-Zip, Pack-Nuget, Copy-Local 
task Init Clean, Get-Tools
task Conic Init, Package-Restore-Conic, Build-Conic,  Marge-Conic,  Copy-To-Ready-Conic 
task Example Init, Conic, Package-Restore-Example, Build-Example, Marge-Example, Copy-To-Ready-Example, Prepare-Conic-Example-To-Work
task Build-All Init, Example
Task Publish-Conic Conic, Pack-Nuget 
task .  Publish-Conic 


