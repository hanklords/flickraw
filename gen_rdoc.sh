#git merge -s ours --no-commit master
#git read-tree --prefix=master/ -u master
#git commit -m "Merge master project as our subdirectory"
git merge -s subtree master
cd master
rake rdoc
rsync -r html/* ..
rm -rf html
