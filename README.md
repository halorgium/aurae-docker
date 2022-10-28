# aurae-docker

> Aurae is a free and open source Rust project which houses a memory-safe systems runtime daemon built specifically for enterprise distributed systems called auraed.

If you are not on Linux, you can play around with https://aurae.io/ via Docker.

Make sure you have a Docker install configured: https://www.docker.com/get-started/

## Downloading

```bash
git clone https://github.com/halorgium/aurae-docker
cd aurae-docker
git clone https://github.com/aurae-runtime/aurae src
```

## Building

```bash
./build.sh
```

## Running the daemon

```bash
./daemon.sh
```

## Running a command

```bash
./examples.sh
# in the container
~/examples/connect.auraescript
```
