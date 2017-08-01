powershell -NoProfile -ExecutionPolicy Unrestricted .\Export-PSTipsIndex.ps1
powershell -NoProfile -ExecutionPolicy Unrestricted .\Get-Images.ps1

dos2unix.exe ..\source\_posts\*.md

cd ..

git.exe add --all
git.exe commit -m "(auto commit message)"
git.exe push --porcelain --progress --recurse-submodules=check origin refs/heads/source:refs/heads/source

hexo generate&&hexo deploy
pause