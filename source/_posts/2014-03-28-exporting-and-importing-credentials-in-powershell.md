layout: post
title: "PowerShell 技能连载 - 用 PowerShell 导入导出凭据"
date: 2014-03-28 00:00:00
description: PowerTip of the Day - Exporting and Importing Credentials in PowerShell
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
凭据对象包含了用户名和密码。您可以用 `Get-Credential` 来创建它们，然后将该对象传递给任何包含 `-Credential` 参数的 cmdlet。

然而，您要怎么做才能不需要用户干预，并且确保安全呢？您不希望弹出一个凭据对话框，并且您不希望在脚本中保存密码信息的话。

以下是一个解决方案：使用 `Export-Credential` 函数将凭据保存到一个文件中：

    function Export-Credential 
    {
       param
       (
         [Parameter(Mandatory=$true)]
         $Path,
    
         [System.Management.Automation.Credential()]
         [Parameter(Mandatory=$true)]
         $Credential
       )
        
      $CredentialCopy = $Credential | Select-Object *    
      $CredentialCopy.Password = $CredentialCopy.Password | ConvertFrom-SecureString    
      $CredentialCopy | Export-Clixml $Path
    } 
    
这段代码将 tobias 用户的凭据保存到一个文件中：

![](/img/2014-03-28-exporting-and-importing-credentials-in-powershell-001.png)

请注意当您进行这步操作时，将弹出凭据对话框并以安全的方式询问您的密码。该输出的文件包含 XML，并且密码是加密的。

现在，当您需要凭据时，使用 `Import-Credential` 来从文件中取回它：

    function Import-Credential 
    {
       param
       (
         [Parameter(Mandatory=$true)]
         $Path
       )
        
      $CredentialCopy = Import-Clixml $path    
      $CredentialCopy.password = $CredentialCopy.Password | ConvertTo-SecureString    
      New-Object system.Management.Automation.PSCredential($CredentialCopy.username, $CredentialCopy.password)
    }
    
使用方法如下：

![](/img/2014-03-28-exporting-and-importing-credentials-in-powershell-002.png)

加密解密的“奥秘”在于您的身份，所以只有您（导出凭据的用户）可以将它再次导入。无需在您的脚本中硬编码隐私信息。

<!--more-->
本文国际来源：[Exporting and Importing Credentials in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/exporting-and-importing-credentials-in-powershell)
