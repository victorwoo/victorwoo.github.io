cd ..

git.exe add --all
git.exe commit -m "(auto commit message)"
git.exe push --porcelain --progress --recurse-submodules=check origin refs/heads/source:refs/heads/source