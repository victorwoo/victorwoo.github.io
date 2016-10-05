Param ($Short = $false)

$sourcePath = '..\source\_posts\'
$sitePrefix = 'http://blog.vichamp.com'

if (gmo Blog) { rmo Blog }
ipmo ./Blog.psm1

dir "$sourcePath*.md" | sort | foreach {
    $hexoBlog = Read-HexoBlog $_

    $url = ("{0}/{1}/{2}" -f $sitePrefix, ($hexoBlog.Meta.categories -join '/'), $hexoBlog.Url)
    
    if ($Short) { $url = Get-ShortedUrl $url }
    
    Write-Host $hexoBlog.Meta.title
    Write-Host $url

    echo $hexoBlog.Meta.title
    echo $url
} | Out-String | Out-Clipboard