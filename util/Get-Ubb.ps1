$DebugPreference = 'Continue'
$ubbPath = '..\.ubb'
$sourcePath = '..\source\_posts\'
$sitePrefix = 'http://blog.vichamp.com'

if (gmo Blog) { rmo Blog }
ipmo ./Blog.psm1

function Remove-More ($text) {
    #return ($text -split '<!--more-->')[0].TrimEnd()
    return $text -split '<!--more-->\r\n' | Out-String
}

function Replace-Code ($text) {
    $pattern = @'
(\r?\n){2,}
(?<CODE>(^([ ]{4}|\t).*?$)+?)
(\r?\n){2,}
'@

    $text = [Regex]::Replace($text, $pattern, {
        param($m)

        $code = $m.Groups['CODE'].Value
        $resultlist = new-object System.Collections.Specialized.StringCollection
        $regex = [regex] '(?m)^([ ]{4}|\t)(?<CODE>.*)$'
        $match = $regex.Match($code)
        while ($match.Success) {
	        $resultlist.Add($match.Groups['CODE'].Value.TrimEnd()) | out-null
	        $match = $match.NextMatch()
        } 

        $code = ($resultlist | Out-String).TrimEnd()
        $template = @'

[code]
{0}
[/code]

'@
        return $template -f $code
    }, [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace -bor
      [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
      [System.Text.RegularExpressions.RegexOptions]::Multiline)

    return $text
}

function Replace-Quote ($text) {
    $pattern = @'
(\r?\n){2,}
(?<QUOTE>(^> .*?$)+?)
(\r?\n){2,}
'@

    $text = [Regex]::Replace($text, $pattern, {
        param($m)

        $quote = $m.Groups['QUOTE'].Value
        $resultlist = new-object System.Collections.Specialized.StringCollection
        $regex = [regex] '(?m)^> (?<QUOTE>.*)$'
        $match = $regex.Match($quote)
        while ($match.Success) {
	        $resultlist.Add($match.Groups['QUOTE'].Value.TrimEnd()) | out-null
	        $match = $match.NextMatch()
        } 

        $quote = ($resultlist | Out-String).TrimEnd()
        $template = @'

[quote]
{0}
[/quote]

'@
        return $template -f $quote
    }, [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace -bor
      [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
      [System.Text.RegularExpressions.RegexOptions]::Multiline)

    return $text
}

function Replace-Picture ($text) {
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)!\[(?<ALT>.*?)\]\((?<URL>\/{1}.*?)\)', ('[img]{0}${{URL}}[/img]' -f $sitePrefix)
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)!\[(?<ALT>.*?)\]\((?<URL>.*?)\)', '[img]${URL}[/img]'
    return $text
}

function Replace-Url ($text) {
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)\[(?<ALT>.*?)\]\((?<URL>\/{1}.*?)\)', ('[url={0}${{URL}}]${{ALT}}[/url]' -f $sitePrefix)
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)\[(?<ALT>.*?)\]\((?<URL>.*?)\)', '[url=${URL}]${ALT}[/url]'
    return $text
}

function Replace-Italic ($text) {
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)[*|_]{1}(?<INNER_TEXT>.+?)[*|_]{1}(?>)', '[i]${INNER_TEXT}[/i]'
    return $text
}

function Replace-Bold ($text) {
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)[*|_]{2}(?<INNER_TEXT>.+?)[*|_]{2}(?>)', '[b]${INNER_TEXT}[/b]'
    return $text
}

function Replace-Delete ($text) {
    $text = $text -creplace '(?m)(?<=^(?!    |\t).*?)~{1}(?<INNER_TEXT>.+?)~{1}(?>)', '[s]${INNER_TEXT}[/s]'
    return $text
}

if (!(Test-Path $ubbPath)) {
    md $ubbPath
}

dir (Join-Path $sourcePath *.md) | foreach {
#dir ./2014-07-18-test-ubb.md | foreach {
#dir ..\source\_posts\2014-07-21-forward-chinese-text-into-clipboard.md | foreach {
    echo $_.Name
    $original = Read-HexoBlog $_

    $text = $original.Body
    $text = Remove-More $text
    $text = Replace-Code $text
    $text = Replace-Quote $text
    $text = Replace-Picture $text
    $text = Replace-Url $text
    $text = Replace-Bold $text
    $text = Replace-Italic $text
    $text = Replace-Delete $text

    $template = @'
原始链接：[url={0}]{1}[/url]
发表日期：{2:yyyy-MM-dd}
[hr]
{3}
'@

    $result = $template -f "$sitePrefix/$($original.Url)", $original.Meta.title, $original.Date, $text
    $newPath = (Join-Path $ubbPath $_.BaseName) + '.ubb.txt'
    # Write-Debug $result
    # return
    sc $newPath $result -Encoding UTF8
}