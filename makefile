#!/usr/bin/env make -f

all: build start
	# none

build: ./dockerfile
	$^ .

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
