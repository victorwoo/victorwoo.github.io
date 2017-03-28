if (gmo Blog) { rmo Blog }
ipmo ./Blog.psm1

function Fix-File ($path) {
    $fileName = [IO.Path]::GetFileName($path)
    $fileDate = [datetime]$fileName.Substring(0, 10)
    $blocks = Get-Blocks $path 
    $yaml = $blocks[0]
    $body = $blocks[1]
    $yamlObj = Get-YamlObj $yaml
    $yamlDate = [datetime]$yamlObj.date
    
    if ($fileDate - $yamlDate -eq [timespan]::FromHours(8)) {
        $yamlObj.date = $fileDate
        $fileContent = Out-HexoBlog $yamlObj $body
        sc -Encoding UTF8 $path $fileContent
    }

    try {
        $old = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        .\dos2unix.exe $path
    } catch [System.Management.Automation.RemoteException] {
        $errmsg = $_.Exception.Message
        Write-Warning $errmsg
    } finally {
        # reset the erroractionpreference to what it was before
        $ErrorActionPreference = $old
    }
}
<#
$path = 'D:\interest\blog.vichamp.com\source\_posts\2017-03-22-invoking-a-script-block.md'
Fix-File $path

exit
#>
dir D:\interest\blog.vichamp.com\source\_posts\*.md | ForEach-Object {
    #$path = 'D:\interest\blog.vichamp.com\source\_posts\2017-03-22-invoking-a-script-block.md'
    $path = $_
    Fix-File $path
}

