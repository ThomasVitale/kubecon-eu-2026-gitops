{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    # Carvel
    pkgs.imgpkg
    pkgs.kapp
    pkgs.kbld
    pkgs.vendir
    pkgs.ytt

    # Kubernetes
    pkgs.k3d
    pkgs.kubectl
    pkgs.kubernetes-helm

    # Utilities
    pkgs.jq
    pkgs.yq-go
  ];

  # See full reference at https://devenv.sh/reference/options/
}
