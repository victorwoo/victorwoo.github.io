#!/bin/sh

pwsh -NoProfile -ExecutionPolicy Unrestricted ./Export-PSTipsIndex.ps1
pwsh -NoProfile -ExecutionPolicy Unrestricted ./Get-ImagesCore.ps1
pwsh -NoProfile -ExecutionPolicy Unrestricted ./Write-Comment.ps1

dos2unix ../source/_posts/*.md

cd ..

git add --all
git commit -m "(auto commit message)"
git push --porcelain --progress --recurse-submodules=check origin refs/heads/source:refs/heads/source

hexo generate&&hexo deploy

read -p "按回车键继续"