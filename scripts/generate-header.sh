#!/bin/sh
echo "" >> /.header
echo "~~~ Welcome to the OneZero Developer Environment for $1 ~~~" >> /.header
echo "" >> /.header
echo "==== Runtime & Tool Versions ====" >> /.header
if [ $2 ]; then echo "node $(node -v)" >> /.header; fi
if [ $2 ]; then echo "npm $(npm -v)" >> /.header; fi
/bin/deno --version >> /.header
echo "" >> /.header
echo "Have fun coding :)" >> /.header
echo "" >> /.header