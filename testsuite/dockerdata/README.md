# Creating image

- Make sure `testsuite/dockerdata/version` is bumped for new images, also
  after updating `kas/kas-container`.

- Run:

```
testsuite/dockerdata/build.sh
```

# Pushing the image to docker hub

- Configure github token (classic) with `write:packages` permissions.

- Use it for uploading docker image:

```
docker push ghcr.io/ilbers/isar/test-container:$(cat testsuite/dockerdata/version)
```

- Make the uploaded package public
