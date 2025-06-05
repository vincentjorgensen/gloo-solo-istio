# gloo-solo-istio

Common functions for manipulating Istio clusters, Gloo Platform, and Solo.io
builds

# Requirements

```bash
brew install jinja2 kubectl
```

Version 1.17.2 of Helm required until [this
issue](https://github.com/helm/helm/issues/30738)  is fixed.

```bash
brew uninstall helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | DESIRED_VERSION=v3.17.2 bash
```

Some commands require `istioctl` (though I've tried my best to limit them).
Here is an example of how to install istioctl version 1.25.3

```bash
mkdir $HOME/.istioctl/bin
PATH=$HOME/.istioctl/bin:$PATH

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.3 sh -

cp istio-1.25.3/bin/istioctl $HOME/.istioctl/bin/istioctl-1.25
```

# Usage

```bash
source ./functions.sh
```
