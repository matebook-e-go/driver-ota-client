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

For bootstrapping installation media, use [drivers for ThinkPad X13s](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-x-series-laptops/thinkpad-x13s-type-21bx-21by/downloads/driver-list/component?name=Power%20Management&id=E1B533C3-16CA-4FBE-8BD8-FB5D7A57F431)

## After installation

Use a USB network adapter to get online and install drivers from Windows Update.

For touch screen support, run `Get-DriverUpdates.ps1` and install `THP_Software` manually.
