#!/bin/bash

s3cmd sync -r --no-mime-magic --acl-public site/ s3://www.wordpressdocker.com
