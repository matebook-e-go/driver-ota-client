<#
    .SYNOPSIS
    Check for driver updates for Huawei MateBook E Go devices.

    .PARAMETER SendCurrentVersion
    Sends the current installed driver version to server. Some drivers are only offered if a valid previous version is installed.

    .PARAMETER SendDeviceId
    Sends the device serial number to server. Firmware updates may be offered to some batch of devices only.
#>
param(
  [switch]$SendCurrentVersion,
  [switch]$SendDeviceId
)

$ErrorActionPreference = "Stop"

$productName = (Get-CimInstance -ClassName Win32_BaseBoard).Product
$wmiBios = Get-WmiObject -Class Win32_BIOS

if ($SendDeviceId) {
  $deviceId = $wmiBios.SerialNumber
}
else {
  $deviceId = "AAAAAAAAAAAAAAAA"
}

$defaultrules = @{
  C_version      = "C233";
  Dashboard      = "MateBookManager:13.0.3.366(C233);$($driverlist.version);";
  DashboardFlash = "13.0.3.366(C233)";
  DeviceName     = "GaoKun";
  FirmWare       = "";
  Language       = "en-US";
  OS             = "Windows 10 Enterprise-ni_release-22621-1848";
  deviceId       = $deviceId;
  extra_info     = "";
  saleinfo       = "|||||||||";
  udid           = "0000000000000000000000000000000000000000000000000000000000000000";
}

$pnpdevs = Get-PnpDevice -Status OK

function findDevice([string]$hwids) {
  $hwidsa = $hwids -split ";"
  foreach ($dev in $pnpdevs) {
    foreach ($hwid in $hwidsa) {
      if ($dev.HardwareID -like "*$hwid*") {
        return $dev
      }
    }
  }
  return $null
}

$listdiscovery = Invoke-RestMethod "http://update-drcn.platform.hicloud.com/hid_and_common/v2/CheckEx.action?latest=true&verType=true&defenceHijack=true" -UseBasicParsing -Method POST -ContentType "application/x-www-form-urlencoded" -Body @"
{
    "components": [
        {
            "AppName": "DriverListServer",
            "PackageName": "DriverListServer",
            "PackageType": $($productName | ConvertTo-Json -Compress),
            "PackageVersionCode": "1.0.0.0",
            "PackageVersionName": "13.0.3.366(C233)",
            "componentID": "94"
        }
    ],
    "rules": {
        "C_version": "C233",
        "Dashboard": "MateBookManager:13.0.3.366(C233);DriverListServer:1.0.0.0;",
        "DashboardFlash": "13.0.3.366(C233)",
        "DeviceName": "GaoKun",
        "FirmWare": "",
        "Language": "en-US",
        "OS": "Windows 10 Enterprise-ni_release-22621-1848",
        "deviceId": $($deviceId | ConvertTo-Json -Compress),
        "extra_info": "",
        "saleinfo": "|||||||||",
        "udid": "0000000000000000000000000000000000000000000000000000000000000000"
    }
}
"@

$listresp = Invoke-WebRequest -UseBasicParsing ($listdiscovery.components[0].url + "full/DriverListServer.xml")

try {
  $listxml = [xml]$listresp.Content
}
catch {
  $listxml = [xml]$listresp.Content.Replace("&", "&amp;")
}

if ($SendCurrentVersion) {
  Import-Module "$PSScriptRoot\MCUGetVersion\MCUGetVersion.psm1"
  Start-MCUVersionBroker
  trap { Stop-MCUVersionBroker; throw $_ }
}

$driverlist = $listxml.driverlist
# $drvlist_title = "$($driverlist.device)-$($driverlist.version)"
$components = [System.Collections.ArrayList]::new()
$id2name = @{}
foreach ($drv in $driverlist.GaoKun.driver) {
  $result = @{
    AppName            = $drv.appname;
    PackageName        = $drv.packagename;
    PackageType        = "";
    PackageVersionCode = $null;
    PackageVersionName = "13.0.3.366(C233)";
    componentID        = $drv.id;
  }
  $id2name[$drv.id] = $drv.appname
  if ($drv.pkgTypeNeedReport -eq "productName") {
    $result.PackageType = "GK-W7X-PCB";
  }
  if ($null -ne $drv.hwid) {
    $dev = findDevice($drv.hwid)
    if ($SendCurrentVersion -and $null -ne $dev) {
      $result.PackageVersionCode = ($dev | Get-PnpDeviceProperty -KeyName DEVPKEY_Device_DriverVersion).Data
    }
    if ($null -eq $dev) {
      continue
    }
  }
  if ($SendCurrentVersion) {
    if ($null -ne $drv.regpath) {
      try {
        $arr = $drv.regpath.Split(";", 2)
        $key = $arr[0]
        $value = $arr[1]
        $result.PackageVersionCode = Get-ItemProperty -Path "HKLM:\$key" -Name $value | Select-Object -ExpandProperty $value
      }
      catch [System.Exception] {}
    }
    elseif ("BIOS" -eq $drv.appname) {
      $result.PackageVersionCode = (Get-WmiObject -Class Win32_BIOS).SMBIOSBIOSVersion
    }
    elseif ("InteractInfoWithMCU" -eq $drv.dllName) {
      $result.PackageVersionCode = Get-MCUDriverVersion $drv.appname
    }
  }
  if ($null -eq $result.PackageVersionCode) {
    if ($null -ne $drv.default) {
      $result.PackageVersionCode = $drv.default
    }
    else {
      $result.PackageVersionCode = "1.0.0.0"
    }
  }
  $components += $result
}

if ($SendCurrentVersion) {
  try {
    Stop-MCUVersionBroker
  }
  catch {}
}

$reqbody = @{
  components = $components;
  rules      = $defaultrules;
}

$driversmanifest = Invoke-RestMethod "http://update-drcn.platform.hicloud.com/hid_and_common/v2/CheckEx.action?latest=fa&verType=true&defenceHijack=true" -UseBasicParsing -Method POST -ContentType "application/x-www-form-urlencoded" -Body (ConvertTo-Json -Compress $reqbody)

if ($driversmanifest.status -eq 0) {
  $pkgs = [System.Collections.ArrayList]::new()

  foreach ($c in $driversmanifest.components) {
    [void]$pkgs.Add([pscustomobject]@{
        PackageName = $id2name[$c.componentID.ToString()];
        Version     = $c.version;
        Date        = [datetime]$c.createTime;
        Url         = $c.url + "full/update.zip";
      })
  }
  $pkgs | Sort-Object -Property Date -Descending | Format-List | Out-String -Width 114514
}
