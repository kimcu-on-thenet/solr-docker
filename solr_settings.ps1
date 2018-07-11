#Solr Docker
$SolrDockerPath = "$PSScriptRoot\Docker"
$DockerComposeFile = Join-Path $SolrDockerPath "docker-compose.yml"
$ScriptsPath = "$PSScriptRoot\Scripts"
$DockerContainer = "Solr662"
$KeystoreFile=  "solr-ssl.keystore.jks"
$KeystoreFilePath=  Join-Path $SolrDockerPath $KeystoreFile
$P12KeystoreFile= Join-Path $SolrDockerPath "solr-ssl.keystore.p12"
$KeystorePassword= "secret"

# Solr Parameters
$SolrUrl = "https://localhost:8983/solr"
$SolrRoot = Join-Path $PSScriptRoot "SolrData"

