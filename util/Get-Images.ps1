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

    cat $file -Encoding UTF8 -Raw | % {
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

    $newContent = cat $file -Encoding UTF8 -Raw | % {
        $line = $_
        $dict.Keys | % {
            $url = $_
            $newPath = $relateUrl + $dict[$url]
            $line = [string]$line.Replace($url, $newPath)
        }
        $line
    }

    #$bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
    #sc $file $bytes -Encoding Byte
    sc $file $newContent.TrimEnd() -Encoding UTF8
    #[IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
}

dir "$sourcePath/*.md" | % {
    Get-Picture $_
}