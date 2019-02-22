---
layout: post
date: 2015-01-26 12:00:00
title: "PowerShell 技能连载 - 用 Cmdlet 来管理 MSI 安装包"
description: PowerTip of the Day - Cmdlets to Manage MSI Packages
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 2.0 及以上版本_

需要管理 MSI 安装包的朋友可以从这个开源项目中受益：[http://psmsi.codeplex.com/](http://psmsi.codeplex.com/)。

只需要下载 PowerShell 模块——它自己包含了一个安装包。请确保在安装它之前对 MSI 文件进行解锁。否则，Windows 可能会拒绝安装它。

不幸的是，这个模块将它自己安装到一个很特殊的地方(AppData\Local\Apps\...)，并且扩展了 `$env:PSModulePath` 环境变量，所以 PowerShell 可以找到这个模块。这是为什么您在安装完模块之后需要重启 PowerShell  的原因，因为 PowerShell 不能自动感知到 `$env:PSModulePath` 发生了改变。

这是获取新的 MSI 相关 cmdlet 的方法：

     
    PS> Get-Command -Module MSI
    
    CommandType     Name                                               ModuleName
    -----------     ----                                               ----------
    Function        Get-MSIComponentState                              MSI
    Function        Get-MSISharedComponentInfo                         MSI
    Function        Install-MSIAdvertisedFeature                       MSI
    Cmdlet          Add-MSISource                                      MSI       
    Cmdlet          Clear-MSISource                                    MSI
    Cmdlet          Edit-MSIPackage                                    MSI
    Cmdlet          Export-MSIPatchXml                                 MSI
    Cmdlet          Get-MSIComponentInfo                               MSI
    Cmdlet          Get-MSIFeatureInfo                                 MSI
    Cmdlet          Get-MSIFileHash                                    MSI
    Cmdlet          Get-MSIFileType                                    MSI
    Cmdlet          Get-MSILoggingPolicy                               MSI
    Cmdlet          Get-MSIPatchInfo                                   MSI
    Cmdlet          Get-MSIPatchSequence                               MSI
    Cmdlet          Get-MSIProductInfo                                 MSI
    Cmdlet          Get-MSIProperty                                    MSI
    Cmdlet          Get-MSIRelatedProductInfo                          MSI
    Cmdlet          Get-MSISource                                      MSI                            
    Cmdlet          Get-MSISummaryInfo                                 MSI
    Cmdlet          Get-MSITable                                       MSI            
    Cmdlet          Install-MSIPatch                                   MSI                    
    Cmdlet          Install-MSIProduct                                 MSI          
    Cmdlet          Measure-MSIProduct                                 MSI                             
    Cmdlet          Remove-MSILoggingPolicy                            MSI
    Cmdlet          Remove-MSISource                                   MSI
    Cmdlet          Repair-MSIProduct                                  MSI
    Cmdlet          Set-MSILoggingPolicy                               MSI                  
    Cmdlet          Test-MSIProduct                                    MSI
    Cmdlet          Uninstall-MSIPatch                                 MSI
    Cmdlet          Uninstall-MSIProduct                               MSI

<!--本文国际来源：[Cmdlets to Manage MSI Packages](http://community.idera.com/powershell/powertips/b/tips/posts/cmdlets-to-manage-msi-packages)-->
