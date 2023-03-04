#!/bin/bash

function list_short() {
    ls /proc | egrep '[0-9]+' | sort -n | column
}

function list_long() {
    for pid in list_short
}
