---
layout: post
date: 2018-08-06 00:00:00
title: "PowerShell 技能连载 - 使用 PSGraph"
description: PowerTip of the Day - Using PSGraph
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PSGraph 是一个非常棒的免费 PowerShell 库，您可以用它来将关系可视化。在使用 PSGraph 之前，需要安装它的依赖项（graphviz 引擎）。两者都需要管理员特权：

```powershell
#requires -RunAsAdministrator

# install prerequisite (graphviz)
Register-PackageSource -Name Chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2/
Find-Package graphviz | Install-Package -ForceBootstrap

# install PowerShell module
Install-Module -Name PSGraph
```

安装完成后，这是如何将对象关系可视化的代码：

```powershell
$webServers = 'Web1','Web2','web3'
$apiServers = 'api1','api2'
$databaseServers = 'db1'

graph site1 {
    # External/DMZ nodes
    subgraph 0 -Attributes @{label='DMZ'} {
        node 'loadbalancer' @{shape='house'}
        rank $webServers
        node $webServers @{shape='rect'}
        edge 'loadbalancer' $webServers
    }

    subgraph 1 -Attributes @{label='Internal'} {
        # Internal API servers
        rank $apiServers
        node $apiServers   
        edge $webServers -to $apiServers
    
        # Database Servers
        rank $databaseServers
        node $databaseServers @{shape='octagon'}
        edge $apiServers -to $databaseServers
    }    
} | Export-PSGraph -ShowGraph
```

这个例子中创建的图形使用脚本文件中的 hypothetical 服务器并向其添加合适的关系，并显示图像。

<!--more-->
本文国际来源：[Using PSGraph](http://community.idera.com/powershell/powertips/b/tips/posts/using-psgraph)
