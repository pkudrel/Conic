Function EnsureDirExists ($path){

    if((Test-Path $path) -eq 0) {
        mkdir $path | out-null;
    }
}

function EnsureDirExistsAndIsEmpty ($path){

    if((Test-Path $path) -eq 0) {
        mkdir $path | out-null;
    } 
    else {
        Remove-Item $path -rec -force | out-null
        mkdir $path | out-null;
    }
}

function DownloadFileIfNotExists($src , $dstDirectory, $checkFile){
    $msg = "File src: '$src'; Dst dir: '$dstDirectory'; Check file: '$checkFile'"
    If (-not (Test-Path $checkFile)){
        Write-Host "$msg ; Check file not exists - processing"
        If (-not (Test-Path $dstDirectory)){
            New-Item -ItemType directory -Path $dstDirectory
        }
        Invoke-WebRequest $src -OutFile $checkFile
    } else {
        Write-Host "$msg ; Check file exists - exiting"
    }
}

function DownloadNugetIfNotExists ($nuget, $packageName, $dstDirectory, $checkFile) {
    $msg = "Package name: '$packageName'; Dst dir: '$dstDirectory'; Check file: '$checkFile'"
    If (-not (Test-Path  $checkFile)){
        Write-Host "$msg ; Check file not exists - processing"
        & $nuget install $packageName -excludeversion -outputdirectory $dstDirectory
    } else {
        Write-Host "$msg ; Check file exists - exiting"
    }
}

function BackupTemporaryFiles($workDir, $fileToBeckup){
			
    Write-Host "Temporary beckup files. Root dir: '$workDir'"
    $beckupArr = New-Object System.Collections.ArrayList
    foreach ($b in $fileToBeckup) {
        $f1 = Join-Path $workDir $b
        $f2 = "$f1.temporary-beckup-file"
        $pairArr = @{src = $f1; dst = $f2;}
        $beckupArr.Add($pairArr) > $null
    }	
			
    foreach ($b in $beckupArr) {
        $src = $b.src;
        $dst = $b.dst;
        Write-Host 	"Backup; src: $src ; dst: $dst"
        Copy-Item $src $dst -Force
    }
			
}

function RestoreTemporaryFiles ($workDir) {
			
    Write-Host "Restore temporary backuped files. Root dir: '$workDir'"
    $directory = Resolve-Path $workDir
    $pattern = "$directory\**\*.temporary-beckup-file"
    $items = Get-ChildItem $pattern -Recurse | % FullName

			 foreach ($item in $items) {
        $src  = $item
        $dir = Split-Path  $item -parent	
        $dst = Join-Path $dir ([System.IO.Path]::GetFileNameWithoutExtension($item))
				
        Write-Host 	"Restore; src: $src ; dst: $dst"
        Move-Item $src $dst -Force
    }

}