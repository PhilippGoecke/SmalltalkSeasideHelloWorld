podman build --no-cache --rm --file Containerfile --tag seaside:demo .
podman run --interactive --tty --publish 8181:8080 seaside:demo
echo "browse https://localhost:8181/"
