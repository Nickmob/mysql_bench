#!/bin/bash
# Скрипт для запуска тестов производительности MySQL
# Настройки

# База для sysbench
db_sysbench=sbtest

# База для TPCC
db_tpcc=sbt

# Пользователь
mysql_user=root

# Пароль
mysql_pass=1

# Хост
mysql_host='127.0.0.1'

# Порт
mysql_port=3306

# Количество потоков
threads_num=4

# Время теста
bench_time=10

# Размер таблицы (sysbench)
table_size=100000

# Количество таблиц (sysbench)
table_num=2

cd  /usr/share/sysbench/

# Создаём БД
mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench
mysqladmin -u$mysql_user -p$mysql_pass create $db_sysbench

# Sysbench

# Point select
sysbench ./oltp_point_select.lua --threads=$threads_num --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size prepare
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'
sysbench ./oltp_point_select.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size --range_selects=off --db-ps-mode=disable --report-interval=0 --histogram=on run

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench
mysqladmin -u$mysql_user -p$mysql_pass create $db_sysbench

# RO traffic
sysbench ./oltp_read_only.lua --threads=$threads_num --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size prepare
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'
sysbench ./oltp_read_only.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size --range_selects=off --db-ps-mode=disable --report-interval=0 --histogram=on run
sysbench ./oltp_read_only.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size --range_selects=off --db-ps-mode=disable --report-interval=0 cleanup

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench
mysqladmin -u$mysql_user -p$mysql_pass create $db_sysbench

# RW traffic
sysbench ./oltp_read_write.lua --threads=$threads_num --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size prepare
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'
sysbench ./oltp_read_write.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --delete_inserts=10 --index_updates=10 --non_index_updates=10 --table-size=$table_size --db-ps-mode=disable --report-interval=0 --histogram=on run
sysbench ./oltp_read_write.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --delete_inserts=10 --index_updates=10 --non_index_updates=10 --table-size=$table_size --db-ps-mode=disable --report-interval=0 cleanup

mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'
mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench

# TPCC Percona
cd /usr/share/sysbench/percona

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_tpcc
mysqladmin -u$mysql_user -p$mysql_pass create $db_tpcc
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'

./tpcc.lua --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-host=$mysql_host --mysql-port=$mysql_port --mysql-db=$db_tpcc --threads=$threads_num --tables=$table_num --scale=2 prepare
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'

./tpcc.lua --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-host=$mysql_host --mysql-port=$mysql_port --mysql-db=$db_tpcc --time=$bench_time --threads=$threads_num --report-interval=0 --tables=$table_num --scale=2 --db-driver=mysql --histogram=on run

mysqladmin -u$mysql_user -p$mysql_pass -f $db_tpcc