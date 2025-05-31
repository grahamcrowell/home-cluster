# home-cluster

> 3 node bare metal kubernetes cluster

99% of all code/inspiration is from [mchestr/home-cluster](https://github.com/mchestr/home-cluster)

## prequistite apps

-   kubectl
-   k9s `brew install k9s`
-   talosctl `brew install siderolabs/tap/talosctl`
-   talhelper `brew install talhelper`
-   taskfiles `brew install go-task`
-   helmfile `brew install helmfile`
-   op `brew install --cask 1password-cli`
-   helmfile `brew install helmfile`
-   helm diff `helm plugin install https://github.com/databus23/helm-diff`
-   kyverno`brew install kyverno`
-   flux `brew install fluxcd/tap/flux`

## Bootstrap

### Prerequisites

-   zero rook drives (takes > 6hrs)

```bash
talosctl --nodes cp0 wipe disk sdc --method ZEROES &
talosctl --nodes cp1 wipe disk sdc --method ZEROES &
talosctl --nodes cp2 wipe disk sdc --method ZEROES &
```

### Bootstrap

1. `task bootstrap:talos_generate_configs`
1. `task bootstrap:talos_apply_config_cp0`
1. `task bootstrap:bootstrap:talos_bootstrap_cp0`
1. `task bootstrap:talos_apply_config_cp1_cp2`
1. `task bootstrap:k8s_apps`

### Hardware Requirements

-   [Video file size calculator](https://snxpstudio.co/resources/video-file-size-calculator/)

```
1000 movies + 200 series

800 movies + 100 series @ 4K
200 movies + 100 series @ 1080p

1 series = 5 season * 15 episodes * 45 mins ~ 4000 mins
1 movie = 120 mins

800 * 120 + 4_000 * 100 = 496_000
200 * 120 + 4_000 * 100
```
