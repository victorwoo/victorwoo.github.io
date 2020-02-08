---
layout: post
date: 2019-11-04 00:00:00
title: "PowerShell 技能连载 - WMI 浏览器"
description: PowerTip of the Day - WMI Explorer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI（Windows管理规范）是一个很好的信息来源：几乎可以在其中找到有关计算机的任何信息。困难的部分不是 WMI 查询本身。困难的部分是找出适当的 WMI 类名称和属性：

例如，要获取您 BIOS 的信息，请运行以下代码：

```powershell
PS> Get-CimInstance -ClassName Win32_BIOS


SMBIOSBIOSVersion : 1.0.9
Manufacturer      : Dell Inc.
Name              : 1.0.9
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001
```

获取其他信息只需要替换您要查询的类名。因此，例如要获取有关您的操作系统的信息，请运行以下命令：

```powershell
PS> Get-CimInstance -ClassName Win32_OperatingSystem


SystemDirectory : C:\Windows\system32
Organization    :
BuildNumber     : 18362
RegisteredUser  : tobias.weltner@email.de
SerialNumber    : 00330-50000-00000-AAOEM
Version         : 10.0.18362
```

为了找到任何信息并找到合适的 WMI 类名称，我们创建了一个智能的 "`WMI Explorer`"，它实际上只是一个简单的功能。它需要Windows PowerShell (PowerShell 3-5):

```powershell
function Find-WmiClass
{
  # show all properties, not just 4
  $oldLimit = $FormatEnumerationLimit
  $global:FormatEnumerationLimit = -1
  # list all WMI classes...
  Get-WmiObject -Class * -List |
  # ...with at least 4 properties
  Where-Object { $_.Properties.Count -gt 4 } |
  # let the user select one
  Out-GridView -Title 'Select a class that seems interesting' -OutputMode Single |
  ForEach-Object {
    # query the selected class
    $Name = $_.name
    $props = Get-WmiObject -Class $Name |
    # take the first instance
    Select-Object -Property * -First 1 |
    ForEach-Object {
      # turn the object into a hash table, and exclude empty properties
      $_ | & {
              $_.PSObject.Properties |
        Sort-Object -Property Name |
        Where-Object { $_.Value -ne $null } |
        ForEach-Object {
            $hashtable = [Ordered]@{}} { $hashtable[$_.Name] = $_.Value } { $hashtable }
        } |
        # show the properties and let the user select
        Out-GridView -Title "$name : Select all properties you need (hold CTRL)" -PassThru |
        ForEach-Object {
          # return the selected property names
          $_.Name
        }
    }
    # take all selected properties
    $prop = $props -join ', '
    # create the command for it:
    $a = "Get-CimInstance -Class $Name | Select-Object -Property $prop"
    # place it into the clipboard
    $a | Set-Clipboard
    Write-Warning "Command is also available from the clipboard"
    $a
  }
  # reset format limit
  $global:FormatEnumerationLimit = $oldLimit
}
```

以下是它的工作原理：

* 运行上面的代码，将添加一个名为 `Find-WmiClass` 的新命令
* 运行 `Find-WmiClass` 以执行该函数
* 将打开一个网格视图窗口，并显示标准命名空间 root\cimv2 中所有可用的 WMI 类（如果要搜索其他命名空间，请调整代码并将`-Namespace 参数添加到 Get-WmiObject 调用中）
* 现在，在网格视图窗口的顶部文本字段中输入您要查找的内容，它就像一个过滤器。例如，如果输入 UserName，则网格视图会将列表限制为名称或任何属性名称中任何位置具有 "UserName" 的所有类。过滤后只有几个类可供选择。
* 选择要调查的类，例如 "Win32_ComputerSystem"，然后单击网格右下角的“确定”按钮。
* 现在查询选定的类，并且它的第一个实例显示在另一个网格视图中。每个属性都显示在其自己的行上，因此您可以再次过滤显示。按住 CTRL 键选择要保留的所有属性。然后再次单击确定。
* 将在控制台中显示创建的命令。它还位于剪贴板中。因此要测试命令的话，请按 CTRL + V，然后按 Enter。

感谢 `Find-WmiClass` 命令，探索 WMI 并找到有用的 WMI 类和属性变得非常容易。

<!--本文国际来源：[WMI Explorer](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/wmi-explorer)-->

