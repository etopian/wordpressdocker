#!/bin/bash

git add .
git commit -m'commit' .
git push
mkdocs build
s3cmd sync -r --no-mime-magic --acl-public site/ s3://www.wordpressdocker.com
