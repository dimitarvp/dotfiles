#! /bin/sh

docker system prune -f
docker volume prune -f
docker image prune -f
docker container prune -f
docker buildx prune -f
