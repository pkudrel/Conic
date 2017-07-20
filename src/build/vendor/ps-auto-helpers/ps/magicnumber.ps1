
<#
.Synopsis
	Get "magic"  Major, Minor, Patch number from build
#>
function Get-MagicMajorMinorPatch {
	
    param(
        [parameter(Mandatory=$true)] [int] $counter
    )

    $r = [PSCustomObject]  @{"Major" = 0; "Minor" = 0; "Patch" = 0;}
    $r.Major =  [math]::floor($counter / 100 )
    $rest =  ($counter - ($r.Major * 100))
    $r.Minor =  [math]::floor($rest/10)
    $rest =  ($rest - ($r.Minor * 10))
    $r.Patch =  [math]::floor($rest / 1 ) 
    return $r
}


function Get-MagicMajorMinorPatchByDigits {
	
    param(
        [parameter(Mandatory=$true)] [int] $counter,
        [parameter(Mandatory=$true)] [int] $sliceSize,
        [parameter(Mandatory=$true)]  $template,
        [parameter(Mandatory=$true)]  $defaultValues
				
    )
    $r = [PSCustomObject]  @{"Major" = $defaultValues.Major; "Minor" = $defaultValues.Minor; "Patch" = $defaultValues.Patch;}
    $fieldsToFill = ($template| Get-Member | Where-Object  {$_.MemberType -eq "NoteProperty"}).length
    $s = $counter.ToString();
    $max = $fieldsToFill  * $sliceSize;
		
    #min lenght
    if (($max - $s.length) -gt 0) {
        $t1 = New-Object System.String('0',  ($max - $s.length));	
        $s =  $t1 + $s;
    }

			 if ($fieldsToFill -eq 1) {
        $r.Patch = [int]::Parse($s)
			 }
			 if ($fieldsToFill -eq 2) {
        $t1  =  $s.Substring(($s.length) - $sliceSize, $sliceSize);
        $t2  =  $s.Substring(0,  ($s.length - $t1.Length)); 
        $r.Patch = [int]::Parse($t1)
        $r.Minor = [int]::Parse($t2)
			 }

			 if ($fieldsToFill -eq 3) {
        $t1  =  $s.Substring(($s.length) - $sliceSize, $sliceSize);
        $t2  =  $s.Substring(($s.length - (2*$sliceSize)),  $sliceSize); 
        $t3  =  $s.Substring(0,  ($s.length - $t1.Length - $t2.Length)); 
        $r.Patch = [int]::Parse($t1)
        $r.Minor = [int]::Parse($t2)
        $r.Major = [int]::Parse($t3)
			 }
    return $r
}


function Get-Object($major, $minor, $patch ) {
    return [PSCustomObject]  @{"Major" = $major; "Minor" = $minor; "Patch" = $patch; }
}
function Get-ExtendVersion($simple, $private ) {
    return [PSCustomObject]  @{"Major" = $simple.Major; "Minor" = $simple.Minor; "Patch" = $simple.Patch; "Private" = $private }
}


function Get-MagicNumber {
	
    param(
        [parameter(Mandatory=$true)] [int] $major,
        [parameter(Mandatory=$true)] [int] $minor,
        [parameter(Mandatory=$true)] [int] $patch,
        [parameter(Mandatory=$true)] [int] $private,
        [parameter(Mandatory=$true)] [int] $buildCounter,
        [parameter(Mandatory=$true)] [ValidateSet('standard','fromBuildCounterMMP','combinateMajorAndBuildSlice3','standardOrCombinateMajorAndBuildSlice3')] [string] $strategy = "standard"
    )

    $r = [PSCustomObject]  @{"Major" = 0; "Minor" = 0; "Patch" = 0;}
    $templateMajorMinorPath = [PSCustomObject]  @{"Major" = 0; "Minor" = 0; "Patch" = 0;}
    $templateMinorPath = [PSCustomObject]  @{"Minor" = 0; "Patch" = 0;}
			
    $res = @{};
       
		
    # default
    $res["default"] = Get-Object $major $minor $patch $private ;
            
    #buildMajorMinorPatch
    $res["buildMajor100Minor10Patch1"] = Get-MagicMajorMinorPatch  $buildCounter ;
           
             
    #combinateMagicMajorMinorPatch
    $res["combinateMajorMinorAndBuild"] = Get-Object $major $minor $buildCounter 0;

    #buildMajorMinorPatchBy2Digits
    $res["buildMajorMinorPatchBySlice3"] = Get-MagicMajorMinorPatchByDigits $buildCounter 3 $templateMajorMinorPath  $r;
			
    $res["buildMinorPatchBySlice3"] = Get-MagicMajorMinorPatchByDigits $buildCounter 3 $templateMinorPath  $r;

    #buildMajorMinorPatchBy3Digits
    $res["combinateMajorAndBuildSlice3"] = Get-MagicMajorMinorPatchByDigits $buildCounter 3 $templateMinorPath  $res["default"];
 			$res["combinateMajorAndBuildSlice2"] = Get-MagicMajorMinorPatchByDigits $buildCounter 2 $templateMinorPath  $res["default"];


    $res1 = [PSCustomObject]  @{"MagicVersion" = 0; "MagicVersionExtend" = 0; "MagicVersionAll" = 0;}
    $res1.MagicVersionAll = [PSCustomObject]$res;

    switch ($strategy) {
        standard { 
            $res1.MagicVersion = $res["default"]
            $res1.MagicVersionExtend = Get-ExtendVersion $res1.MagicVersion $private;
            break;     
        }
        fromBuildCounterMMP {
            $res1.MagicVersion = $res["buildMajor100Minor10Patch1"]
            $res1.MagicVersionExtend = Get-ExtendVersion $res1.MagicVersion $private;
            break;
        }
        combinateMajorAndBuildSlice3 {
            $res1.MagicVersion = $res["combinateMajorAndBuildSlice3"]
            $res1.MagicVersionExtend = Get-ExtendVersion $res1.MagicVersion $private;
            break;
        }
        standardOrCombinateMajorAndBuildSlice3 {
            if ( ($major -eq 0) -and ($minor -eq 0) -and ($patch -eq 0) -and ($private -eq 0) ){
                $res1.MagicVersion = $res["combinateMajorAndBuildSlice3"]
                $res1.MagicVersionExtend = Get-ExtendVersion $res1.MagicVersion $private;					
            } else{
                $res1.MagicVersion = $res["default"]
                $res1.MagicVersionExtend = Get-ExtendVersion $res1.MagicVersion $private;	
            }
            break;
        }
        default {
            $res1.MagicVersion = $res["default"]
            $res1.MagicVersionExtend = Get-ExtendVersion $res1.MagicVersion $private;
        }
				}

				
    return   $res1
}
