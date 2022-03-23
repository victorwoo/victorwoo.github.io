$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$downloadPath = '../source/img'
$relateUrl = '/img/'
$sourcePath = '../source/_posts'

function Download-Picture($url, $fileName) {
    Write-Host "downloading $url to $fileName"
    $fullPath = Join-Path $downloadPath $fileName
    Invoke-WebRequest -Uri $url -OutFile $fullPath
    return $?
}

function Get-Picture($file) {
    $index = 1
    $fileBaseName = ([System.IO.FileInfo]$file).BaseName
    [System.Collections.Generic.Dictionary[[string],[string]]] $dict = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]'

    Get-Content $file -Encoding utf8NoBOM | ForEach-Object {
        $regex = [regex] '(?mx)(?<!^(\s{4,}|\t).*)!\[(?<desc>.*?)\]\((?<url>.*?)\)'
        $matches = $regex.Matches($_)
        
        if ($matches.Count) {
            $matches.ForEach({
                $fullMatch = $_.Value
                $desc = $_.Groups['desc'].Value
                $url = $_.Groups['url'].Value
                if ($url -like 'http*') {
                    $extension = [System.IO.Path]::GetExtension($url).ToLower()
                    $targetPath = "$fileBaseName-{0:d3}$extension" -f $index++
                    $result = Download-Picture $url $targetPath
                    if ($result) {
                        $dict.Add($url, $targetPath)
                    }
                }
            })
        }
    }

    $newContent = Get-Content $file -Encoding utf8NoBOM | ForEach-Object {
        $line = $_
        $dict.Keys | ForEach-Object {
            $url = $_
            $newPath = $relateUrl + $dict[$url]
            $line = [string]$line.Replace($url, $newPath)
        }
        $line
    }

    #$bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
    #sc $file $bytes -Encoding Byte
    Set-Content $file $newContent.TrimEnd() -Encoding utf8NoBOM
    #[IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
}

Get-ChildItem "$sourcePath/*.md" | ForEach-Object {
    Write-Output $_
    Get-Picture $_
}