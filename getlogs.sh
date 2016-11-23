#!/bin/bash

s3cmd sync s3://logs.wordpressdocker.com/ logs/
cat logs/* >> sitelog.txt
s3cmd rm s3://logs.wordpressdocker.com/logs*
cat logs/*
rm logs/*
