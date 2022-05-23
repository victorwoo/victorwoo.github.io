---
layout: post
date: 2022-05-06 00:00:00
title: "PowerShell 技能连载 - 管理蓝牙设备（第 2 部分）"
description: PowerTip of the Day - Managing Bluetooth Devices (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想通过编程方式删除配对的蓝牙设备，则没有内置的 cmdlet。 PowerShell 仍然可以解决问题，甚至通常可以解除配对无法通过 UI 删除或不断重复出现的蓝牙设备。

您需要首先删除蓝牙设备的硬件地址。 这是有关如何列出所有蓝牙设备并返回其硬件地址的示例：

```powershell
$Address =     @{
    Name='Address'
Expression={$_.HardwareID | 
ForEach-Object { [uInt64]('0x' + $_.Substring(12))}}
}

Get-PnpDevice -Class Bluetooth |
    Where-Object HardwareID -match 'DEV_' |
    Select-Object FriendlyName, $Address |
    Where-Object Address |
    Out-GridView -Title 'Select Bluetooth Device to Remove' -OutputMode Single
```

结果看起来类似这样，并在网格视图窗口中显示，您可以在其中选择一个蓝牙设备：

    FriendlyName                               Address
    ------------                               -------
    Bamboo Ink Plus                       480816531482
    SMA001d SN: 2110109033 SN2110109033   550378395892
    MX Master 3                            20919489792
    MX Keys                              1089715743697
    Bose QC35 II                        44056255752152   

附带说明，该代码说明了一个简单的技巧，可以以编程方式将十六进制数字转换为十进制：

```powershell
PS> $hex = 'A0FD'

PS> [int]"0x$hex"
41213
```

一旦知道要解除配对的蓝牙设备的硬件地址，接下来，您必须将其传给一个内部的 Windows API。内部方法 `Bluetoothremavyevice()` 将其删除。 下面的代码灵感来自 Keith A. Miller 在 Microsoft 论坛中提供的建议。

以下是一个包装内部 Windows API 签名的函数，它输入一个硬件地址，然后解绑设备：

```powershell
function Unpair-Bluetooth
{
    # take a UInt64 either directly or as part of an object with a property
    # named "DeviceAddress" or "Address"
    param
    (
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Address')]
        [UInt64]
        $DeviceAddress
    )

    # tell PowerShell the location of the internal Windows API
    # and define a static helper function named "Unpair" that takes care
    # of creating the needed arguments:
    begin
    {
        Add-Type -Namespace "Devices" -Name 'Bluetooth' -MemberDefinition '
[DllImport("BluetoothAPIs.dll", SetLastError = true, CallingConvention = CallingConvention.StdCall)]
[return: MarshalAs(UnmanagedType.U4)]
static extern UInt32 BluetoothRemoveDevice(IntPtr pAddress);
public static UInt32 Unpair(UInt64 BTAddress) {
    GCHandle pinnedAddr = GCHandle.Alloc(BTAddress, GCHandleType.Pinned);
    IntPtr pAddress     = pinnedAddr.AddrOfPinnedObject();
    UInt32 result       = BluetoothRemoveDevice(pAddress);
    pinnedAddr.Free();
    return result;
}'
    }

    # do this for every object that was piped into this function:
    process
    {
        $result = [Devices.Bluetooth]::Unpair($DeviceAddress)
        [PSCustomObject]@{
            Success = $result -eq 0
            ReturnValue = $result
        }
    }
}
```

由于新函数 `Unpair-Bluetooth` 是支持管道的，因此您可以将其附加到以前的代码之后即可解除蓝牙配对：

```powershell
$Address =     @{
    Name='Address'
Expression={$_.HardwareID | 
ForEach-Object { [uInt64]('0x' + $_.Substring(12))}}
}

Get-PnpDevice -Class Bluetooth |
    Where-Object HardwareID -match 'DEV_' |
    Select-Object FriendlyName, $Address |
    Where-Object Address |
    Out-GridView -Title 'Select Bluetooth Device to Unpair' -OutputMode Single |
    Unpair-Bluetooth
```

运行代码时，它再次显示所有蓝牙设备。选择一个要解除配对的设备，然后点击网格视图窗口右下角的确定。请注意，如果设备不是“记住的设备”，则解除配对会失败。当解除配对成功时，返回值为 0，并将设备从蓝牙设备列表中删除。

<!--本文国际来源：[Managing Bluetooth Devices (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-bluetooth-devices-part-3)-->

