#####################################################
# 
#  Install Solr 6.6.2 Docker Container
# 
#####################################################

[CmdletBinding()]
param(
    [switch] $remove
)

$ErrorActionPreference = 'Stop'

. $PSScriptRoot\solr_settings.ps1

if (Get-Module("solr")) {
    Remove-Module "solr"
}
Import-Module "$ScriptsPath\solr.psm1" #-Verbose

function Install-Prerequisites {
    #Verify Java version
    $JRERequiredVersion = "1.8"
    $minVersion = New-Object System.Version($JRERequiredVersion)
    $foundVersion = $FALSE
	$jrePath = "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment"
	$jdkPath = "HKLM:\SOFTWARE\JavaSoft\Java Development Kit"
	if (Test-Path $jrePath) {
		$path = $jrePath
	}
	elseif (Test-Path $jdkPath) {
		$path = $jdkPath
	}
	else {
        throw "Cannot find Java Runtime Environment or Java Development Kit on this machine."
	}
	
	$javaVersionStrings = Get-ChildItem $path | ForEach-Object { $parts = $_.Name.Split("\"); $parts[$parts.Count-1] } 
    foreach ($versionString in $javaVersionStrings) {
        try {
            $version = New-Object System.Version($versionString)
        } catch {
            continue
        }

        if ($version.CompareTo($minVersion) -ge 0) {
            $foundVersion = $TRUE
        }
    }
    if (-not $foundVersion) {
        throw "Invalid Java version. Expected $minVersion or over."
    }
}

function Install-SolrDocker {
    try {
        Install-Solr -DockerComposeFile $DockerComposeFile -SolrDataRootPath $SolrRoot
        Install-SolrCertificate -DockerContainer $DockerContainer `
                            -KeystoreFileName $KeystoreFile `
                            -KeystoreFilePath $KeystoreFilePath `
                            -KeystorePassword $KeystorePassword `
                            -P12Path $P12KeystoreFile
    }
    catch {
        write-host "Caught an exception:" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
    }
}


Install-Prerequisites
if ($remove) {
    Write-Host "*******************************************************" -ForegroundColor Green
    Write-Host " Uninstalling Solr" -ForegroundColor Green
    Uninstall-Solr -DockerComposeFile $DockerComposeFile `
                    -SolrDataRoot $SolrRoot `
                    -P12KeystoreFile $P12KeystoreFile `
                    -JksKeystoreFile $KeystoreFilePath `
                    -KeystorePassword $KeystorePassword
    Write-Host "** Finish un-installing Solr *****************************" -ForegroundColor Green
} else {
    Write-Host "*******************************************************" -ForegroundColor Green
    Write-Host " Installing Solr" -ForegroundColor Green

    Install-SolrDocker

    Write-Host "** Finish installing Solr *****************************" -ForegroundColor Green
}