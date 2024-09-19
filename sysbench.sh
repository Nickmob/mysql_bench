#!/bin/bash
# Скрипт для запуска тестов производительности MySQL
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
bench_time=30
# Размер таблицы (sysbench)
table_size=2000000
# Количество таблиц (sysbench)
table_num=2
# Опции sysbench
sysb_opts='--histogram=off'

cd  /usr/share/sysbench/

# Создаём БД
mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench > /dev/null
mysqladmin -u$mysql_user -p$mysql_pass create $db_sysbench > /dev/null

# Sysbench

# Point select
sysbench ./oltp_point_select.lua --threads=$threads_num --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size prepare > /dev/null
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();' > /dev/null
echo '>>>>>>>>>>> Test: oltp_point_select.lua <<<<<<<<<<<<'
sysbench ./oltp_point_select.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size --range_selects=off --db-ps-mode=disable --report-interval=0 $sysb_opts run

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench > /dev/null
mysqladmin -u$mysql_user -p$mysql_pass create $db_sysbench > /dev/null

# RO traffic
sysbench ./oltp_read_only.lua --threads=$threads_num --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size prepare > /dev/null
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();' > /dev/null
echo '>>>>>>>>>>> Test: oltp_read_only.lua <<<<<<<<<<<<'
sysbench ./oltp_read_only.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size --range_selects=off --db-ps-mode=disable --report-interval=0 $sysb_opts run
sysbench ./oltp_read_only.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size --range_selects=off --db-ps-mode=disable --report-interval=0 cleanup > /dev/null

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench > /dev/null
mysqladmin -u$mysql_user -p$mysql_pass create $db_sysbench > /dev/null

# RW traffic
sysbench ./oltp_read_write.lua --threads=$threads_num --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --table-size=$table_size prepare > /dev/null
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();'
echo '>>>>>>>>>>> Test: oltp_read_write.lua <<<<<<<<<<<<'
sysbench ./oltp_read_write.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --delete_inserts=10 --index_updates=10 --non_index_updates=10 --table-size=$table_size --db-ps-mode=disable --report-interval=0 $sysb_opts run
sysbench ./oltp_read_write.lua --threads=$threads_num --events=0 --time=$bench_time --mysql-host=$mysql_host --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-port=$mysql_port --tables=$table_num --delete_inserts=10 --index_updates=10 --non_index_updates=10 --table-size=$table_size --db-ps-mode=disable --report-interval=0 cleanup > /dev/null

mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();' > /dev/null
mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_sysbench > /dev/null

# TPCC Percona
cd /usr/share/sysbench/percona

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_tpcc > /dev/null
mysqladmin -u$mysql_user -p$mysql_pass create $db_tpcc > /dev/null
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();' > /dev/null

# Scale - количество warehouse. scale 100 + table 1 = 10 GB данных
./tpcc.lua --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-host=$mysql_host --mysql-port=$mysql_port --mysql-db=$db_tpcc --threads=$threads_num --tables=$table_num --scale=5 prepare > /dev/null
mysql -u$mysql_user -p$mysql_pass -e 'PURGE BINARY LOGS BEFORE NOW();' > /dev/null

echo '>>>>>>>>>>> Test: tpcc.lua <<<<<<<<<<<<'
./tpcc.lua --mysql-user=$mysql_user --mysql-password=$mysql_pass --mysql-host=$mysql_host --mysql-port=$mysql_port --mysql-db=$db_tpcc --time=$bench_time --threads=$threads_num --report-interval=0 --tables=$table_num --scale=5 --db-driver=mysql $sysb_opts run

mysqladmin -u$mysql_user -p$mysql_pass -f drop $db_tpcc > /dev/null
echo 'Done!'