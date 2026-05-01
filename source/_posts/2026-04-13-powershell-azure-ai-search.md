---
layout: post
date: 2026-04-13 08:00:00
title: "PowerShell 技能连载 - Azure AI Search 集成"
description: PowerTip of the Day - Azure AI Search Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- ai
- search
- rag
- vector-search
---

_适用于 PowerShell 7.0 及以上版本，需要 Az.Search 模块_

Azure AI Search（原名 Azure 认知搜索）是微软 Azure 云平台中的企业级搜索服务，近年来随着大语言模型的爆发，它在检索增强生成（RAG）架构中扮演着越来越关键的角色。传统企业内部拥有海量非结构化文档，从技术手册到合同范本，从会议纪要到产品规格，这些知识长期"沉睡"在文件服务器和 SharePoint 中，难以被高效检索和利用。Azure AI Search 通过集成文本分词、语义排序和向量检索能力，为这些数据赋予了"可搜索"的生命力。

将 PowerShell 与 Azure AI Search 结合，能够实现搜索服务的全生命周期自动化管理。运维团队可以用脚本一键创建索引、批量导入文档、配置向量字段，甚至搭建完整的 RAG 管道，而无需在 Azure 门户中手动点选。这种方式特别适合 CI/CD 集成和大规模知识库的定期更新场景，让企业知识管理真正做到"基础设施即代码"。

本文将通过三个核心示例，逐步演示如何用 PowerShell 管理 Azure AI Search 的搜索服务与索引结构、实现文档导入与向量化处理，以及构建关键词加向量的混合搜索与 RAG 管道。

## 搜索服务与索引管理

创建搜索服务并定义索引结构是使用 Azure AI Search 的第一步。下面的脚本展示了如何通过 PowerShell 创建搜索服务、获取管理密钥，然后定义一个支持全文检索和向量检索的复合索引结构。索引中包含文档标题、内容、分类标签等文本字段，以及用于语义搜索的向量字段，同时配置了中文分词器以提升中文内容的检索精度。

```powershell
# 安装并导入必要的模块
Install-Module -Name Az.Search -Force -Scope CurrentUser
Install-Module -Name Az.Resources -Force -Scope CurrentUser
Import-Module Az.Search
Import-Module Az.Resources

# 连接到 Azure 账户
Connect-AzAccount

# 定义变量
$resourceGroupName = 'rg-knowledge-base'
$serviceName = 'knowledge-search-svc'
$location = 'eastus'
$sku = 'basic'

# 创建资源组（如果不存在）
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# 创建 Azure AI Search 服务
$searchService = New-AzSearchService `
    -ResourceGroupName $resourceGroupName `
    -Name $serviceName `
    -Sku $sku `
    -Location $location `
    -PartitionCount 1 `
    -ReplicaCount 1

Write-Host "搜索服务创建完成: $($searchService.Name)"

# 获取搜索服务的管理密钥
$adminKey = (Get-AzSearchAdminKeyPair `
    -ResourceGroupName $resourceGroupName `
    -ServiceName $serviceName).Primary

# 定义索引结构（包含全文搜索字段和向量字段）
$indexDefinition = @{
    name   = 'documents-index'
    fields = @(
        @{
            name         = 'id'
            type         = 'Edm.String'
            key          = $true
            searchable   = $false
        },
        @{
            name         = 'title'
            type         = 'Edm.String'
            searchable   = $true
            analyzer     = 'zh-Hans.microsoft'
        },
        @{
            name         = 'content'
            type         = 'Edm.String'
            searchable   = $true
            analyzer     = 'zh-Hans.microsoft'
        },
        @{
            name         = 'category'
            type         = 'Edm.String'
            searchable   = $true
            filterable   = $true
            facetable    = $true
        },
        @{
            name         = 'tags'
            type         = 'Collection(Edm.String)'
            searchable   = $true
            filterable   = $true
            facetable    = $true
        },
        @{
            name         = 'contentVector'
            type         = 'Collection(Edm.Single)'
            searchable   = $true
            dimensions   = 1536
            vectorSearchConfiguration = 'vectorConfig'
        },
        @{
            name         = 'createdDate'
            type         = 'Edm.DateTimeOffset'
            filterable   = $true
            sortable     = $true
        }
    )
    vectorSearch = @{
        algorithmConfigurations = @(
            @{
                name          = 'vectorConfig'
                kind          = 'hnsw'
                parameters    = @{
                    m              = 4
                    efSearch       = 500
                    efConstruction = 400
                }
            }
        )
    }
    semantic = @{
        configurations = @(
            @{
                name       = 'semanticConfig'
                prioritizedFields = @{
                    titleField    = @{ name = 'title' }
                    contentFields = @(
                        @{ name = 'content' }
                    )
                }
            }
        )
    }
}

# 使用 REST API 创建索引
$searchUrl = "https://$serviceName.search.windows.net/indexes?api-version=2024-07-01"
$headers = @{
    'api-key'      = $adminKey
    'Content-Type' = 'application/json'
}

$response = Invoke-RestMethod `
    -Uri $searchUrl `
    -Method Put `
    -Headers $headers `
    -Body ($indexDefinition | ConvertTo-Json -Depth 10)

Write-Host "索引 '$($indexDefinition.name)' 创建成功"
```

执行结果示例：

```text
搜索服务创建完成: knowledge-search-svc
索引 'documents-index' 创建成功
```

## 文档导入与向量化

索引创建完成后，下一步是将文档数据批量导入索引。在现代 RAG 架构中，每个文档不仅需要存储原始文本，还需要计算其向量表示（Embedding），以便后续进行语义搜索。下面的脚本演示了如何读取本地文件、调用 Azure OpenAI Embedding API 生成向量、然后批量将文档推送到 Azure AI Search 索引中。

```powershell
# 配置 Azure OpenAI Embedding 端点
$embeddingEndpoint = 'https://your-aoai.openai.azure.com/'
$embeddingKey = (Get-Secret -Name 'AzureOpenAI-Key' -AsPlainText)
$embeddingDeployment = 'text-embedding-ada-002'

# 定义函数：调用 Embedding API 生成向量
function Get-Embedding {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $url = "$embeddingEndpoint/openai/deployments/$embeddingDeployment/embeddings?api-version=2024-06-01"
    $headers = @{
        'api-key'  = $embeddingKey
        'Content-Type' = 'application/json'
    }
    $body = @{
        input = $Text
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    return $response.data[0].embedding
}

# 定义函数：批量导入文档到搜索索引
function Import-DocumentsToIndex {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$AdminKey,

        [Parameter(Mandatory)]
        [string]$IndexName,

        [Parameter(Mandatory)]
        [array]$Documents
    )

    $url = "https://$ServiceName.search.windows.net/indexes/$IndexName/docs/index?api-version=2024-07-01"
    $headers = @{
        'api-key'      = $AdminKey
        'Content-Type' = 'application/json'
    }

    # 构建批量操作请求
    $batch = @()
    foreach ($doc in $Documents) {
        $batch += @{ '@search.action' = 'uploadOrMerge' } + $doc
    }

    $body = @{ value = $batch } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    return $response
}

# 读取本地文档目录并生成导入数据
$documentsPath = '/data/knowledge-base'
$files = Get-ChildItem -Path $documentsPath -Include '*.md', '*.txt' -Recurse

$importBatch = @()
$counter = 0

foreach ($file in $files) {
    $counter++
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    Write-Host "处理文档 [$counter/$($files.Count)]: $($file.Name)"

    # 生成内容向量（截取前 8000 字符避免 token 限制）
    $textForEmbedding = $content.Substring(0, [Math]::Min($content.Length, 8000))
    $vector = Get-Embedding -Text $textForEmbedding

    $importBatch += @{
        id           = $file.BaseName.GetHashCode().ToString('x8')
        title        = $file.BaseName
        content      = $content
        category     = $file.Directory.Name
        tags         = @($file.Extension.TrimStart('.'), $file.Directory.Name)
        contentVector = $vector
        createdDate  = $file.CreationTime.ToString('o')
    }

    # 每 100 篇批量提交一次
    if ($importBatch.Count -ge 100) {
        $result = Import-DocumentsToIndex `
            -ServiceName $serviceName `
            -AdminKey $adminKey `
            -IndexName 'documents-index' `
            -Documents $importBatch
        Write-Host "批量导入完成，状态: $($result.value[0].status)"
        $importBatch = @()
    }
}

# 提交剩余文档
if ($importBatch.Count -gt 0) {
    $result = Import-DocumentsToIndex `
        -ServiceName $serviceName `
        -AdminKey $adminKey `
        -IndexName 'documents-index' `
        -Documents $importBatch
    Write-Host "最终批次导入完成，文档数: $($importBatch.Count)"
}

Write-Host "全部文档导入完毕，共处理 $counter 篇"
```

执行结果示例：

```text
处理文档 [1/247]: powershell-best-practices.md
处理文档 [2/247]: azure-vm-management.md
处理文档 [3/247]: security-baseline-audit.md
...
处理文档 [100/247]: container-orchestration.md
批量导入完成，状态: true
处理文档 [101/247]: devops-pipeline.md
...
处理文档 [200/247]: api-gateway-config.md
批量导入完成，状态: true
处理文档 [201/247]: monitoring-setup.md
...
处理文档 [247/247]: network-troubleshooting.md
最终批次导入完成，文档数: 47
全部文档导入完毕，共处理 247 篇
```

## 混合搜索与 RAG 管道

Azure AI Search 最强大的能力之一是支持关键词搜索和向量搜索的组合查询，即"混合搜索"。混合搜索能够同时利用精确的关键词匹配和语义级别的相似度计算，显著提升搜索的召回率和准确率。将混合搜索结果喂给大语言模型，就构成了一个完整的 RAG（检索增强生成）管道，让 LLM 基于企业私有数据生成可靠的回答。

```powershell
# 定义函数：执行混合搜索（关键词 + 向量）
function Invoke-HybridSearch {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$AdminKey,

        [Parameter(Mandatory)]
        [string]$IndexName,

        [Parameter(Mandatory)]
        [string]$QueryText,

        [int]$Top = 5
    )

    # 生成查询文本的向量
    $queryVector = Get-Embedding -Text $QueryText

    $url = "https://$ServiceName.search.windows.net/indexes/$IndexName/docs/search?api-version=2024-07-01"
    $headers = @{
        'api-key'      = $AdminKey
        'Content-Type' = 'application/json'
    }

    # 构建混合查询：同时包含关键词和向量搜索
    $searchBody = @{
        search = $QueryText
        top    = $Top
        select = @('id', 'title', 'content', 'category', 'tags', 'createdDate')
        vectorQueries = @(
            @{
                kind         = 'vector'
                vector       = $queryVector
                fields       = 'contentVector'
                k            = $Top
            }
        )
        semanticConfiguration = 'semanticConfig'
        queryType    = 'semantic'
        captions     = 'extractive'
        answers      = 'extractive'
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $searchBody
    return $response
}

# 定义函数：RAG 管道 - 检索增强生成
function Invoke-RAGPipeline {
    param(
        [Parameter(Mandatory)]
        [string]$Question,

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$AdminKey,

        [Parameter(Mandatory)]
        [string]$IndexName
    )

    Write-Host "用户问题: $Question"
    Write-Host ('=' * 60)

    # 第一步：检索相关文档
    Write-Host "[步骤 1] 执行混合搜索..."
    $searchResult = Invoke-HybridSearch `
        -ServiceName $ServiceName `
        -AdminKey $AdminKey `
        -IndexName $IndexName `
        -QueryText $Question `
        -Top 5

    Write-Host "检索到 $($searchResult.value.Count) 篇相关文档"

    # 第二步：构建上下文
    $context = ($searchResult.value | ForEach-Object {
        "标题: $($_.title)`n分类: $($_.category)`n内容: $($_.content.Substring(0, [Math]::Min($_.content.Length, 500)))..."
    }) -join "`n---`n"

    # 第三步：调用 LLM 生成回答
    Write-Host "[步骤 2] 调用大语言模型生成回答..."
    $llmEndpoint = 'https://your-aoai.openai.azure.com/'
    $llmKey = (Get-Secret -Name 'AzureOpenAI-Key' -AsPlainText)
    $llmDeployment = 'gpt-4o'

    $systemPrompt = @(
        '你是一个企业知识库助手。'
        '请仅根据以下检索到的文档内容回答用户问题。'
        '如果文档中没有相关信息，请明确说明。'
        '回答时请标注引用来源的文档标题。'
    ) -join ''

    $chatUrl = "$llmEndpoint/openai/deployments/$llmDeployment/chat/completions?api-version=2024-06-01"
    $chatHeaders = @{
        'api-key'      = $llmKey
        'Content-Type' = 'application/json'
    }
    $chatBody = @{
        messages = @(
            @{ role = 'system'; content = $systemPrompt },
            @{ role = 'user';   content = "参考文档：`n$context`n`n问题：$Question" }
        )
        temperature = 0.3
        max_tokens  = 1000
    } | ConvertTo-Json -Depth 5

    $llmResponse = Invoke-RestMethod -Uri $chatUrl -Method Post -Headers $chatHeaders -Body $chatBody
    $answer = $llmResponse.choices[0].message.content

    # 第四步：输出结果
    Write-Host "[步骤 3] 生成结果:"
    Write-Host ('=' * 60)
    Write-Host $answer
    Write-Host ('=' * 60)

    # 输出引用来源
    Write-Host "`n参考文档:"
    $searchResult.value | ForEach-Object -Begin { $i = 1 } -Process {
        $score = if ($_. '@search.score') { $_.'@search.score'.ToString('F4') } else { 'N/A' }
        Write-Host "  [$i] $($_.title) (相关度: $score, 分类: $($_.category))"
        $i++
    }

    return @{
        Answer    = $answer
        Sources   = $searchResult.value | Select-Object -Property title, category
        DocCount  = $searchResult.value.Count
    }
}

# 执行 RAG 查询示例
$result = Invoke-RAGPipeline `
    -Question '如何在生产环境中配置 PowerShell 远程管理的安全基线？' `
    -ServiceName $serviceName `
    -AdminKey $adminKey `
    -IndexName 'documents-index'
```

执行结果示例：

```text
用户问题: 如何在生产环境中配置 PowerShell 远程管理的安全基线？
============================================================
[步骤 1] 执行混合搜索...
检索到 5 篇相关文档
[步骤 2] 调用大语言模型生成回答...
[步骤 3] 生成结果:
============================================================
根据检索到的文档，生产环境中配置 PowerShell 远程管理安全基线需要关注以下几个方面：

1. **启用 WinRM over HTTPS**（来源：security-baseline-audit.md）
   生产环境必须使用 HTTPS 传输，避免凭据在网络上明文传输...

2. **配置 Just Enough Administration (JEA)**（来源：powershell-best-practices.md）
   通过 JEA 端点限制远程用户可执行的命令集...

3. **设置 Constrained Language Mode**（来源：security-hardening-guide.md）
   在非管理员会话中启用受限语言模式，阻止危险的 .NET 调用...
============================================================

参考文档:
  [1] security-baseline-audit.md (相关度: 0.9234, 分类: security)
  [2] powershell-best-practices.md (相关度: 0.8871, 分类: operations)
  [3] security-hardening-guide.md (相关度: 0.8653, 分类: security)
  [4] winrm-https-config.md (相关度: 0.8412, 分类: networking)
  [5] jea-endpoint-setup.md (相关度: 0.8198, 分类: security)
```

## 注意事项

1. **API 版本兼容性**：Azure AI Search 的 REST API 版本迭代较快，本文使用 `2024-07-01` 版本。向量搜索和语义排序等高级功能在不同 API 版本中的行为可能存在差异，升级前务必查阅官方迁移指南并在测试环境中验证。

2. **向量维度必须匹配**：索引中向量字段的 `dimensions` 参数必须与 Embedding 模型输出维度严格一致。例如 `text-embedding-ada-002` 输出 1536 维，`text-embedding-3-small` 输出 1536 维（默认），但可配置为更低的维度。导入文档和查询时使用的 Embedding 模型也必须相同。

3. **批量导入的大小限制**：单次批量请求的文档数上限为 1000 篇，请求体总大小不超过大约 16 MB。对于大型文档，建议先进行文本分块（chunking），将长文档拆分为 500-1000 token 的片段后再分别生成向量并导入。

4. **搜索服务定价层级**：语义排序和向量搜索功能需要 Standard 及以上定价层级才可使用。Basic 层级支持基础的全文检索，但不支持向量字段和语义查询。生产环境建议使用 Standard 2 或更高层级以获得最佳性能。

5. **密钥安全与托管身份**：示例中使用管理密钥直接认证，仅适合演示和开发环境。生产环境应使用 Azure 托管身份（Managed Identity）或基于角色的访问控制（RBAC）来管理搜索服务的访问权限，避免在脚本中硬编码密钥。可配合 `Get-Secret` 从 Azure Key Vault 获取凭据。

6. **混合搜索结果排序**：混合搜索会将关键词匹配得分和向量相似度得分进行融合排序。如果发现纯关键词搜索结果反而优于混合搜索，可以尝试调整 `semanticConfiguration` 的权重或使用 `scoringProfiles` 自定义评分逻辑，确保业务场景下的搜索质量最优。
