# home-cluster

> 3 node bare metal kubernetes cluster

99% of all code/inspiration is from [mchestr/home-cluster](https://github.com/mchestr/home-cluster)

## prequistite apps

-   kubectl
-   talosctl `brew install siderolabs/tap/talosctl`
-   talhelper `brew install talhelper`
-   taskfiles `brew install go-task`
-   helmfile `brew install helmfile`
-   op `brew install --cask 1password-cli`
-   helmfile `brew install helmfile`
-   helm diff `helm plugin install https://github.com/databus23/helm-diff`

### not (yet) used

-   flux `brew install fluxcd/tap/flux`
-   helm convert `helm plugin install https://github.com/ContainerSolutions/helm-convert`

## Generate secrets for Talos and save as 1password item

1. [generate talos secrets](https://www.talos.dev/v1.9/introduction/prodnotes/#separating-out-secrets)

```bash
talosctl gen secrets -o talsecret.yaml
```

2. Create json payload for 1password. Replace every `???` in [talos/talosecret-op.json.example](talos/talosecret-op.json.example) in new file: talos/talosecret.json

3. Create 1password item from talos/talosecret.op.cli.json

```bash
     --template talos/talosecret.json
```

4. Delete talos/talosecret.json and talos/talsecret.yaml

### Helpers

#### Recreate talos/talosecret.json from 1password

```bash
op inject -i talos/talosecret.op.json -o talos/talosecret.json
```

#### Recreate talos/talosecret.yaml from 1password

```bash
op inject -i talos/talosecret.op.yaml -o talos/talosecret.yaml
```

## bootstrap cluster

0. Ensure `cp0` node booted from Talos ISO and has IP 192.168.4.10
1. `taloctl apply-configs`
2. `taloctl bootstrap`
3. `helm install` CoreDNS and Cilium
4. Ensure `cp1` and `cp2` nodes booted from Talos ISO and have IP 192.168.4.11 and 192.168.4.12
5. `taloctl apply-configs`

```
export GITHUB_TOKEN=$(op read "op://Kubernetes/home-cluster/PERSONAL_ACCESS_TOKEN")
export GITHUB_USER=grahamcrowell
flux bootstrap github \
  --token-auth \
  --owner=$GITHUB_USER \
  --repository=home-cluster \
  --branch=main \
  --path=k8s/apps \
  --personal
```
