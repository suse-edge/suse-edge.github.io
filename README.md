# SUSE Edge website

The latest version of our docs can be found at https://suse-edge.github.io/id-suse-edge-documentation.html



## How to test/build locally

If you are contributing to our documentation, you can locally render the content using one of these methods. 

With docker/podman: 

```bash
podman run -it --rm -v $PWD/:/docs/ registry.opensuse.org/home/atgracey/cnbp/containers/builder:latest bash -c 'cd /docs/asciidoc; daps -d DC-edge html'

cd asciidoc/build/edge/html/edge; python -m http.server
```

With [Pack](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/):
```bash
pack build edge-docs --path asciidoc --builder registry.opensuse.org/home/atgracey/cnbp/containers/builder:latest -e BP_DC_FILE=DC-edge

podman run -d -p 8080:8080 edge-docs
```

With [Epinio](epinio.io):
```bash
epinio push -n docs --builder-image registry.opensuse.org/home/atgracey/cnbp/containers/builder:latest -e BP_DC_FILE=DC-edge
```