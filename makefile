#!/usr/bin/env make -f

all:
	# none

start: ./docker-compose.yml
	$^ up -d
	$^ logs -t

stop: ./docker-compose.yml
	$^ kill
	$^ down -v

%: ./docker-compose.yml
	$^ exec $@ bash
