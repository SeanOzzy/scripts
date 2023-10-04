# Dockerfile Commands

1. **`FROM`**
   - **Description**: Sets the base image for subsequent instructions.
   - **Example**: `FROM ubuntu:20.04`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#from)

2. **`LABEL`**
   - **Description**: Adds metadata to an image.
   - **Example**: `LABEL maintainer="john.doe@example.com"`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#label)

3. **`RUN`**
   - **Description**: Executes command(s) in a new layer and commits the result.
   - **Example**: `RUN apt-get update && apt-get install -y curl`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#run)
   - 
4. **`CMD`**
   - **Description**: Provides defaults for executing a container.
   - **Example**: `CMD ["echo", "Hello World"]`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#cmd)

5. **`ENTRYPOINT`**
   - **Description**: Configures a container to run as an executable.
   - **Example**: `ENTRYPOINT ["./app"]`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#entrypoint)

6. **`WORKDIR`**
   - **Description**: Sets the working directory for subsequent instructions.
   - **Example**: `WORKDIR /app`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#workdir)

7. **`ARG`**
   - **Description**: Defines a variable that users can pass at build-time.
   - **Example**: `ARG version=1.0`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#arg)

8. **`ENV`**
   - **Description**: Sets an environment variable.
   - **Example**: `ENV NODE_ENV=production`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#env)

9. **`ADD`**
   - **Description**: Copies files, directories, or remote files to the container.
   - **Example**: `ADD http://example.com/app.tar.gz /app/`
   - [Official Documentation](https://docs.docker.com/engine/reference/builder/#add)

10. **`COPY`**
    - **Description**: Copies new files or directories from source to the container's filesystem at destination.
    - **Example**: `COPY ./app /app`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#copy)

11. **`EXPOSE`**
    - **Description**: Informs Docker that the container listens on the specified network ports at runtime.
    - **Example**: `EXPOSE 80`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#expose)

12. **`VOLUME`**
    - **Description**: Creates a mount point and marks it as holding externally mounted volumes from the native host or other containers.
    - **Example**: `VOLUME /data`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#volume)

13. **`USER`**
    - **Description**: Sets the user name or UID and optionally the user group or GID to use when running the image.
    - **Example**: `USER developer`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#user)

14. **`HEALTHCHECK`**
    - **Description**: Tells Docker how to test the container to check that it's still working.
    - **Example**: `HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#healthcheck)

15. **`ONBUILD`**
    - **Description**: Adds a trigger instruction when the image is used as the base for another build.
    - **Example**: `ONBUILD ADD ./app /app`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#onbuild)

16. **`SHELL`**
    - **Description**: Allows overriding the default shell used for the `RUN` instruction.
    - **Example**: `SHELL ["powershell", "-command"]`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#shell)

17. **`STOPSIGNAL`**
    - **Description**: Sets the system call signal that will be sent to the container to exit.
    - **Example**: `STOPSIGNAL SIGKILL`
    - [Official Documentation](https://docs.docker.com/engine/reference/builder/#stopsignal)


