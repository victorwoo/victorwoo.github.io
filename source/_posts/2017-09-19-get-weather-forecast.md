---
layout: post
date: 2017-09-19 00:00:00
title: "PowerShell 技能连载 -获取天气预报"
description: PowerTip of the Day - Get Weather Forecast
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Invoke-WebRequest` 可以轻松地获得网页内容。如果不指定 `–UseBasicParsing` 参数，HTML 内容会被解析成 Internet Explorer DOM。通过这种方法，PowerShell 只需要几行代码就可以获取世界上大多数城市当前的天气预报：

```powershell
$City = 'New York'
$weather = Invoke-WebRequest -Uri "http://wttr.in/$City" 
$text = $weather.ParsedHtml.building.outerText

$text
$text | Out-GridView
```

要注意一些事情：

- `Out-GridView` 只能显示有限行的文本。要查看完整的报告，请将 `$text` 输出到控制台。
- `Invoke-WebRequest` 需要内置的 Windows 浏览器运行和初始化至少一次
- 以上代码是脆弱的：一旦网站作者对页面内容重新布局，脚本可能就不能工作了

<!--本文国际来源：[Get Weather Forecast](http://community.idera.com/powershell/powertips/b/tips/posts/get-weather-forecast)-->
