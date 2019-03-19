Add-Type -Path '.\YamlDotNet.3.2.1\lib\net35\YamlDotNet.dll'

function Get-YamlObj ($yamlString) {
    $input = New-Object System.IO.StringReader $yamlString
    $yaml = New-Object YamlDotNet.RepresentationModel.YamlStream

    $yaml.Load($input)
    $mapping = [YamlDotNet.RepresentationModel.YamlMappingNode]$yaml.Documents[0].RootNode

    $keys = $mapping.Children[0].Keys
    $obj = [ordered]@{}
    $keys | foreach {
        $key = $_.Value
        $value = $mapping.Children[0][$_].Value
        #$obj | Add-Member -MemberType NoteProperty -Name $key -Value $value
        $obj[$key] = $value
    }
    echo $obj
}

function Get-YamlString ($yaml) {
    $serializer = New-Object YamlDotNet.Serialization.Serializer 0, $null
    $output = New-Object System.IO.StringWriter

    $serializer.Serialize($output, $yaml);
    return $output.ToString().Trim()
}

function Get-Blocks ($path) {
    $blocks = @()
    $lines = @()
    $currentBlock = @()
    
    $separactor = '---'
    $lineNumber = 0
    $lines = Get-Content $path -Encoding utf8NoBOM
    foreach ($line in $lines) {
        if ($line.Trim() -eq $separactor) {
            # 解析到分隔符
            if ($lineNumber -ne 0) {
                # 首行遇到分隔符，块号不增加
                $blocks += ($currentBlock | Out-String).Trim()
                $currentBlock = @()
            }
        } else {
            # 解析到文本（非分隔符）
            $currentBlock += $line
        }
        $lineNumber++
    }

    if ($currentBlock.Length) {
        # 最后一块。
        $blocks += ($currentBlock | Out-String).Trim()
    }

    return $blocks
}

function Read-JekyllBlog ($path) {
    $blocks = Get-Blocks $path
    $date = Get-BlogDate $path
    return [ordered]@{
        Meta = Get-YamlObj $blocks[0];
        Body = $blocks[1] -split "`r`n" | where { $_ -notlike '*{%*%}*' } | Out-String;
        Date = $date
    }
}

function Read-HexoBlog ($path) {
    $blocks = Get-Blocks $path
    $yamlObj = Get-YamlObj $blocks[0];
    
    $date = [datetime]$yamlObj.date
    $categoriesPart = $yamlObj.categories -join '/'
    $datePart = '{0:d2}/{1:d2}/{2:d2}' -f $date.Year, $date.Month, $date.Day
    $path -cmatch '.*?(?<YEAR>\d{4})-(?<MONTH>\d{2})-(?<DAY>\d{2})-(?<FILE_NAME>[-\w]+)\.md'
    $namePart = $Matches.FILE_NAME
    

    #$url = $path -creplace '.*?(?<YEAR>\d{4})-(?<MONTH>\d{2})-(?<DAY>\d{2})-(?<FILE_NAME>[-\w]+)\.md', 
    #    @($categories, '${YEAR}/${MONTH}/${DAY}/${FILE_NAME}/') -join '/'
    $url = @($categoriesPart, $datePart, $namePart, '') -join '/'

    return [ordered]@{
        Meta = $yamlObj;
        Body = $blocks[1] -split "`r`n" | Out-String;
        Date = (Get-Date $date);
        Url = $url;
    }
}

function Out-HexoBlog ($yamlObj, $body) {
    $serializer = New-Object YamlDotNet.Serialization.Serializer 0, $null
    $output = New-Object System.IO.StringWriter

    $yamlObj.date = ([datetime]$yamlObj.date).ToString('yyyy-MM-dd HH:mm:ss');

    $serializer.Serialize($output, $yamlObj);
    $hexoFrontMatterString = $output.ToString().Trim()

    return @"
---
{0}
---
{1}
"@ -f $hexoFrontMatterString, $body.Trim()
}

function Get-ShortedUrl ($originalUrl) {
    $result = Invoke-RestMethod -Method Post -Uri 'http://dwz.cn/create.php' -Body "url=$originalUrl"
    if ($result.status -ne 0) { Write-Error "$originalUrl 解析失败" }
    return $result.tinyurl
}

function Out-Clipboard {
    [CmdletBinding()]
    Param
    (
        [Parameter(mandatory=$true,ValueFromPipeline=$true)]
        [string]$Text
    )

    Add-Type -Assembly PresentationCore
    [Windows.Clipboard]::SetText($text)
}

Export-ModuleMember *