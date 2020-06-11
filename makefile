#!/usr/bin/env make -f

REPLICAS := 3

all: build start
	# none

build: ./dockerfile
	$^ .

cluster: ./docker-compose.yml
	$^ up -d --scale nodes=$(REPLICAS)

start: ./docker-compose.yml
	$^ up -d
	$^ logs -t

stop: ./docker-compose.yml
	$^ kill
	$^ down -v

logs: ./docker-compose.yml
	$^ logs -tf

%: ./docker-compose.yml
	$^ exec $@ bash
