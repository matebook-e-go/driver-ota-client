## Usage

```
NAME
    Get-DriverUpdates

SYNOPSIS
    Check for driver updates for Huawei MateBook E Go devices.

SYNTAX
    .\Get-DriverUpdates [-SendCurrentVersion] [-SendDeviceId]
    [<CommonParameters>]

PARAMETERS
    -SendCurrentVersion
        Sends the current installed driver version to server. Some drivers are 
        only offered if a valid previous version is installed.

    -SendDeviceId
        Sends the device serial number to server. Firmware updates may be 
        offered to some batch of devices only.

```

## Bootstrapping

For bootstrapping installation media, use [drivers for ThinkPad X13s](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-x-series-laptops/thinkpad-x13s-type-21bx-21by/downloads/ds556993-sccm-package-for-windows-pe-11-thinkpad-x13s?category=Enterprise%20Management)

## After installation

Use a USB network adapter to get online and install drivers from Windows Update.

For touch screen support, run `Get-DriverUpdates.ps1` and install `THP_Software` manually.
