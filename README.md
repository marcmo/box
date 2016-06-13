
## Run container

container path is `/home/dev` by default. to mount the local directory:

    docker run --rm -it -v ${PWD}:/home/dev/${PWD##*/} -w /home/dev/${PWD##*/}  box:latest
