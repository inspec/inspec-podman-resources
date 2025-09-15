+++
title = "About Chef InSpec Podman resources"
platform = "podman"
draft = false
linkTitle = "Podman resources"
summary = "Chef InSpec resources for auditing Podman."


[cascade]
  [cascade.params]
    gh_repo = "inspec-podman-resources"
    platform = "podman"

[menu.podman]
title = "About resources"
identifier = "inspec/resources/podman/about"
parent = "inspec/resources/podman"
+++

The InSpec Podman resources allow you to test and validate the state of Podman containers, images, pods, networks, and volumes.

## Support

The InSpec Podman resources were part of InSpec core through InSpec 6.
Starting in InSpec 7, they're released separately as a Ruby gem.

## Usage

To add this resource pack to an InSpec profile, add the `inspec-podman-resources` gem as a dependency in your `inspec.yml` file:

```yaml
depends:
 - name: inspec-podman-resources
    gem: inspec-podman-resources
```

## Podman resources

{{< inspec_resources_filter >}}

The following Chef InSpec Podman resources are available in this resource pack.

{{< inspec_resources section="podman" platform="podman" >}}
