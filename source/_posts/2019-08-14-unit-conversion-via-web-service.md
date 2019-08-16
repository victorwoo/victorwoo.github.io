---
layout: post
date: 2019-08-14 00:00:00
title: "PowerShell 技能连载 - 通过 Web Service 做单位转换"
description: PowerTip of the Day - Unit Conversion via Web Service
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过 PowerShell 访问 RESTful Web Service 十分容易：只需要将您的发送数据发给公开的 Web Service，并且接收结果即可。

以下是三个 PowerShell 函数，每个函数处理一个数字转换：

```powershell
function Convert-InchToCentimeter
{
  param
  (
    [Parameter(Mandatory)]
    [Double]
    $Inch
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $url = 'https://ucum.nlm.nih.gov/ucum-service/v1/ucumtransform/{0}/from/%5Bin_i%5D/to/cm' -f $Inch
  $result = Invoke-RestMethod -Uri $url -UseBasicParsing
  $result.UCUMWebServiceResponse.Response
}


function Convert-FootToMicrometer
{
  param
  (
    [Parameter(Mandatory)]
    [Double]
    $Foot
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $url = 'https://ucum.nlm.nih.gov/ucum-service/v1/ucumtransform/{0}/from/%5Bft_i%5D/to/um' -f $Foot
  $result = Invoke-RestMethod -Uri $url -UseBasicParsing
  $result.UCUMWebServiceResponse.Response
}


function Convert-GramToOunce
{
  param
  (
    [Parameter(Mandatory)]
    [Double]
    $Gram
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $url = 'https://ucum.nlm.nih.gov/ucum-service/v1/ucumtransform/{0}/from/g/to/%5Boz_ap%5D' -f $Gram
  $result = Invoke-RestMethod -Uri $url -UseBasicParsing
  $result.UCUMWebServiceResponse.Response
}
```

假设您有 Internet 连接，然后做单位换算就是一个函数调用那么简单了：

```PowerShell
PS C:\> Convert-GramToOunce -Gram 230

SourceQuantity SourceUnit TargetUnit ResultQuantity
-------------- ---------- ---------- --------------
230.0          g          [oz_ap]    7.3946717
```

需要注意的点有：

* 您需要允许 Tls12 来允许 HTTPS 连接（参考代码）
* 您需要遵守 Web Service 规定的规则，即当它需要整个数数时，您不能提交小数。

更多的转换功能请参考 [https://ucum.nlm.nih.gov/ucum-service.html#conversion](https://ucum.nlm.nih.gov/ucum-service.html#conversion)，您可以使用以上提供的函数作为模板来创建更多的转换函数。

<!--本文国际来源：[Unit Conversion via Web Service](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/unit-conversion-via-web-service)-->

