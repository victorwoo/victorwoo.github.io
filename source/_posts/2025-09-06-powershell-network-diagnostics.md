---
layout: post
date: 2025-09-06 08:00:00
updated: 2025-09-06 08:00:00
title: "PowerShell 技能连载 - 网络诊断工具"
description: PowerTip of the Day - Network Diagnostics Tools in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- network
- diagnostics
- troubleshooting
---

_适用于 PowerShell 5.1 及以上版本_

在日常运维中，网络问题往往是最难定位的一类故障。接口掉线、带宽异常、HTTP 响应变慢——这些问题如果不能快速发现并定位，就会影响业务连续性。传统的图形化网络工具虽然直观，但难以批量执行和自动化巡检。

PowerShell 提供了全面的网络诊断能力：从网卡状态检测、HTTP 请求质量测量，到延迟丢包统计和实时流量监控，都可以通过脚本完成。更重要的是，这些脚本可以集成到定时任务或 CI/CD 流水线中，实现网络健康状态的持续观测。

本文将围绕四个实用场景，介绍如何用 PowerShell 构建一套轻量但实用的网络诊断工具集。

## 网络接口健康检查

首先，了解本机网卡的基本状态是排查网络问题的第一步。下面的脚本汇总所有活跃网卡的 IP 地址、链路状态、速率和已发送/接收的字节数，帮助你快速判断网络接口层是否正常。

```powershell
function Get-NetworkInterfaceHealth {
    <#
    .SYNOPSIS
    获取本机所有活跃网络接口的健康状态
    #>

    $adapters = Get-NetAdapter |
        Where-Object { $_.Status -eq 'Up' -and $_.InterfaceType -notmatch 'Loopback' }

    $results = foreach ($adapter in $adapters) {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv2 -ErrorAction SilentlyContinue |
            Select-Object -First 1

        $stats = Get-NetAdapterStatistics -Name $adapter.Name -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            名称       = $adapter.Name
            接口描述   = $adapter.InterfaceDescription
            链路速率   = "$($adapter.LinkSpeed)"
            IPv4地址   = if ($ipConfig) { $ipConfig.IPAddress } else { '未分配' }
            已接收字节 = if ($stats) { '{0:N2} GB' -f ($stats.ReceivedBytes / 1GB) } else { 'N/A' }
            已发送字节 = if ($stats) { '{0:N2} GB' -f ($stats.SentBytes / 1GB) } else { 'N/A' }
            MAC地址    = $adapter.MacAddress
        }
    }

    $results | Format-Table -AutoSize
    $results
}

Get-NetworkInterfaceHealth
```

执行结果示例：

```
名称     接口描述                            链路速率   IPv4地址       已接收字节  已发送字节  MAC地址
----     ----------                            --------   --------       ----------  ----------  --------
以太网   Intel(R) Ethernet Connection I219-V  1 Gbps     192.168.1.100  12.35 GB    3.28 GB     AA:BB:CC:DD:EE:FF
Wi-Fi    Intel(R) Wi-Fi 6 AX200              866.7 Mbps 192.168.1.101  5.71 GB     1.04 GB     11:22:33:44:55:66
```

## HTTP 响应质量检测

仅仅知道端口是否可达是不够的，很多时候我们需要深入了解 HTTP 服务的响应质量，包括首字节时间（TTFB）、总耗时、状态码以及重定向链。这些指标对 Web 服务运维至关重要。

```powershell
function Test-HttpQuality {
    <#
    .SYNOPSIS
    测试 HTTP/HTTPS 服务的响应质量
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Urls,

        [int]$TimeoutSec = 10
    )

    $results = foreach ($url in $Urls) {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec $TimeoutSec `
                -UseBasicParsing -MaximumRedirection 0 -ErrorAction Stop

            $timer.Stop()

            [PSCustomObject]@{
                URL       = $url
                状态码    = [int]$response.StatusCode
                状态描述  = $response.StatusDescription
                总耗时ms  = $timer.ElapsedMilliseconds
                内容长度  = if ($response.Headers['Content-Length']) {
                    '{0:N0} bytes' -f [int]$response.Headers['Content-Length']
                } else {
                    'N/A'
                }
                服务器    = if ($response.Headers['Server']) {
                    $response.Headers['Server']
                } else {
                    '-'
                }
                结果      = '成功'
            }
        } catch {
            $timer.Stop()
            $statusCode = $null

            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            [PSCustomObject]@{
                URL       = $url
                状态码    = $statusCode
                状态描述  = if ($statusCode) { $_.Exception.Message.Substring(0, 60) } else { '-' }
                总耗时ms  = $timer.ElapsedMilliseconds
                内容长度  = 'N/A'
                服务器    = '-'
                结果      = '失败'
            }
        }
    }

    $results | Format-Table -AutoSize
}

$targets = @(
    'https://blog.vichamp.com',
    'https://github.com',
    'https://nonexistent-test-12345.example.com'
)

Test-HttpQuality -Urls $targets
```

执行结果示例：

```
URL                                               状态码 状态描述                   总耗时ms 内容长度       服务器        结果
---                                               ------ --------                   -------- ----------       ------        ----
https://blog.vichamp.com                               200 OK                              312 15,280 bytes  GitHub.com   成功
https://github.com                                     200 OK                              287 82,451 bytes  GitHub.com   成功
https://nonexistent-test-12345.example.com               - -                                   5012 N/A            -            失败
```

## 延迟与丢包统计分析

网络延迟和丢包率是衡量链路质量的核心指标。下面的脚本通过多次 ICMP 测试，统计平均延迟、最小/最大延迟、抖动（jitter）以及丢包率，并给出一个综合评级。

```powershell
function Test-NetworkLatency {
    <#
    .SYNOPSIS
    测试到目标主机的延迟和丢包率
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Targets,

        [int]$Count = 20,

        [int]$DelayMs = 500
    )

    $results = foreach ($target in $Targets) {
        Write-Host "正在测试 $target ..." -ForegroundColor Gray

        $latencies = [System.Collections.Generic.List[double]]::new()
        $lostCount = 0

        for ($i = 0; $i -lt $Count; $i++) {
            $reply = Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue

            if ($reply) {
                $detail = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
                if ($detail) {
                    $latencies.Add($detail.ResponseTime)
                }
            } else {
                $lostCount++
            }

            if ($i -lt $Count - 1) {
                Start-Sleep -Milliseconds $DelayMs
            }
        }

        if ($latencies.Count -gt 0) {
            $avg = [math]::Round(($latencies | Measure-Object -Average).Average, 1)
            $min = [math]::Round(($latencies | Measure-Object -Minimum).Minimum, 1)
            $max = [math]::Round(($latencies | Measure-Object -Maximum).Maximum, 1)

            # 计算抖动（相邻延迟差的平均值）
            $jitterValues = [System.Collections.Generic.List[double]]::new()
            for ($j = 1; $j -lt $latencies.Count; $j++) {
                $jitterValues.Add([math]::Abs($latencies[$j] - $latencies[$j - 1]))
            }
            $jitter = if ($jitterValues.Count -gt 0) {
                [math]::Round(($jitterValues | Measure-Object -Average).Average, 1)
            } else {
                0
            }

            $lossRate = [math]::Round(($lostCount / $Count) * 100, 1)

            # 综合评级
            $grade = if ($avg -lt 10 -and $lossRate -eq 0 -and $jitter -lt 5) {
                '优秀'
            } elseif ($avg -lt 50 -and $lossRate -lt 1) {
                '良好'
            } elseif ($avg -lt 100 -and $lossRate -lt 5) {
                '一般'
            } else {
                '较差'
            }
        } else {
            $avg = $min = $max = $jitter = 0
            $lossRate = 100
            $grade = '不可达'
        }

        [PSCustomObject]@{
            目标   = $target
            平均ms = $avg
            最小ms = $min
            最大ms = $max
            抖动ms = $jitter
            丢包率 = "$lossRate%"
            评级   = $grade
        }
    }

    $results | Format-Table -AutoSize
}

# 批量测试多个目标的网络质量
Test-NetworkLatency -Targets @(
    'baidu.com',
    'google.com',
    'github.com'
) -Count 15
```

执行结果示例：

```
目标        平均ms 最小ms 最大ms 抖动ms 丢包率  评级
----        ------ ------ ------ ------ ------  ----
baidu.com     8.3    5.2   15.1    1.8  0.0%   优秀
google.com   42.7   38.1   55.3    3.2  0.0%   良好
github.com   85.1   72.4  140.6    8.5  6.7%   一般
```

## 实时网络流量监控

最后一个工具用于监控指定时间窗口内的网络流量变化趋势。它每隔一定时间采样一次网卡统计数据，计算每秒的吞吐量，帮助你发现突发的流量异常（例如某个进程突然大量上传数据）。

```powershell
function Watch-NetworkTraffic {
    <#
    .SYNOPSIS
    实时监控网络接口流量
    #>
    param(
        [string]$InterfaceName = (Get-NetAdapter |
            Where-Object { $_.Status -eq 'Up' -and $_.InterfaceType -notmatch 'Loopback' } |
            Select-Object -First 1).Name,

        [int]$DurationSeconds = 30,

        [int]$IntervalSeconds = 2
    )

    $adapter = Get-NetAdapter -Name $InterfaceName -ErrorAction SilentlyContinue

    if (-not $adapter) {
        Write-Host "未找到网络接口：$InterfaceName" -ForegroundColor Red
        return
    }

    Write-Host "监控接口：$InterfaceName ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
    Write-Host "持续时间：${DurationSeconds}秒，采样间隔：${IntervalSeconds}秒" -ForegroundColor Cyan
    Write-Host ('-' * 70)

    $samples = [System.Collections.Generic.List[PSCustomObject]]::new()
    $startTime = Get-Date

    $prevStats = Get-NetAdapterStatistics -Name $InterfaceName
    $prevTime = Get-Date

    while (((Get-Date) - $startTime).TotalSeconds -lt $DurationSeconds) {
        Start-Sleep -Seconds $IntervalSeconds

        $currentStats = Get-NetAdapterStatistics -Name $InterfaceName
        $currentTime = Get-Date

        $elapsed = ($currentTime - $prevTime).TotalSeconds
        if ($elapsed -le 0) { $elapsed = 1 }

        $rxRate = ($currentStats.ReceivedBytes - $prevStats.ReceivedBytes) / $elapsed
        $txRate = ($currentStats.SentBytes - $prevStats.SentBytes) / $elapsed

        function Format-Bytes {
            param([double]$Bytes)
            if ($Bytes -ge 1MB) { '{0,8:N2} MB/s' -f ($Bytes / 1MB) }
            elseif ($Bytes -ge 1KB) { '{0,8:N2} KB/s' -f ($Bytes / 1KB) }
            else { '{0,8:N2}  B/s' -f $Bytes }
        }

        $sample = [PSCustomObject]@{
            时间     = $currentTime.ToString('HH:mm:ss')
            接收速率 = Format-Bytes $rxRate
            发送速率 = Format-Bytes $txRate
            累计接收 = '{0:N2} MB' -f ($currentStats.ReceivedBytes / 1MB)
            累计发送 = '{0:N2} MB' -f ($currentStats.SentBytes / 1MB)
        }

        $samples.Add($sample)
        Write-Host ("  {0}  |  接收: {1}  |  发送: {2}" -f `
            $sample.时间, $sample.接收速率, $sample.发送速率)

        $prevStats = $currentStats
        $prevTime = $currentTime
    }

    Write-Host ('-' * 70)
    Write-Host "采样完成，共 $($samples.Count) 个数据点" -ForegroundColor Green

    $samples | Format-Table -AutoSize
}

# 监控 30 秒内的网络流量变化
Watch-NetworkTraffic -DurationSeconds 30 -IntervalSeconds 3
```

执行结果示例：

```
监控接口：以太网 (Intel(R) Ethernet Connection I219-V)
持续时间：30秒，采样间隔：3秒
----------------------------------------------------------------------
  14:20:03  |  接收:     2.35 MB/s  |  发送:     0.42 MB/s
  14:20:06  |  接收:     5.18 MB/s  |  发送:     0.38 MB/s
  14:20:09  |  接收:     1.72 MB/s  |  发送:     0.25 MB/s
  14:20:12  |  接收:     8.91 MB/s  |  发送:     1.23 MB/s
  14:20:15  |  接收:     3.44 MB/s  |  发送:     0.55 MB/s
  14:20:18  |  接收:     0.85 MB/s  |  发送:     0.12 MB/s
  14:20:21  |  接收:     1.06 MB/s  |  发送:     0.18 MB/s
  14:20:24  |  接收:     4.67 MB/s  |  发送:     0.89 MB/s
  14:20:27  |  接收:     2.13 MB/s  |  发送:     0.33 MB/s
  14:20:30  |  接收:     1.88 MB/s  |  发送:     0.29 MB/s
----------------------------------------------------------------------
采样完成，共 10 个数据点

时间     接收速率          发送速率          累计接收        累计发送
----     --------          --------          --------        --------
14:20:03      2.35 MB/s       0.42 MB/s     12,350.22 MB    3,281.45 MB
14:20:06      5.18 MB/s       0.38 MB/s     12,365.76 MB    3,282.59 MB
14:20:09      1.72 MB/s       0.25 MB/s     12,370.92 MB    3,283.34 MB
```

## 注意事项

1. **管理员权限**：`Get-NetAdapterStatistics` 等部分 cmdlet 在某些 Windows 版本上需要以管理员身份运行 PowerShell，否则可能返回不完整的数据
2. **采样精度**：流量监控的精度取决于采样间隔，间隔越短结果越精确，但也会增加系统开销；建议生产环境使用 3-5 秒的间隔
3. **IPv4/IPv6 兼容**：延迟测试中 `Test-Connection` 默认可能优先使用 IPv6，如果目标仅支持 IPv4，可通过 `-TargetName` 参数配合 `[System.Net.Dns]::GetHostAddresses` 显式指定地址族
4. **HTTPS 证书警告**：HTTP 质量检测中遇到自签名证书或过期证书时，`Invoke-WebRequest` 会抛出异常，可根据实际需求决定是否跳过证书验证（添加 `-SkipCertificateCheck` 参数，仅限 PowerShell 7+）
5. **并发性能**：批量测试多个目标时，如果目标数量较多，可以考虑使用 `Runspaces` 或 PowerShell 7 的 `ForEach-Object -Parallel` 来并发执行，显著缩短总耗时
6. **防火墙与 ICMP**：部分云服务器和网络安全设备默认屏蔽 ICMP 协议，此时 ping 测试会失败但 HTTP 服务可能正常，诊断时应结合多种协议综合判断
