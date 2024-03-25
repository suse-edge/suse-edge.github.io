# SUSE Edge website

Currently we don't have any published builds but Github should render the pages just fine (but without the SUSE branding). We are working on build automation and will update this readme when it's ready. 

The best starting place for reading our docs on GH is [here](https://github.com/suse-edge/suse-edge.github.io/blob/main/asciidoc/edge-book/welcome.adoc)

## How to test/build locally

With docker/podman: 

```bash
podman run -it --rm -v $PWD/:/docs/ registry.opensuse.org/home/atgracey/cnbp/containers/builder:latest -- bash -c 'cd /docs/asciidoc; daps -d DC-edge html'

cd asciidocs/build/edge/html/edge; python -m http.server
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