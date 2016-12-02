#!/bin/bash

cat sitelog.txt |cut -c 119-|sort| uniq -s 0 -w 10 | grep -vi google | grep -vi phantom | grep -vi spider | grep -vi bot | sed 's/\s.*$//' | wc
