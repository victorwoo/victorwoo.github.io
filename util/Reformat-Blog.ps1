if (gmo Blog) { rmo Blog }
ipmo ./Blog.psm1

dir ..\source\_posts\*.md | foreach {
    echo $_.Name
    $original = Read-HexoBlog $_
    $out = Out-HexoBlog $original.Meta $original.Body
    sc $_ $out -Encoding UTF8
}