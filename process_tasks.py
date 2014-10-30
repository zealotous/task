#!/usr/bin/env python
# -*- coding: utf-8 -*-
from functools import lru_cache
from queue import Queue
from threading import Thread
from time import sleep
import pymysql

from settings import DATABASE_SETTINGS
 

THREADS_NUM = 100
CONNECTIONS = []
 
# Кешируем функцию, вычисляющую ряд фибоначчи
@lru_cache(maxsize=None)
def fib(n):
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)
 
# Предварительно вычилсяем ряд фибоначчи
fib(20)
 
 
def fib_thread(i, q):
    while True:
        task_id, n = q.get()
        result = fib(n)
        print('task.id: %s\nfib(%s): %s' % (task_id, n, result))
        conn = CONNECTIONS[i]
        c = conn.cursor()
        c.execute('insert results(task_id, result) '
                         'values (%s, %s)', (task_id, result))
        c.close()
        conn.commit()
        q.task_done()
 
 
if __name__ == '__main__':
    fib_queue = Queue()
    for i in range(THREADS_NUM):
        w = Thread(target=fib_thread, args=(i, fib_queue))
        w.setDaemon(True)
        w.start()

    # Создаём пул подключений к базе данных
    CONNECTIONS = [pymysql.connect(**DATABASE_SETTINGS) 
                   for _ in range(THREADS_NUM)]

    conn = pymysql.connect(**DATABASE_SETTINGS)
    c = conn.cursor()
    c.execute('select id, number from tasks')
    for id_, number in c.fetchall():
        fib_queue.put((id_, number))
 
    fib_queue.join()
