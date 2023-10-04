# Docker Commands

## 1. Implementation:

### `docker pull`
- **Description**: Pulls an image from a Docker registry.
- **Example**: `docker pull nginx`
- **Public image repo**: https://hub.docker.com/

### `docker build`
- **Description**: Build a Docker image from a Dockerfile.
- **Example**: `docker build -t my-image:latest .`

### `docker run`
- **Description**: Create and start a container from an image on port 80.
- **Example**: `docker run -d -p 80:80 nginx`

## 2. Administration:

### `docker ps`
- **Description**: List running containers.
- **Example**: `docker ps`

### `docker stop`
- **Description**: Stop a running container.
- **Example**: `docker stop [container_id]`

### `docker rm`
- **Description**: Remove a stopped container.
- **Example**: `docker rm [container_id]`

### `docker rmi`
- **Description**: Remove a Docker image.
- **Example**: `docker rmi [image_id]`

### `docker volume ls`
- **Description**: List all volumes.
- **Example**: `docker volume ls`

### `docker network ls`
- **Description**: List all networks.
- **Example**: `docker network ls`

## 3. Monitoring:

### `docker stats`
- **Description**: Display real-time container statistics.
- **Example**: `docker stats`

### `docker logs`
- **Description**: Fetch the logs of a container.
- **Example**: `docker logs [container_id]`

### `docker top`
- **Description**: Display the running processes in a container.
- **Example**: `docker top [container_id]`

## 4. Troubleshooting:

### `docker inspect`
- **Description**: Return low-level information on a container or image.
- **Example**: `docker inspect [container_id/image_id]`

### `docker exec`
- **Description**: Execute a command inside a running container.
- **Example**: `docker exec -it [container_id] /bin/sh`

### `docker system df`
- **Description**: Display used space by Docker.
- **Example**: `docker system df`

### `docker system prune`
- **Description**: Remove unused data.
- **Example**: `docker system prune`

## Additional Resources:
- [Docker Documentation](https://docs.docker.com/)
- [Docker Cheat Sheet](https://github.com/wsargent/docker-cheat-sheet)
- [Docker Hub](https://hub.docker.com/)
