---
layout: post
title: "PowerShell 技能连载 - 批量重命名对象的属性"
date: 2014-05-15 00:00:00
description: PowerTip of the Day - Bulk Renaming Object Properties
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，我们需要批量重命名对象的属性来更好地创建报表。例如，假设您获取了进程对象，你需要您可能需要以新的的列名来创建报表。

以下是一个称为 `Rename-Property` 的过滤器，可以用于重命名任何属性。在例子中，生成了一个进程列表，然后重命名一些属性：

    filter Rename-Property ([Hashtable]$PropertyMapping)
    {
        Foreach ($key in $PropertyMapping.Keys)
        {
            $_ = $_ | Add-Member -MemberType AliasProperty -Name $PropertyMapping.$key -Value $key  -PassThru
        }
        $_
    }

    $newProps = @{
      Company = 'Manufacturer'
      Description = 'Purpose'
      MainWindowTitle = 'TitlebarText'
    }

    # get raw data
    Get-Process |
        # add alias properties as specified in $newProps
        Rename-Property $newProps |
        # select the properties you want to display
        # can be original properties and/or newly added alias properties
        Select-Object -Property Name, Manufacturer, Purpose, TitlebarText

`Rename-Property` 自动加入了 `$newProps` 中指定的所有属性。结果对象中含有名为“Manufacturer”、“Purpose”和“TitlebarText”的新属性。您可以接着使用 `Select-Object` 来选择您想在报表中包含的属性。您可以从原先存在的属性中选择，也可以从新增加的别名属性中选择。

![](/img/2014-05-15-bulk-renaming-object-properties-001.png)

所以本质上上，属性并没有被改名（技术上不可能实现）。实际上，该过滤器以新的名字添加了别名属性，并指向原先的属性。

<!--本文国际来源：[Bulk Renaming Object Properties](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-renaming-object-properties)-->
