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
- translation
---
PowerShell 是一个非常有用的语言，可以调用 Web Service 和访问网页。如果您将两者合并成一个动态参数，就能得到一个专业的，支持实时汇率的货币换算器。

Here is the ConvertTo-Euro function that takes values from other currencies and converts them to EUR. The function has the -Currency parameter that is populated dynamically by the currencies supported by the European Central Bank.
以下 `ConvertTo-Euro` 函数可以输入其他货币并转换成欧元。该函数有一个 `-Currency` 参数，并可以动态地传入欧洲中央银行支持的货币。


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
    

The function illustrates how a dynamic parameter can be populated by dynamic data, and how this data is cached so IntelliSense won't trigger a new retrieval all the time.

Here is some sample output you can expect (provided you have Internet access):

     
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
     

 

Throughout this month, we'd like to point you to three awesome community-driven global PowerShell events taking place this year:

Europe: April 20-22: 3-day PowerShell Conference EU in Hannover, Germany, with more than 30+ speakers including Jeffrey Snover and Bruce Payette, and 60+ sessions: [www.psconf.eu](http://www.psconf.eu).

Asia: October 21-22: 2-day PowerShell Conference Asia in Singapore. Watch latest announcements at [www.psconf.asia](http://www.psconf.asia/)

North America: April 4-6: 3-day PowerShell and DevOps Global Summit in Bellevue, WA, USA with 20+ speakers including many PowerShell Team members: [https://eventloom.com/event/home/PSNA16](https://eventloom.com/event/home/PSNA16)

All events have limited seats available so you may want to register early.

<!--more-->
本文国际来源：[Converting Currencies](http://powershell.com/cs/blogs/tips/archive/2016/02/09/converting-currencies.aspx)
