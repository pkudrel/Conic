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
		$buildDateTime,
		$conf = (Get-Content $configPath | Out-String | ConvertFrom-Json),
		$publishRepoDir = (Join-Path (Split-Path $repoPath -Parent) $conf.PublishRepoSubDir), 
		$functionRoot = (Join-Path $repoPath "src\SimpleFun"), 
		$toolsPath,
		$buildTmpDir = (Join-Path $buildPath "tmp"),
		$projects = ([PSCustomObject]$conf.Projects),
	    $buildVersion = $global:psgitversion,
		$buildDir = (Join-Path $buildPath "build"),
		$margeDir =  (Join-Path $buildPath "marge"),
		$readyDir =  (Join-Path $buildPath "ready"),
		$srcDir = (Join-Path  $repoPath $conf.SrcDir),
		$packagesDir = (Join-Path  $repoPath $conf.PackagesDir),
		$libz = (Join-Path $repoPath $conf.Libz),
		$eventBuilder = (Join-Path $repoPath $conf.EventBuilder),
		$nuget = (Join-Path $scriptsPath "tools\nuget\nuget.exe"),
		$gitversion = (Join-Path $repoPath $conf.Gitversion),
		$gitBranch,
		$gitCommitNumber,
		$buildMiscInfo,
		$nugetTempDir = (Join-Path $buildTmpDir "nuget-tmp"),
		$nugetDir = (Join-Path $buildPath "nuget"),
		$packtDir = (Join-Path $buildPath "pack"),
		$buildConicReadyDir = (Join-Path $buildPath "conic")

    )

# inser tools
. (Join-Path $scriptsPath "vendor\ps-auto-helpers\ps\misc.ps1")
. (Join-Path $scriptsPath "vendor\ps-auto-helpers\ps\io.ps1")
. (Join-Path $scriptsPath "vendor\ps-auto-helpers\ps\assembly-tools.ps1")

use 14.0 MSBuild

# Synopsis: Remove temp files.
task Clean {

	Write-Host $buildDir
	EnsureDirExistsAndIsEmpty $buildDir
}

# Synopsis: Download tools if needed
task Get-Tools {



	if((Test-Path $nuget) -eq 0)
	{
		$nugetDir = Split-Path  $nuget -parent
		Ensure-DirExists $nugetDir
		wget "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -outfile $nuget
	}

	Ensure-DirExists $packagesDir

	if((Test-Path $libz) -eq 0)
	{
		exec {  &$nuget install -excludeversion -pre LibZ.Tool -outputdirectory $packagesDir }
	}
}

# Synopsis: Build the project.
task Build-Conic {
	Write-Host "Build Conic"
	
	$projectFile = Join-Path $repoPath  "/src/Conic/Conic.csproj"
	EnsureDirExistsAndIsEmpty $buildDir 
	$srcWorkDir = Join-Path $repoPath "/src/Conic/"
	$out =  $buildDir;
	$out
	UpdateAssemblyInfo $srcWorkDir $buildVersion.AssemblyVersion $buildVersion.AssemblyFileVersion $buildVersion.AssemblyInformationalVersion $conf.ProductName $conf.CompanyName $conf.Copyright

	try {
		exec { msbuild $projectFile /t:Build /p:Configuration=$buildTarget /v:quiet /p:OutDir=$out     } 
	}
	catch {
		RestoreTemporaryFiles $srcWorkDir
		throw $_.Exception
		exit 1
	}
	finally {
		RestoreTemporaryFiles $srcWorkDir
	}

}

# Synopsis: Build the example.
task Build-Example {
	Write-Host "Build Example"
	$winformProjectFile = Join-Path $repoPath  $conf.WinformProjectFile
	EnsureDirExistsAndIsEmpty $buildExampleDir
	exec { msbuild $winformProjectFile /t:Build /p:Configuration=$buildTarget /v:quiet /p:OutDir=$buildExampleDir    } 
}

# Synopsis: Package-Restore
task Package-Restore-Conic {

	Push-Location  $repoPath
	$slnFile = Join-Path $repoPath  "/src/Conic.sln"
	$slnFile
	exec {  &$nuget restore $slnFile  }
	Pop-Location

}

# Synopsis: Package-Restore
task Package-Restore-Example {

	Push-Location  $repoPath
	$slnFile = Join-Path $repoPath  $conf.ExampleSlnFile
	exec {  &$nuget restore $slnFile  }
	Pop-Location

}

# Synopsis: Marge 
task Marge-Conic  {	

	Write-Host "Marge Conic"
	
	$src = $buildDir;
	$dst = $margeDir
	EnsureDirExistsAndIsEmpty $dst
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
	EnsureDirExistsAndIsEmpty $dst
	Push-Location  $src
	

	& $libz inject-dll --assembly Conic.Example.WinForm.exe --include *.dll --move
	Pop-Location
	Copy-Item  "$src/Conic.Example.WinForm.exe" -Destination $dst 

}

# Synopsis: Marge example
task Copy-To-Ready-Example  {	

	$dst = $buildExampleReadyDir
	EnsureDirExistsAndIsEmpty $dst
	
	$winformDir = "$dst/winform"
	EnsureDirExistsAndIsEmpty $winformDir
	cp  "$margExampleDir/Conic.Example.WinForm.exe" -Destination "$winformDir"

	$extensionDir = "$dst/extension"
	EnsureDirExistsAndIsEmpty $extensionDir
	cp  "$repoPath/src/Example/Conic.Example.ChromeExtension/app/*" -Recurse -Destination "$extensionDir"

	$conicDir = "$dst/conic"
	EnsureDirExistsAndIsEmpty $conicDir
	cp  "$margeDir/Conic.exe" -Destination "$conicDir"
	cp  "$margeDir/NLog.config" -Destination "$conicDir"
}

# Synopsis: Marge example
task Copy-To-Ready-Conic  {	

	$dst = $buildConicReadyDir
	EnsureDirExistsAndIsEmpty $dst
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
	New-Item -Path "HKCU:\SOFTWARE\Google\Chrome\NativeMessagingHosts\$nameMessagingHost" -Value $manifestFile –Force

}

# Synopsis: Make nuget file
task Pack-Nuget  {

	EnsureDirExistsAndIsEmpty $nugetTempDir
	EnsureDirExistsAndIsEmpty $nugetDir
	EnsureDirExistsAndIsEmpty "$nugetTempDir\tools"
	
	$spacFilePath = Join-Path $scriptsPath "nuget\Conic.nuspec"
	$specFileOutPath = Join-Path $nugetTempDir "Conic.nuspec"
	
	cp "$margeDir\Conic.exe" "$nugetTempDir\tools"
	cp "$margeDir\NLog.config" "$nugetTempDir\tools"
	cp "$scriptsPath\Samples\conic.config.json.sample" "$nugetTempDir\tools"
	cp "$scriptsPath\Samples\manifest.json.sample" "$nugetTempDir\tools"
    
    $spec = [xml](get-content $spacFilePath)
    $spec.package.metadata.version = ([string]$spec.package.metadata.version).Replace("{Version}", $buildVersion.NuGetVersion)
    $spec.Save($specFileOutPath )
    exec { &$nuget pack $specFileOutPath -OutputDirectory $nugetDir }
}

# Synopsis: Make zip file.
task Pack-To-Zip  {

	EnsureDirExistsAndIsEmpty $packtDir
	
	$src = "$margeDir\Conic.exe"
	$dst =  "$packtDir\conic.zip"
    exec { &$7zip a -tzip  "$dst"  "$src" }
}

task Pack-To-Zip  {

	EnsureDirExistsAndIsEmpty $packtDir
	
	$src = "$margeDir\Conic.exe"
	$dst =  "$packtDir\conic.zip"
    exec { &$7zip a -tzip  "$dst"  "$src" }
}

task Copy-Local -If ($buildEnv -eq 'local')  {

	EnsureDirExistsAndIsEmpty $packtDir
	
	$src = "$margeDir\Conic.exe"
	$dst =  "$repoPath\stuff\working-version\"
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



