layout: post
date: 2015-03-30 11:00:00
title: "PowerShell 技能连载 - 访问非 Microsoft LDAP 服务"
description: PowerTip of the Day - Accessing Non-Microsoft LDAP Servers
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
_适用于 PowerShell 所有版本_

Microsoft 和 Dell 提供了一些 Active Directory 的免费 cmdlet，分别是 RSAT 工具和 Quest 的一部分。它们使访问域控制器变得更简单。

要访问一个非 Microsoft 的 LDAP 服务器，由于没有现成的 cmdlet，所以可以使用 .NET 框架的功能。

以下是一些示例代码，演示了如何连接这种 LDAP 服务器，提交 LDAP 查询，并且获取信息。

该脚本假设 LDAP 服务器架设在 192.168.1.1 的 389 端口，是“mycompany.com”域的一部分，有一个名为“SomeGroup”的工作组。该脚本列出该工作组的用户账户：

    $LDAPDirectoryService = '192.168.1.1:389'
    $DomainDN = 'dc=mycompany,dc=com'
    $LDAPFilter = '(&(cn=SomeGroup))'
    
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('System.DirectoryServices.Protocols')
    $null = [System.Reflection.Assembly]::LoadWithPartialName('System.Net')
    $LDAPServer = New-Object System.DirectoryServices.Protocols.LdapConnection $LDAPDirectoryService
    $LDAPServer.AuthType = [System.DirectoryServices.Protocols.AuthType]::Anonymous
    
    $LDAPServer.SessionOptions.ProtocolVersion = 3
    $LDAPServer.SessionOptions.SecureSocketLayer =$false
     
    $Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
    $AttributeList = @('*')
    
    $SearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest -ArgumentList $DomainDN,$LDAPFilter,$Scope,$AttributeList
    
    $groups = $LDAPServer.SendRequest($SearchRequest)
    
    foreach ($group in $groups.Entries) 
    {
      $users=$group.attributes['memberUid'].GetValues('string')
      foreach ($user in $users) {
        Write-Host $user
      }
    }

<!--more-->
本文国际来源：[Accessing Non-Microsoft LDAP Servers](http://powershell.com/cs/blogs/tips/archive/2015/03/30/accessing-non-microsoft-ldap-servers.aspx)
