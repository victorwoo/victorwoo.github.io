---
layout: post
date: 2026-02-17 08:00:00
updated: 2026-02-17 08:00:00
title: "PowerShell 技能连载 - Azure Front Door 与 CDN 管理"
description: PowerTip of the Day - Azure Front Door and CDN Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- frontdoor
- cdn
- networking
---

_适用于 PowerShell 7.0 及以上版本_

Azure Front Door 是微软 Azure 平台上的云原生应用交付控制器（ADC），集成了全球 CDN、智能七层路由、Web 应用防火墙（WAF）和 SSL 卸载等核心能力。对于面向全球用户的 Web 应用来说，Front Door 能通过遍布全球的边缘节点，将用户请求自动路由到最近的后端实例，显著降低访问延迟并提升可用性。

在实际运维中，Front Door 的配置往往涉及多个层面：后端池定义、健康探测、路由规则、WAF 策略、缓存行为和自定义域名绑定。当环境数量增多（开发、预发布、生产）或者需要频繁调整规则时，纯手工在 Azure 门户中操作不仅效率低下，还容易因为人为疏漏导致配置漂移。

通过 PowerShell 的 `Az.FrontDoor` 模块，我们可以将 Front Door 的完整配置脚本化，实现基础设施即代码（IaC）的管理方式。本文将围绕三个核心场景展开：Front Door 配置管理、WAF 安全策略配置，以及缓存与性能优化，帮助你用 PowerShell 系统化地管理全球流量入口。

<!-- more -->

## Front Door 配置管理

下面的脚本演示了如何创建 Front Door 配置文件，包括后端池定义、健康探测设置和路由规则的完整流程。每个步骤都通过 PowerShell 参数化，方便在不同环境间复用。

```powershell
# 连接 Azure 并选择订阅
Connect-AzAccount -Subscription 'MySubscription'

# 定义变量
$resourceGroup = 'rg-frontdoor-demo'
$location = 'global'
$frontDoorName = 'fd-demo-001'

# 创建资源组
New-AzResourceGroup -Name $resourceGroup -Location $location -Force

# 定义后端地址池
$backend1 = New-AzFrontDoorBackendObject `
    -Address 'app-eastasia.azurewebsites.net' `
    -HttpPort 80 `
    -HttpsPort 443 `
    -Priority 1 `
    -Weight 50

$backend2 = New-AzFrontDoorBackendObject `
    -Address 'app-eastus.azurewebsites.net' `
    -HttpPort 80 `
    -HttpsPort 443 `
    -Priority 2 `
    -Weight 50

$backendPool = New-AzFrontDoorBackendPoolObject `
    -Name 'primaryPool' `
    -FrontDoorName $frontDoorName `
    -ResourceGroupName $resourceGroup `
    -Backend $backend1, $backend2

# 定义健康探测
$healthProbe = New-AzFrontDoorHealthProbeSettingObject `
    -Name 'appHealthProbe' `
    -Path '/health' `
    -Protocol Https `
    -IntervalInSeconds 30

# 定义负载均衡设置
$loadBalancing = New-AzFrontDoorLoadBalancingSettingObject `
    -Name 'appLoadBalancing' `
    -SampleSize 4 `
    -SuccessfulSamplesRequired 2

# 定义前端端点
$frontendEndpoint = New-AzFrontDoorFrontendEndpointObject `
    -Name 'frontendEndpoint1' `
    -HostName "$frontDoorName.azurefd.net"

# 定义路由规则
$routingRule = New-AzFrontDoorRoutingRuleObject `
    -Name 'defaultRouting' `
    -FrontDoorName $frontDoorName `
    -ResourceGroupName $resourceGroup `
    -FrontendEndpointName 'frontendEndpoint1' `
    -BackendPoolName 'primaryPool' `
    -AcceptedProtocol Https `
    -PatternsToMatch '/*' `
    -EnabledState Enabled

# 创建 Front Door 实例
$frontDoor = New-AzFrontDoor `
    -ResourceGroupName $resourceGroup `
    -Name $frontDoorName `
    -BackendPool $backendPool `
    -HealthProbeSetting $healthProbe `
    -LoadBalancingSetting $loadBalancing `
    -FrontendEndpoint $frontendEndpoint `
    -RoutingRule $routingRule

Write-Host "Front Door 创建完成：$($frontDoor.Name)"
Write-Host "前端访问地址：https://$frontDoorName.azurefd.net"
```

执行结果示例：

```
Front Door 创建完成：fd-demo-001
前端访问地址：https://fd-demo-001.azurefd.net

ResourceGroupName : rg-frontdoor-demo
Name              : fd-demo-001
Type              : Microsoft.Network/frontdoors
Location          : global
ProvisioningState : Succeeded
Cname             : fd-demo-001.azurefd.net
```

可以看到，Front Door 的创建过程是声明式的：我们先定义后端池、健康探测和负载均衡策略等子资源，然后将它们组合成一个完整的 Front Door 实例。`global` 区域意味着 Front Door 会在全球所有边缘节点自动部署。

## WAF 安全策略配置

Web 应用防火墙（WAF）是 Front Door 安全体系的核心组件。下面的脚本展示了如何创建 WAF 策略，配置自定义规则、托管规则集和速率限制，为应用提供多层安全防护。

```powershell
# 定义 WAF 策略变量
$wafPolicyName = 'waf-demo-policy'
$resourceGroup = 'rg-frontdoor-demo'

# 创建自定义规则：阻断特定恶意 User-Agent
$customRule1 = New-AzFrontDoorWafCustomRuleObject `
    -Name 'blockBadBots' `
    -RuleType MatchRule `
    -MatchCondition @{
        MatchVariable     = 'RequestHeader'
        Selector          = 'User-Agent'
        OperatorProperty  = 'Contains'
        MatchValue        = @('BadBot', 'Scraper', 'MaliciousCrawler')
        NegateCondition   = $false
    } `
    -Action Block `
    -Priority 100

# 创建自定义规则：仅允许特定国家/地区访问
$customRule2 = New-AzFrontDoorWafCustomRuleObject `
    -Name 'geoFilterRule' `
    -RuleType MatchRule `
    -MatchCondition @{
        MatchVariable     = 'SocketAddr'
        OperatorProperty  = 'GeoMatch'
        MatchValue        = @('CN', 'HK', 'TW', 'SG', 'JP')
        NegateCondition   = $true
    } `
    -Action Block `
    -Priority 200

# 创建速率限制规则：防止暴力破解
$rateLimitRule = New-AzFrontDoorWafCustomRuleObject `
    -Name 'rateLimitLogin' `
    -RuleType RateLimitRule `
    -MatchCondition @{
        MatchVariable     = 'RequestUri'
        OperatorProperty  = 'Contains'
        MatchValue        = @('/api/login', '/api/auth')
    } `
    -RateLimitDurationInMinutes 1 `
    -RateLimitThreshold 20 `
    -Action Block `
    -Priority 300

# 创建托管规则集（OWASP Top 10 防护）
$managedRuleSet = New-AzFrontDoorWafManagedRuleObject `
    -Type 'Microsoft_DefaultRuleSet' `
    -Version '2.1'

$botRuleSet = New-AzFrontDoorWafManagedRuleObject `
    -Type 'Microsoft_BotManagerRuleSet' `
    -Version '1.0'

# 组合创建 WAF 策略
$wafPolicy = New-AzFrontDoorWafPolicy `
    -ResourceGroupName $resourceGroup `
    -Name $wafPolicyName `
    -CustomRule $customRule1, $customRule2, $rateLimitRule `
    -ManagedRule $managedRuleSet, $botRuleSet `
    -EnabledState Enabled `
    -Mode Prevention

Write-Host "WAF 策略创建完成：$($wafPolicy.Name)"
Write-Host "运行模式：$($wafPolicy.Mode)"
Write-Host "自定义规则数量：$($wafPolicy.CustomRules.Count)"
Write-Host "托管规则集数量：$($wafPolicy.ManagedRules.Count)"

# 将 WAF 策略关联到 Front Door 前端端点
$frontDoorName = 'fd-demo-001'
$frontendEndpoint = Get-AzFrontDoorFrontendEndpoint `
    -ResourceGroupName $resourceGroup `
    -FrontDoorName $frontDoorName `
    -Name 'frontendEndpoint1'

# 更新前端端点以关联 WAF 策略
$wafPolicyId = $wafPolicy.Id
Update-AzFrontDoorFrontendEndpoint `
    -ResourceGroupName $resourceGroup `
    -FrontDoorName $frontDoorName `
    -Name 'frontendEndpoint1' `
    -WebApplicationFirewallPolicyLink $wafPolicyId

Write-Host "WAF 策略已关联到前端端点"
```

执行结果示例：

```
WAF 策略创建完成：waf-demo-policy
运行模式：Prevention
自定义规则数量：3
托管规则集数量：2
WAF 策略已关联到前端端点

PolicyId     : /subscriptions/xxxx/resourceGroups/rg-frontdoor-demo/providers/Microsoft.Network/frontdoorwebappfirewallpolicies/waf-demo-policy
EnabledState : Enabled
Mode         : Prevention
CustomRules  : {blockBadBots, geoFilterRule, rateLimitLogin}
ManagedRules : {Microsoft_DefaultRuleSet-2.1, Microsoft_BotManagerRuleSet-1.0}
```

WAF 策略的三层防护各司其职：自定义规则处理业务特定逻辑（如地域访问控制），速率限制防御暴力攻击，托管规则集则覆盖 OWASP Top 10 等常见攻击模式。`Prevention` 模式会直接阻断恶意请求，调试阶段可以切换为 `Detection` 仅记录日志。

## 缓存与性能优化

合理的缓存策略能大幅减少后端负载，同时提升用户访问速度。下面的脚本展示了如何配置缓存规则、启用压缩，以及生成流量分析报告。

```powershell
# 定义变量
$resourceGroup = 'rg-frontdoor-demo'
$frontDoorName = 'fd-demo-001'

# 获取当前 Front Door 配置
$frontDoor = Get-AzFrontDoor `
    -ResourceGroupName $resourceGroup `
    -Name $frontDoorName

# 创建带缓存的路由规则（静态资源）
$cachedBackendPool = $frontDoor.BackendPools[0]
$cachedFrontend = $frontDoor.FrontendEndpoints[0]

# 更新路由规则，添加缓存配置
$routingRuleWithCache = New-AzFrontDoorRoutingRuleObject `
    -Name 'staticAssetsRouting' `
    -FrontDoorName $frontDoorName `
    -ResourceGroupName $resourceGroup `
    -FrontendEndpointName $cachedFrontend.Name `
    -BackendPoolName $cachedBackendPool.Name `
    -AcceptedProtocol Http, Https `
    -PatternsToMatch '/static/*', '/images/*', '/css/*', '/js/*' `
    -EnabledState Enabled `
    -DefaultCacheBehavior `
    -CacheDuration 'P30D' `
    -ForwardingProtocol HttpsOnly `
    -CacheKeyQueryParameterStripAll

# 创建 API 路径的动态缓存规则
$apiCacheRule = New-AzFrontDoorRoutingRuleObject `
    -Name 'apiCacheRouting' `
    -FrontDoorName $frontDoorName `
    -ResourceGroupName $resourceGroup `
    -FrontendEndpointName $cachedFrontend.Name `
    -BackendPoolName $cachedBackendPool.Name `
    -AcceptedProtocol Https `
    -PatternsToMatch '/api/products/*', '/api/catalog/*' `
    -EnabledState Enabled `
    -DefaultCacheBehavior `
    -CacheDuration 'PT5M' `
    -ForwardingProtocol HttpsOnly

# 查看当前 Front Door 的流量统计
$endTime = Get-Date
$startTime = $endTime.AddDays(-7)

# 获取 Front Door 的指标数据
$metrics = Get-AzMetric `
    -ResourceId $frontDoor.Id `
    -MetricName 'RequestCount', 'BackendRequestLatency', 'CacheHitRatio' `
    -StartTime $startTime `
    -EndTime $endTime `
    -TimeGrain 'PT1H' `
    -AggregationType Total, Average

# 生成流量分析报告
$report = [PSCustomObject]@{
    时间范围       = "$startTime ~ $endTime"
    总请求数       = ($metrics | Where-Object { $_.Name -eq 'RequestCount' } |
                        ForEach-Object { $_.Timeseries.Data.TimeseriesDataValues } |
                        Measure-Object -Property Total -Sum).Sum
    平均延迟ms     = [math]::Round(
        ($metrics | Where-Object { $_.Name -eq 'BackendRequestLatency' } |
            ForEach-Object { $_.Timeseries.Data.TimeseriesDataValues } |
            Measure-Object -Property Average -Average).Average, 2)
    缓存命中率pct  = [math]::Round(
        ($metrics | Where-Object { $_.Name -eq 'CacheHitRatio' } |
            ForEach-Object { $_.Timeseries.Data.TimeseriesDataValues } |
            Measure-Object -Property Average -Average).Average * 100, 2)
}

Write-Host "`n=== Front Door 周报 ==="
$report | Format-List

# 列出所有路由规则及缓存状态
Write-Host "`n=== 当前路由规则 ==="
foreach ($rule in $frontDoor.RoutingRules) {
    $cacheStatus = if ($rule.Properties.RoutingRuleProperties.CacheConfiguration) {
        "已启用 (有效期: $($rule.Properties.RoutingRuleProperties.CacheConfiguration.CacheDuration))"
    } else {
        '未启用'
    }
    [PSCustomObject]@{
        规则名称    = $rule.Name
        匹配路径    = ($rule.Properties.RoutingRuleProperties.PatternsToMatch -join ', ')
        缓存状态    = $cacheStatus
        协议        = $rule.Properties.RoutingRuleProperties.AcceptedProtocols -join ', '
    } | Format-Table -AutoSize
}
```

执行结果示例：

```
=== Front Door 周报 ===

时间范围      : 2026-02-10 00:00:00 ~ 2026-02-17 00:00:00
总请求数      : 1284350
平均延迟ms    : 23.67
缓存命中率pct : 87.43

=== 当前路由规则 ===

规则名称            匹配路径                              缓存状态                      协议
--------            --------                              --------                      ----
defaultRouting      /*                                    未启用                        Https
staticAssetsRouting /static/*, /images/*, /css/*, /js/*    已启用 (有效期: P30D)         Http, Https
apiCacheRouting     /api/products/*, /api/catalog/*       已启用 (有效期: PT5M)         Https
```

从报告中可以看到，静态资源缓存 30 天能覆盖绝大部分场景，而 API 数据用 5 分钟短缓存可以在数据新鲜度和性能之间取得平衡。缓存命中率 87% 意味着绝大部分请求在边缘节点就已响应，无需回源。

## 注意事项

1. **Front Door Standard/Premium 与经典版差异**：经典版使用 `Az.FrontDoor` 模块，而 Standard/Premium 版使用 `Az.Cdn` 模块（对应 Microsoft.CDN/profiles 资源）。迁移前需确认当前使用的版本，两者的 cmdlet 和配置结构完全不同。

2. **WAF 策略的 Detection 模式调试**：上线新规则前，建议先将 WAF 切换为 `Detection` 模式运行 3-7 天，观察日志中的误报情况。避免直接启用 `Prevention` 模式导致合法流量被阻断。

3. **缓存键的查询参数处理**：`CacheKeyQueryParameterStripAll` 会忽略所有查询参数，即 `/api/data?a=1` 和 `/api/data?b=2` 返回同一份缓存。如果 API 返回内容依赖查询参数（如分页、搜索），需要改用白名单模式。

4. **后端健康探测间隔不宜过短**：`IntervalInSeconds` 设为 30 秒是推荐值，低于 10 秒会增加后端负载，尤其是后端为 Serverless 或按调用计费的服务时，探测流量本身会产生额外费用。

5. **SSL 证书的自动续期**：Front Door 托管的 `.azurefd.net` 域名自带 SSL，但自定义域名需要绑定证书。建议使用 Azure Key Vault 管理证书并启用自动轮换，避免证书过期导致服务中断。

6. **配置变更的传播延迟**：Front Door 的配置变更需要在全球边缘节点传播，通常需要 5-10 分钟生效。自动化脚本中应加入等待逻辑（如轮询 `ProvisioningState`），不要假设配置立即生效。
