---
layout: post
date: 2016-02-09 12:00:00
title: "PowerShell 技能连载 - 换算货币"
description: PowerTip of the Day - Converting Currencies
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是一个非常有用的语言，可以调用 Web Service 和访问网页。如果您将两者合并成一个动态参数，就能得到一个专业的，支持实时汇率的货币换算器。

以下 `ConvertTo-Euro` 函数可以输入其他货币并转换成欧元。该函数有一个 `-Currency` 参数，并可以动态地传入欧洲中央银行支持的货币。

```powershell
    function ConvertTo-Euro
    {
      [CmdletBinding()]
      param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Double]
        $Value
      )

      dynamicparam
      {
        $Bucket = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        $Attributes = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribParameter = New-Object System.Management.Automation.ParameterAttribute
        $AttribParameter.Mandatory = $true
        $Attributes.Add($AttribParameter)

        if ($script:currencies -eq $null)
        {
          $url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
          $result = Invoke-RestMethod  -Uri $url
          $script:currencies = $result.Envelope.Cube.Cube.Cube.currency
        }

        $AttribValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($script:currencies)
        $Attributes.Add($AttribValidateSet)

        $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter('Currency',[String], $Attributes)
        $Bucket.Add('Currency', $Parameter)

        $Bucket
      }

      begin
      {
        foreach ($key in $PSBoundParameters.Keys)
        {
          if ($MyInvocation.MyCommand.Parameters.$key.isDynamic)
          {
            Set-Variable -Name $key -Value $PSBoundParameters.$key
          }
        }

        $url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
        $rates = Invoke-RestMethod  -Uri $url
        $rate = $rates.Envelope.Cube.Cube.Cube |
        Where-Object { $_.currency -eq $Currency} |
        Select-Object -ExpandProperty Rate
      }

      process
      {
        $result = [Ordered]@{
          Value = $Value
          Currency = $Currency
          Rate = $rate
          Euro = ($Value / $rate)
          Date = Get-Date
        }

        New-Object -TypeName PSObject -Property $result
      }
    }
```

该函数演示了如何向动态参数填充动态数据，以及该数据如何缓存以免智能感知每次触发一个新的请求过程。


以下使一些您可能期待的例子（需要 Internet 连接）：

    PS C:\> 100, 66.9 | ConvertTo-Euro -Currency DKK

    Value    : 100
    Currency : DKK
    Rate     : 7.4622
    Euro     : 13,4008737369677
    Date     : 26.01.2016 21:32:44

    Value    : 66,9
    Currency : DKK
    Rate     : 7.4622
    Euro     : 8,96518453003136
    Date     : 26.01.2016 21:32:45



    PS C:\>  ConvertTo-Euro -Currency USD -Value 99.78

    Value    : 99,78
    Currency : USD
    Rate     : 1.0837
    Euro     : 92,0734520623789
    Date     : 26.01.2016 21:33:01

<!--本文国际来源：[Converting Currencies](http://community.idera.com/powershell/powertips/b/tips/posts/converting-currencies)-->
