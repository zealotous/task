#!/usr/bin/env bash

REPO=https://github.com/zealotous/task.git
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=root
DATABASE_PASS=
DATABASE_DB=task
N=10000
ROUTINE=pro
TABLE=tasks


function read_var {
    local name=$1
    local val
    read -p "Enter $name[${!name}]: " val
    if [ -z $val ]; then
        val=${!n}
    fi
    declare -g "$name"="$val"
    echo -e "$name=$val\n"
}
__DIR__=`pwd`
# клонируем репозиторий если в текущей папке нет bootstrap.sh
BOOTSTRAP="$__DIR__/bootstrap.sh"
if [ ! -e $BOOTSTRAP ]; then
    git clone "$REPO"
    if [ $? -ne 0 ]; then
        echo "can't clone repo"
        exit 1
    fi
    cd task
    __DIR__=`pwd`
    exec bash $__DIR__/bootstrap.sh
    exit
fi

for n in 'DATABASE_HOST' 'DATABASE_PORT' 'DATABASE_USER' 'DATABASE_DB'; do
     read_var $n
done;

# Не отображаем введённый пароль
read -s -p "Enter DATABASE_PASS[]: " DATABASE_PASS
echo -e "\n"

for n in 'DATABASE_HOST' 'DATABASE_PORT' 'DATABASE_USER' 'DATABASE_DB'; do
     echo "$n=${!n}"
done;

mysql -h$DATABASE_HOST -u$DATABASE_USER -p$DATABASE_PASS --port=$DATABASE_PORT << SQL-SCRIPT

select 'creating database and tables';
drop database if exists $DATABASE_DB;
create database $DATABASE_DB;
use $DATABASE_DB;

create table $TABLE (
    id int not null auto_increment,
    number int not null,
    primary key (id)
)
collate='utf8_general_ci'
engine=InnoDB;

create table results (
    id int not null auto_increment,
    task_id int null,
    result int null,
    primary key (id)
)
collate='utf8_general_ci'
engine=InnoDB;

/* Наполняем таблицу данными */
delimiter $$

create procedure $ROUTINE(num int) 
begin
    set @x = 0; 
    while @x <= num do
        set @x = @x + 1;
        insert $TABLE (number) values(floor(1 + rand() * 20)); 
    end while; 
end
$$
delimiter ;;

select 'filling table "$TABLE"';
call $ROUTINE($N);

drop procedure if exists $ROUTINE;

SQL-SCRIPT

__DIR__=`pwd`

# Если скрипт выполнился удачно сохраняем введённые настройки
# И выполняем python script
if [ $? -eq 0 ]; then
    # Сохраняем настройки базы данных в файл
    echo "
DATABASE_SETTINGS = {'host': '$DATABASE_HOST',
                     'port': $DATABASE_PORT,
                     'db': '$DATABASE_DB',
                     'user': '$DATABASE_USER',
                     'passwd': '$DATABASE_PASS', }
" > settings.py
    if [ ! -e "$__DIR__/process_tasks.py" ]; then
        echo "file does not exists $__DIR__/process_tasks.py"
        exit 1
    fi
    python $__DIR__/process_tasks.py
fi
