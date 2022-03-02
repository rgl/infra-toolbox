#!/bin/bash
source /vagrant/lib.sh

# install the powercli powershell module.
# see https://www.powershellgallery.com/packages/VMware.PowerCLI
# see https://developer.vmware.com/web/tool/12.5/vmware-powercli
pwsh -NonInteractive -File /dev/stdin <<'EOF'
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Output (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}
Write-Output 'Installing the VMware.PowerCLI module...'
Install-Module -Force -Scope AllUsers `
    -Name VMware.PowerCLI `
    -RequiredVersion 12.5.0.19195797
Write-Output 'Configuring the VMware.PowerCLI module...'
Set-PowerCLIConfiguration -Scope AllUsers `
    -ParticipateInCEIP $false `
    -Confirm:$false `
    | Out-Null
EOF
