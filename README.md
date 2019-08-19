# Bob

Meet Bob, the non-trademark-infringing-construction-worker. He builds your local docker development environments.

One or more local git repositories can be watched. When you make a new commit or switch branch the image defined by the project will be rebuilt, tagged and automatically reloaded by any containers that are using it.

## Usage

You can run directly:
```
bob /my/dev/path/my-project
```

Or, launch as a container:
```
docker run -d \
    --mount source=/var/run/docker.sock,target=/var/run/docker.sock \
    --mount source=/my/dev/path/my-project,target=/repos/my-project \
    --mount source=/my/dev/path/my-other-project,target=/repos/my-org/custom-name \
    aca-labs/bob
```

## Contributing

1. Fork it (<https://github.com/aca-labs/bob/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kim Burgess](https://github.com/kimburgess) - creator and maintainer
