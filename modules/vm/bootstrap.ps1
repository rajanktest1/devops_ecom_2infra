# bootstrap.ps1
# Runs on the Windows VM ONCE via Azure Custom Script Extension at provision time.
# Installs: Node.js 20, IIS, iisnode module, URL Rewrite module, creates the IIS site.

$ErrorActionPreference = 'Stop'

function Write-Log($msg) { Write-Host "[bootstrap] $msg" }

Write-Log "Starting VM bootstrap..."

# -----------------------------------------------------------------------
# 1. Install Chocolatey (package manager for Windows)
# -----------------------------------------------------------------------
Write-Log "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
$env:PATH += ";$env:ALLUSERSPROFILE\chocolatey\bin"

# -----------------------------------------------------------------------
# 2. Install Node.js 20 LTS
# -----------------------------------------------------------------------
Write-Log "Installing Node.js 20..."
choco install nodejs-lts --version 20.19.0 -y --no-progress
$env:PATH += ";C:\Program Files\nodejs"
node --version

# -----------------------------------------------------------------------
# 3. Enable IIS and required features
# -----------------------------------------------------------------------
Write-Log "Enabling IIS features..."
$features = @(
    'Web-Server',
    'Web-Common-Http',
    'Web-Static-Content',
    'Web-Default-Doc',
    'Web-Http-Errors',
    'Web-Http-Logging',
    'Web-Request-Monitor',
    'Web-Filtering',
    'Web-Mgmt-Console',
    'Web-Mgmt-Tools',
    'Web-ISAPI-Ext',
    'Web-ISAPI-Filter'
)
Install-WindowsFeature -Name $features -IncludeManagementTools | Out-Null
Write-Log "IIS enabled."

# -----------------------------------------------------------------------
# 4. Install URL Rewrite module (required by iisnode routing)
# -----------------------------------------------------------------------
Write-Log "Installing URL Rewrite module..."
$rewriteUrl = 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi'
$rewriteMsi = "$env:TEMP\rewrite.msi"
Invoke-WebRequest -Uri $rewriteUrl -OutFile $rewriteMsi -UseBasicParsing
Start-Process msiexec.exe -ArgumentList "/i `"$rewriteMsi`" /quiet /norestart" -Wait
Write-Log "URL Rewrite installed."

# -----------------------------------------------------------------------
# 5. Install iisnode module
# -----------------------------------------------------------------------
Write-Log "Installing iisnode..."
$iisnodeUrl = 'https://github.com/Azure/iisnode/releases/download/v0.2.26/iisnode-full-v0.2.26-x64.msi'
$iisnodeMsi = "$env:TEMP\iisnode.msi"
Invoke-WebRequest -Uri $iisnodeUrl -OutFile $iisnodeMsi -UseBasicParsing
Start-Process msiexec.exe -ArgumentList "/i `"$iisnodeMsi`" /quiet /norestart" -Wait
Write-Log "iisnode installed."

# -----------------------------------------------------------------------
# 6. Create app directory and placeholder web.config
# -----------------------------------------------------------------------
$appDir = 'C:\inetpub\ecomm-backend'
Write-Log "Creating app directory: $appDir"
New-Item -ItemType Directory -Path $appDir -Force | Out-Null

@'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="src/index.js" verb="*" modules="iisnode" />
    </handlers>
    <rewrite>
      <rules>
        <rule name="API">
          <match url="/*" />
          <action type="Rewrite" url="src/index.js" />
        </rule>
      </rules>
    </rewrite>
    <iisnode node_env="production" loggingEnabled="true" devErrorsEnabled="false" />
    <security>
      <requestFiltering>
        <hiddenSegments>
          <add segment="node_modules" />
        </hiddenSegments>
      </requestFiltering>
    </security>
  </system.webServer>
</configuration>
'@ | Set-Content "$appDir\web.config" -Encoding UTF8

# -----------------------------------------------------------------------
# 7. Create and configure IIS site
# -----------------------------------------------------------------------
Write-Log "Configuring IIS site..."
Import-Module WebAdministration

# Remove default site if present
if (Get-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue) {
    Remove-Website -Name 'Default Web Site'
}

# Create app pool
if (-not (Test-Path "IIS:\AppPools\ecomm-backend")) {
    New-WebAppPool -Name 'ecomm-backend'
    Set-ItemProperty "IIS:\AppPools\ecomm-backend" processModel.identityType LocalSystem
}

# Create website
New-Website -Name 'ecomm-backend' `
    -PhysicalPath $appDir `
    -ApplicationPool 'ecomm-backend' `
    -Port 80 `
    -Force

Write-Log "IIS site 'ecomm-backend' created on port 80."

# -----------------------------------------------------------------------
# 8. Open Windows Firewall for HTTP/HTTPS/RDP
# -----------------------------------------------------------------------
Write-Log "Configuring Windows Firewall..."
New-NetFirewallRule -DisplayName 'Allow HTTP'  -Direction Inbound -Protocol TCP -LocalPort 80  -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Allow HTTPS' -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue

Write-Log "Bootstrap complete. Node.js + IIS + iisnode are ready."
Write-Log "Deploy your app using: az vm run-command invoke ... --scripts @deploy-backend.ps1"
