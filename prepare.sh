#!/bin/bash

sudo apt update
sudo apt install sysbench git

cd  /usr/share/sysbench/
git clone https://github.com/Percona-Lab/sysbench-tpcc /usr/share/sysbench/percona

