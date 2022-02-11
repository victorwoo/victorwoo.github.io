---
layout: post
date: 2022-02-01 00:00:00
title: "PowerShell 技能连载 - 查看所有模块的细节"
description: PowerTip of the Day - View All Module Details
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
powershellgallery.com 是找到新的免费 PowerShell 扩展模块的好地方，可以为您的 PowerShell 添加新的 cmdlet。

但是，在 Web 界面中查看所有模块详细信息可能会有点麻烦。这就是为什么通过 RESTful WebService 检索模块信息可能会有所帮助。

这是一个脚本，它传入 PowerShell Gallery 中托管的（任何）模块的名称。然后，它检索所有详细信息（例如版本历史记录、下载计数、更新日期和发行说明），并以一种使信息易于访问的方式准备它们。特别是，将检索到的基于 XML 的信息转换为简单对象：

```powershell
# replace module name with any module name hosted
# in the PowerShell Gallery (https://powershellgallery.com)
$ModuleName = 'MicrosoftTeams'

$baseUrl = 'https://www.powershellgallery.com/api/v2/FindPackagesById()?id='
$escaped = [Uri]::EscapeDataString("'$ModuleName'")
$url = $baseUrl + $escaped

# properties to exclude (add or remove as needed)
$blacklist = 'FileList', 'Tags'

$data = Invoke-RestMethod -Uri $url -UseBasicParsing |
ForEach-Object {
  $hash = [Ordered]@{}
  $moduleInfo = $_.Properties
  foreach($_ in $moduleInfo.PSObject.Properties)
  {
    # name of property
    $name = $_.Name
    # if it is in blacklist, skip and continue with next property
    if ($name -in $blacklist) { continue }
# if it is the property "name", then skip
# all remaining (xml default properties)
    if ($name -eq 'Name') { break }

    # if type is "xmlelement", retrieve underlying text value in #text
    if ($_.TypeNameOfValue -eq 'System.Xml.XmlElement')
    {
      $hash[$name] = $moduleInfo.$name.'#text'

      # if a datatype is assigned, try and convert to appropriate type
      if ($moduleInfo.$name.type -like 'Edm.*')
      {
        $typename = $moduleInfo.$name.type.replace('Edm.','')
        $hash[$name] = $hash[$name] -as $typename
      }
    }
    else
    {
      $hash[$name] = $_.Value
    }
  }

  # convert a hash table to object and return it
  [PSCustomObject]$hash
}

$data | Out-GridView
```

<!--本文国际来源：[View All Module Details](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/view-all-module-details)-->

