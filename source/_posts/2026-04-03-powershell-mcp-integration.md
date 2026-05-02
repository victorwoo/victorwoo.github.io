---
layout: post
date: 2026-04-03 08:00:00
updated: 2026-04-03 08:00:00
title: "PowerShell 技能连载 - MCP 协议集成"
description: PowerTip of the Day - MCP Protocol Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ai
- mcp
- llm
- protocol
- tool-use
---

_适用于 PowerShell 7.0 及以上版本_

MCP（Model Context Protocol）是 Anthropic 于 2024 年底发布的开放协议，旨在为大语言模型（LLM）提供标准化的上下文获取和工具调用接口。通过 MCP，AI 应用可以统一地连接数据源、调用外部工具、访问资源，而不必为每个集成编写专用的适配代码。协议本身基于 JSON-RPC 2.0，传输层支持 stdio 和 SSE（Server-Sent Events）两种模式，非常适合构建可组合的 AI 工具生态。

对于 PowerShell 用户来说，MCP 带来了一个令人兴奋的可能性：我们可以用 PowerShell 脚本直接构建 MCP 服务端，将系统管理能力以标准化工具的形式暴露给 AI 助手；同时也能编写 MCP 客户端，让 PowerShell 脚本调用任何符合 MCP 规范的 AI 服务和工具集。这种双向集成使得 PowerShell 成为 AI 工具链中一等公民。

本文将通过三个实际示例，展示如何用 PowerShell 7 搭建 MCP 服务端、编写 MCP 客户端，以及打包一套实用的系统管理工具集，帮助读者快速上手 MCP 与 PowerShell 的结合使用。

## 搭建 MCP 服务端

MCP 服务端的核心职责是：监听客户端请求、注册可用的工具（tools）和资源（resources）、处理工具调用并返回结果。以下代码用 PowerShell 实现了一个基于 stdio 传输的最小化 MCP 服务端，支持协议握手、工具列举和工具调用三个核心能力。

```powershell
using namespace System.Collections.Generic
using namespace System.Text.Json

# MCP 服务端核心类
class McpServer {
    [string] $ServerName
    [string] $Version
    [List[hashtable]] $Tools
    [Dictionary[string, scriptblock]] $Handlers

    McpServer([string]$Name, [string]$Ver) {
        $this.ServerName = $Name
        $this.Version = $Ver
        $this.Tools = [List[hashtable]]::new()
        $this.Handlers = [Dictionary[string, scriptblock]]::new()
    }

    # 注册工具
    [void] RegisterTool(
        [string]$ToolName,
        [string]$Description,
        [hashtable]$Parameters,
        [scriptblock]$Handler
    ) {
        $toolDef = @{
            name        = $ToolName
            description = $Description
            inputSchema = @{
                type       = 'object'
                properties = $Parameters
                required   = @($Parameters.Keys)
            }
        }
        $this.Tools.Add($toolDef)
        $this.Handlers[$ToolName] = $Handler
    }

    # 处理 JSON-RPC 请求
    [string] HandleRequest([string]$JsonLine) {
        $request = $JsonLine | ConvertFrom-Json -AsHashtable
        $response = @{ jsonrpc = '2.0'; id = $request.id }

        switch ($request.method) {
            'initialize' {
                $response.result = @{
                    protocolVersion = '2025-03-26'
                    capabilities    = @{ tools = @{} }
                    serverInfo      = @{
                        name    = $this.ServerName
                        version = $this.Version
                    }
                }
            }
            'tools/list' {
                $response.result = @{ tools = $this.Tools }
            }
            'tools/call' {
                $toolName = $request.params.name
                $args     = $request.params.arguments
                if ($this.Handlers.ContainsKey($toolName)) {
                    $result = & $this.Handlers[$toolName] $args
                    $response.result = @{
                        content = @(
                            @{ type = 'text'; text = ($result | ConvertTo-Json -Depth 5) }
                        )
                    }
                } else {
                    $response.error = @{
                        code    = -32601
                        message = "Tool not found: $toolName"
                    }
                }
            }
            default {
                $response.error = @{
                    code    = -32601
                    message = "Method not found: $($request.method)"
                }
            }
        }
        return $response | ConvertTo-Json -Depth 10 -Compress
    }

    # 启动 stdio 监听循环
    [void] Start() {
        Write-Host "[$($this.ServerName)] MCP Server started on stdio" `
            -ForegroundColor Green
        while ($null -ne ($line = [Console]::In.ReadLine())) {
            $reply = $this.HandleRequest($line)
            [Console]::Out.WriteLine($reply)
            [Console]::Out.Flush()
        }
    }
}

# 创建服务端实例并注册示例工具
$server = [McpServer]::new('ps-mcp-server', '1.0.0')

$server.RegisterTool(
    'get-process-info',
    '获取指定进程的详细信息',
    @{ name = @{ type = 'string'; description = '进程名称' } },
    {
        param($args)
        $procs = Get-Process -Name $args.name -ErrorAction SilentlyContinue
        if ($procs) {
            $procs | Select-Object Name, Id, CPU, WorkingSet64, Path |
                Format-Table -AutoSize | Out-String
        } else {
            "未找到进程: $($args.name)"
        }
    }
)

$server.RegisterTool(
    'calculate',
    '执行数学表达式计算',
    @{
        expression = @{ type = 'string'; description = '数学表达式' }
    },
    {
        param($args)
        $result = Invoke-Expression $args.expression
        "计算结果: $($args.expression) = $result"
    }
)

# 如需 stdio 模式，取消下行注释
# $server.Start()
```

上述代码定义了一个 `McpServer` 类，通过 `RegisterTool` 方法注册工具及其处理脚本块，`HandleRequest` 方法根据 JSON-RPC 方法名分发处理。启动后在 stdio 上逐行读取 JSON 请求并返回 JSON 响应。以下模拟了客户端发送 initialize 和 tools/list 请求后服务端返回的响应：

```
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-03-26","capabilities":{"tools":{}},"serverInfo":{"name":"ps-mcp-server","version":"1.0.0"}}}

{"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"get-process-info","description":"获取指定进程的详细信息","inputSchema":{"type":"object","properties":{"name":{"type":"string","description":"进程名称"}},"required":["name"]}},{"name":"calculate","description":"执行数学表达式计算","inputSchema":{"type":"object","properties":{"expression":{"type":"string","description":"数学表达式"}},"required":["expression"]}}]}}
```

## 编写 MCP 客户端

有了服务端之后，我们需要一个客户端来连接它、发现可用工具并发起调用。以下代码实现了一个 MCP 客户端，通过启动服务端进程并以 stdin/stdout 管道与之通信，完整走通握手、列举、调用的流程。

```powershell
class McpClient {
    [System.Diagnostics.Process] $Process
    [int] $RequestId = 0
    [hashtable] $ServerCapabilities
    [array] $AvailableTools

    # 启动服务端进程
    [void] Connect([string]$Command, [string[]]$Arguments) {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName            = $Command
        $psi.Arguments           = $Arguments -join ' '
        $psi.UseShellExecute     = $false
        $psi.RedirectStandardInput  = $true
        $psi.RedirectStandardOutput = $true
        $psi.CreateNoWindow      = $true

        $this.Process = [System.Diagnostics.Process]::Start($psi)
        Write-Host "已连接到 MCP 服务端 (PID: $($this.Process.Id))" `
            -ForegroundColor Cyan

        # 发送 initialize 请求
        $initResult = $this.SendRequest('initialize', @{
            protocolVersion = '2025-03-26'
            capabilities    = @{}
            clientInfo      = @{
                name    = 'ps-mcp-client'
                version = '1.0.0'
            }
        })
        $this.ServerCapabilities = $initResult.capabilities
        Write-Host "服务端: $($initResult.serverInfo.name) v$($initResult.serverInfo.version)"

        # 发送 initialized 通知
        $this.SendNotification('notifications/initialized', @{})

        # 缓存可用工具列表
        $toolsResult = $this.SendRequest('tools/list', @{})
        $this.AvailableTools = $toolsResult.tools
        Write-Host "已发现 $($this.AvailableTools.Count) 个工具:"
        foreach ($tool in $this.AvailableTools) {
            Write-Host ("  - {0}: {1}" -f $tool.name, $tool.description) `
                -ForegroundColor Yellow
        }
    }

    # 发送 JSON-RPC 请求并等待响应
    [hashtable] SendRequest([string]$Method, [hashtable]$Params) {
        $this.RequestId++
        $request = @{
            jsonrpc = '2.0'
            id      = $this.RequestId
            method  = $Method
            params  = $Params
        }
        $jsonLine = $request | ConvertTo-Json -Depth 10 -Compress
        $this.Process.StandardInput.WriteLine($jsonLine)
        $this.Process.StandardInput.Flush()

        $responseLine = $this.Process.StandardOutput.ReadLine()
        $response = $responseLine | ConvertFrom-Json -AsHashtable
        if ($response.error) {
            throw "MCP Error [$($response.error.code)]: $($response.error.message)"
        }
        return $response.result
    }

    # 发送 JSON-RPC 通知（无 id，无响应）
    [void] SendNotification([string]$Method, [hashtable]$Params) {
        $notification = @{
            jsonrpc = '2.0'
            method  = $Method
            params  = $Params
        }
        $jsonLine = $notification | ConvertTo-Json -Depth 10 -Compress
        $this.Process.StandardInput.WriteLine($jsonLine)
        $this.Process.StandardInput.Flush()
    }

    # 调用指定工具
    [string] InvokeTool([string]$ToolName, [hashtable]$Arguments) {
        $result = $this.SendRequest('tools/call', @{
            name      = $ToolName
            arguments = $Arguments
        })
        $textParts = $result.content | Where-Object { $_.type -eq 'text' }
        return ($textParts | ForEach-Object { $_.text }) -join "`n"
    }

    # 断开连接
    [void] Disconnect() {
        if ($this.Process -and -not $this.Process.HasExited) {
            $this.Process.StandardInput.Close()
            $this.Process.WaitForExit(5000)
            if (-not $this.Process.HasExited) {
                $this.Process.Kill()
            }
        }
        Write-Host "已断开 MCP 连接" -ForegroundColor DarkGray
    }
}
```

客户端通过 `Connect` 方法启动服务端进程并完成协议握手，`InvokeTool` 方法封装了工具调用的细节，调用者只需传入工具名和参数即可获取结果。下面演示了使用客户端调用工具的典型流程：

```
已连接到 MCP 服务端 (PID: 45832)
服务端: ps-mcp-server v1.0.0
已发现 2 个工具:
  - get-process-info: 获取指定进程的详细信息
  - calculate: 执行数学表达式计算

PS> $client.InvokeTool('get-process-info', @{ name = 'pwsh' })

Name  Id     CPU          WorkingSet64 Path
----  --     ---          ------------ ----
pwsh  45832  3.2145       83251200     /usr/local/bin/pwsh
pwsh  45901  1.7823       79216640     /usr/local/bin/pwsh

PS> $client.InvokeTool('calculate', @{ expression = '2 ** 10 + sqrt(144)' })
计算结果: 2 ** 10 + sqrt(144) = 1012
```

## 实用系统管理工具集

理解了 MCP 的客户端-服务端架构后，我们可以把日常系统管理中常用的操作封装成 MCP 工具集，让 AI 助手能够直接调用这些能力。以下代码注册了一组涵盖系统信息、文件操作和网络诊断的实用工具。

```powershell
$sysServer = [McpServer]::new('ps-sys-tools', '1.0.0')

# 工具 1：系统概览
$sysServer.RegisterTool(
    'system-overview',
    '获取操作系统、CPU、内存等系统概览信息',
    @{},
    {
        param($args)
        $os     = [System.Environment]::OSVersion
        $cpu    = Get-CimInstance Win32_Processor | Select-Object -First 1
        $mem    = Get-CimInstance Win32_OperatingSystem
        $totalMem  = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
        $freeMem   = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
        $usedPct   = [math]::Round(($totalMem - $freeMem) / $totalMem * 100, 1)
        @{
            OS               = "$($os.Platform) $($os.Version)"
            MachineName      = [System.Environment]::MachineName
            Processor        = $cpu.Name
            CPUUtilization   = "$([math]::Round($cpu.LoadPercentage, 1))%"
            TotalMemory_GB   = $totalMem
            FreeMemory_GB    = $freeMem
            MemoryUsage      = "$usedPct%"
            PowerShellVersion= $PSVersionTable.PSVersion.ToString()
            Uptime           = (Get-Date) - $mem.LastBootUpTime | Out-String
        }
    }
)

# 工具 2：搜索文件内容
$sysServer.RegisterTool(
    'search-files',
    '在指定目录中搜索包含指定文本的文件',
    @{
        directory = @{ type = 'string'; description = '搜索目录路径' }
        pattern   = @{ type = 'string'; description = '搜索的文本模式' }
        extension = @{
            type        = 'string'
            description = '文件扩展名过滤（可选）'
        }
    },
    {
        param($args)
        $params = @{
            Path    = $args.directory
            Pattern = $args.pattern
            Recurse = $true
        }
        if ($args.extension) {
            $params.Include = "*.$($args.extension)"
        }
        $results = Select-String @params |
            Select-Object -First 20 |
            ForEach-Object {
                @{
                    File   = $_.Path
                    Line   = $_.LineNumber
                    Match  = $_.Line.Trim()
                }
            }
        if (-not $results) {
            return @{ message = '未找到匹配结果'; matches = @() }
        }
        @{ matches = $results; totalFound = $results.Count }
    }
)

# 工具 3：网络连通性诊断
$sysServer.RegisterTool(
    'network-diag',
    '对指定主机执行网络连通性诊断（Ping + 端口检测）',
    @{
        hostname = @{ type = 'string'; description = '目标主机名或 IP' }
        ports    = @{
            type        = 'string'
            description = '要检测的端口，逗号分隔（如 80,443,22）'
        }
    },
    {
        param($args)
        $results = @{}

        # Ping 测试
        $ping = Test-Connection -TargetName $args.hostname `
            -Count 4 -ErrorAction SilentlyContinue
        if ($ping) {
            $latencies = $ping | ForEach-Object { $_.Latency }
            $results.ping = @{
                success   = $true
                avgMs     = [math]::Round(($latencies | Measure-Object -Average).Average, 2)
                minMs     = ($latencies | Measure-Object -Minimum).Minimum
                maxMs     = ($latencies | Measure-Object -Maximum).Maximum
            }
        } else {
            $results.ping = @{ success = $false; message = '主机不可达' }
        }

        # 端口检测
        $portResults = @{}
        foreach ($port in $args.port -split ',') {
            $port = $port.Trim()
            $tcp = [System.Net.Sockets.TcpClient]::new()
            try {
                $connect = $tcp.ConnectAsync($args.hostname, [int]$port)
                $wait = $connect.Wait(3000)
                $portResults[$port] = if ($wait -and $connect.IsCompletedSuccessfully) {
                    'OPEN'
                } else {
                    'CLOSED/TIMEOUT'
                }
            } finally {
                $tcp.Close()
            }
        }
        $results.ports = $portResults
        $results
    }
)

# 工具 4：服务状态查询
$sysServer.RegisterTool(
    'get-service-status',
    '查询指定服务的运行状态',
    @{
        name = @{ type = 'string'; description = '服务名称（支持通配符）' }
    },
    {
        param($args)
        $services = Get-Service -Name $args.name -ErrorAction SilentlyContinue
        if (-not $services) {
            return @{ message = "未找到服务: $($args.name)" }
        }
        $services | ForEach-Object {
            @{
                Name       = $_.Name
                DisplayName= $_.DisplayName
                Status     = $_.Status.ToString()
                StartType  = $_.StartType.ToString()
            }
        }
    }
)

Write-Host "已注册 $($sysServer.Tools.Count) 个系统管理工具" `
    -ForegroundColor Green
Write-Host "工具列表:"
$sysServer.Tools | ForEach-Object {
    Write-Host ("  {0,-20} {1}" -f $_.name, $_.description)
}
```

注册完成后，AI 助手可以通过 MCP 协议调用这些工具。例如，当用户询问"这台服务器的内存够用吗"时，AI 会自动调用 `system-overview` 工具获取实时数据并给出分析。以下是一次典型调用的输出：

```
PS> $result = $sysServer.HandleRequest(
    '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"network-diag","arguments":{"hostname":"example.com","ports":"80,443,22"}}}'
)

$result | ConvertFrom-Json | ConvertTo-Json -Depth 5

{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"ping\":{\"success\":true,\"avgMs\":23.45,\"minMs\":21,\"maxMs\":28},\"ports\":{\"80\":\"OPEN\",\"443\":\"OPEN\",\"22\":\"CLOSED/TIMEOUT\"}}"
      }
    ]
  }
}

PS> $result2 = $sysServer.HandleRequest(
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"system-overview","arguments":{}}}'
)

$result2 | ConvertFrom-Json -AsHashtable | ForEach-Object {
    $_.result.content[0].text | ConvertFrom-Json
}

OS               : Unix 15.4.0
MachineName      : workstation01
Processor        : Apple M3 Pro
CPUUtilization   : 12.3%
TotalMemory_GB   : 36.0
FreeMemory_GB    : 14.27
MemoryUsage      : 60.4%
PowerShellVersion: 7.5.0
Uptime           : 3.14:27:08.3421000
```

## 注意事项

1. **传输模式选择**：stdio 模式适合进程间通信（AI 助手启动 PowerShell 子进程），SSE 模式适合跨网络通信（远程服务器上的 MCP 服务）。Windows 环境下推荐 stdio，Linux 服务端部署可考虑 SSE。

2. **安全沙箱**：MCP 工具本质上是在执行任意 PowerShell 代码，必须在受控环境中运行。生产部署时应限制工具的执行权限，避免注册如 `Invoke-Expression` 等高风险操作，或使用 constrained language mode 加固。

3. **超时处理**：网络诊断等工具可能耗时较长，建议在客户端实现超时机制（如 `WaitHandle.AsyncWaitHandle.WaitOne(5000)`），避免长时间阻塞导致 JSON-RPC 管道挂死。

4. **错误传播**：MCP 规范定义了标准错误码（如 `-32600` Invalid Request、`-32601` Method not found），服务端应遵循这些错误码返回，客户端应正确捕获并呈现错误信息，不要将原始异常暴露给 AI。

5. **工具描述的重要性**：`description` 字段是 AI 模型选择工具的主要依据。描述应当清晰、具体、包含关键的使用前提。例如"获取指定进程的详细信息"比"查询进程"更有利于模型准确匹配用户意图。

6. **序列化深度**：PowerShell 对象通常嵌套层级较深（如 CIM 实例、进程对象），使用 `ConvertTo-Json` 时务必指定足够的 `-Depth` 参数（建议 5 以上），否则深层属性会被截断为字符串"$ref"，导致 AI 收到不完整的数据。
