

function Install-Solr {
    param(
        [string] $DockerComposeFile,
        [string] $SolrDataRootPath
    )

    Write-Host "Prepare to install Solr-Docker container"
    CleanUp-Solr-Docker -DockerComposeFile $DockerComposeFile -SolrDataRootPath $SolrDataRootPath -ReCreateSolrDataFolder $true

    Write-Host "Intializing Solr-Docker container"
    & docker-compose --file $DockerComposeFile up -d --build
}

function CleanUp-Solr-Docker {
    param(
        [string] $DockerComposeFile,
        [string] $SolrDataRootPath,
        [bool] $ReCreateSolrDataFolder = $false
    )
    & docker-compose --file $DockerComposeFile down
    If((Test-Path $SolrDataRootPath)) {
        Remove-Item -Path $SolrDataRootPath -Force -Recurse
    } 

    IF(!(Test-Path $SolrDataRootPath) -and $ReCreateSolrDataFolder) {
        New-Item -ItemType Directory -Force -Path $SolrDataRootPath
    }
}

function Get-KeyTool {
    try {
        $path = $Env:JAVA_HOME + '\keytool.exe'
        Write-Host $path
        if (Test-Path $path) {
            $keytool = (Get-Command $path).Source
        }
    } catch {
        $keytool = Read-Host "keytool.exe not on path. Enter path to keytool (found in JRE bin folder)"

        if([string]::IsNullOrEmpty($keytool) -or -not (Test-Path $keytool)) {
            Write-Error "Keytool path was invalid."
        }
    }

    return $keytool
}

function Uninstall-Solr {
    param(
        [string] $DockerComposeFile,
        [string] $SolrDataRoot,
        [string] $P12KeystoreFile,
        [string] $JksKeystoreFile,
        [string] $KeystorePassword
    )
    #Remove certificate from KeyStore
    Write-Host "Remove certificate from KeyStore."
    $keytool = Get-KeyTool
    & $keytool -delete -alias "solr-ssl" -storetype JKS -keystore $P12KeystoreFile -storepass $KeystorePassword


    Write-Host "Remove .p12 key."
    Remove-File -filePath $P12KeystoreFile
    Write-Host "Removed successful `'$P12KeystoreFile`'"

    Write-Host "Remove .jks key."
    Remove-File -filePath $JksKeystoreFile
    Write-Host "Removed successful `'$JksKeystoreFile`'"
    

    #Remove ssl certificates
    Write-Host ''
    Write-Host 'Removing Solr-SSl Certificate from CA'
    Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object -Property FriendlyName -eq "solr-ssl" | Remove-Item
    Write-Host 'Remove Solr-SSl Certificate from CA successfully'

    CleanUp-Solr-Docker -DockerComposeFile $DockerComposeFile -SolrDataRootPath $SolrDataRoot
}

function Remove-File {
    param(
        [string] $filePath
    )

    if((Test-Path $filePath)) {
        Write-Host "Removing $filePath..."
        Remove-Item $filePath
    }
}

function Install-SolrCertificate {
    param(
        [string] $DockerContainer,
        [string] $KeystoreFileName,
        [string] $KeystoreFilePath,
        [string] $KeystorePassword,
        [string] $P12Path
    )

    

    Write-Host ''
    Write-Host 'get cert from docker container'
    # get cert from docker container
    # cert location in docker: /opt/solr/server/etc/solr-ssl.keystore.jks
    $dockerPath = $("$DockerContainer`:/opt/solr/server/etc/$KeystoreFileName")
    Write-Host "First arg: $dockerPath"
    & docker cp $dockerPath $KeystoreFilePath
    $certPath = $KeystoreFilePath
    if (Test-Path $certPath){
        Write-Host "Cert `'$certPath`' has been copied successfully."
    }
    else {
        Write-Host "Cannot find cert at location `'$certPath`'"
    }

    Write-Host ''
    Write-Host 'Generating .p12 to import to Windows...'
    $keytool = Get-KeyTool
    & $keytool -importkeystore -srckeystore $certPath -destkeystore $P12Path -srcstoretype jks -deststoretype pkcs12 -srcstorepass $KeystorePassword -deststorepass $KeystorePassword

    Write-Host ''
    Write-Host 'Trusting generated SSL certificate...'
    Write-Verbose "Installing cert `'$P12Path`'"
    $secureStringKeystorePassword = ConvertTo-SecureString -String $KeystorePassword -Force -AsPlainText
    $root = Import-PfxCertificate -FilePath $P12Path -Password $secureStringKeystorePassword -CertStoreLocation Cert:\LocalMachine\Root
    Write-Host "Solr SSL certificate was imported from docker container `'$DockerContainer`' and is now locally trusted. (added as root CA)"
}