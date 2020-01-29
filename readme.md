
# Kafka and Confluent in Docker and Compose & Swarm

- Usuable in both standalone and custer forms
- Change network driver to `overlay` for swarm installations

## Building

### Docker:

```
docker build -t pvtmert/confluent -f dockerfile .
```

### Compose:

```
docker-compose build
```

## Running

### Docker:

```
docker run --name=somecluster --rm -it pvtmert/confluent somecluster
```

### Compose:

```
docker-compose -p kafka -f docker-compose.yml up --scale nodes=3
```

### Swarm:

```
cat docker-compose.yml \
| sed 's/expose:/ports:/' \
| sed 's/driver: bridge/driver: overlay/' \
| docker stack deploy -c - --prune kafka
```

