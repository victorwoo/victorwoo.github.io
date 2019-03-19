---
layout: post
date: 2018-07-10 00:00:00
title: "PowerShell 技能连载 - 从函数中返回富对象（第 2 部分）"
description: PowerTip of the Day - Returning Rich Objects from Functions (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个函数返回多于四个属性时，PowerShell 将输出结果格式化为列表，否则格式化为表格。在您学习新的方法来影响这种行为之前，请自己验证一下。以下函数返回一个多于 6 个属性的对象：

```powershell
function Get-TestData
{
    # if a function is to return more than one information kind,
    # wrap it in a custom object

    [PSCustomObject]@{
        # wrap anything you'd like to return
        ID = 1
        Random = Get-Random
        Date = Get-Date
        Text = 'Hello'
        BIOS = Get-WmiObject -Class Win32_BIOS
        User = $env:username
    }
}
```

结果是以表格形式呈现：

```powershell
PS> Get-TestData


ID     : 1
Random : 147704985
Date   : 25.05.2018 13:09:26
Text   : Hello
BIOS   : \\DESKTOP-7AAMJLF\root\cimv2:Win32_BIOS.Name="1.6.1",SoftwareElementID="1.6.1",SoftwareElementState=3,TargetOperatingSys
            tem=0,Version="DELL   - 1072009"
User   : tobwe
```

当移除掉一些属性，限制属性个数为 4 个或更少时，PowerShell 输出一个表格：

```powershell
PS> Get-TestData

ID    Random Text  User
--    ------ ----  ----
    1 567248729 Hello tobwe
```

通常，表格的形式比较容易阅读，特别是有多个数据集的时候。当您得到一个 4 个或更少属性的表格时，您可能不是始终希望返回值只有 4 个属性。所以为什么不像类似 cmdlet 一样处理它呢？

Cmdlet 默认情况下只显示属性的一部分：

```powershell
PS> Get-Service | Select-Object -First 1

Status   Name               DisplayName
------   ----               -----------
Running  AdobeARMservice    Adobe Acrobat Update Service
```

使用 `Select-Object` 可以显示地获得所有属性的列表：

```powershell
PS> Get-Service | Select-Object -First 1 -Property *


Name                : AdobeARMservice
RequiredServices    : {}
CanPauseAndContinue : False
CanShutdown         : False
CanStop             : True
DisplayName         : Adobe Acrobat Update Service
DependentServices   : {}
MachineName         : .
ServiceName         : AdobeARMservice
ServicesDependedOn  : {}
ServiceHandle       :
Status              : Running
ServiceType         : Win32OwnProcess
StartType           : Automatic
Site                :
Container
```

显然，有第一公民和第二公民之分。在您自己的函数中，您可以类似这样定义第一公民：

```powershell
function Get-TestData
{
    # define the first-class citizen
    [string[]]$visible = 'ID','Date','User'
    $info = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',$visible)


    [PSCustomObject]@{
        # wrap anything you'd like to return
        ID = 1
        Random = Get-Random
        Date = Get-Date
        Text = 'Hello'
        BIOS = Get-WmiObject -Class Win32_BIOS
        User = $env:username
    } |
    # add the first-class citizen info to your object
    Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $info -PassThru

}
```

现在，您的函数的行为类似 cmdlet，而且您没有定义多于 4 个一等公民，所以缺省情况下得到一个表格的形式：

```powershell
PS> Get-TestData

ID Date                User
-- ----                ----
    1 25.05.2018 13:15:15 tobwe



PS> Get-TestData | Select-Object -Property *


ID     : 1
Random : 1298877814
Date   : 25.05.2018 13:15:22
Text   : Hello
BIOS   : \\DESKTOP-7AAMJLF\root\cimv2:Win32_BIOS.Name="1.6.1",SoftwareElementID="1.6.1",SoftwareElementState=3,TargetOperatingSys
            tem=0,Version="DELL   - 1072009"
User   : tobwe
```

<!--本文国际来源：[Returning Rich Objects from Functions (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/returning-rich-objects-from-functions-part-2)-->
