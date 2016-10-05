layout: post
title: "PowerShell 技能连载 - 自动连接到公共热点"
date: 2014-03-07 00:00:00
description: PowerTip of the Day - Auto-Connecting with Public Hotspot
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
许多手机服务提供商在机场和公共场所提供公共热点。要连接热点，您往往需要浏览一个登录页面，然后手动输入您的凭据。

以下是一个自动做以上事情的脚本。它在 t-mobile.de 运营商环境下调是通过。但是您可以调整脚本以适应其它的运营商。

    function Start-Hotspot
    {
      param
      (
        [System.String]
        $Username = 'XYZ@t-mobile.de',
        
        [System.String]
        $Password = 'topsecret'
      )
      
      # change this to match your provider logon page URL
      $url = 'https://hotspot.t-mobile.net/wlan/start.do'
    
      $r = Invoke-WebRequest -Uri $url -SessionVariable fb   
      
      $form = $r.Forms[0]
      
      # change this to match the website form field names:
      $form.Fields['username'] = $Username
      $form.Fields['password'] = $Password
      
      # change this to match the form target URL
      $r = Invoke-WebRequest -Uri ('https://hotspot.t-mobile.net' + $form.Action) -WebSession $fb -Method POST -Body $form.Fields
      Write-Host 'Connected' -ForegroundColor Green
      Start-Process 'http://www.google.de' 
    } 

简而言之，`Invoke-WebRequest` 可以到导航到一个页面，填充表单数据，然后提交表单。要能提交正确的数据，您需要查看登录网页的的源代码（导航到该页面，在浏览器中右键单击选择显示 HTML 源代码）。

然后，识别出您希望填充的表单，然后将脚本代码中的表单名称和动作改为您从 HTML 代码中识别出来的值。

<!--more-->
本文国际来源：[Auto-Connecting with Public Hotspot](http://community.idera.com/powershell/powertips/b/tips/posts/auto-connecting-with-public-hotspot)
