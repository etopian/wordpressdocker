<?php

$ips = shell_exec("cat sitelog.txt |cut -c 119-|sort| uniq -s 0 -w 10 | grep -vi google | grep -vi phantom | grep -vi spider | grep -vi bot | sed 's/\s.*$//'");

$ips = (explode("\n", $ips));

foreach($ips as $ip){
  print(shell_exec("geoiplookup ".$ip));
}
