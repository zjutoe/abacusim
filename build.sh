#!/bin/bash

gcc -fPIC -c syscall.c
gcc -shared -o libsyscall.so syscall.o

