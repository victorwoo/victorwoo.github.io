powershell -NoProfile -ExecutionPolicy Unrestricted .\Export-PSTipsIndex.ps1
powershell -NoProfile -ExecutionPolicy Unrestricted .\Get-Images.ps1

cd ..

git.exe add --all
git.exe commit -m "(auto commit message)"
git.exe push --porcelain --progress --recurse-submodules=check origin refs/heads/master:refs/heads/master

hexo generate&&hexo deploy
pause