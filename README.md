# The Developer’s Nightmare: How To Survive Compliance Checklists (and Still Ship Fast) - GitOps

_Presented by Alexandra Hou Aldershaab and Thomas Vitale at KubeCon+CloudNativeCon Europe 2026._

[Details](https://kccnceu2026.sched.com/event/2CVzp/the-developers-nightmare-how-to-survive-compliance-checklists-and-still-ship-fast-alexandra-hou-aldershaab-eficode-thomas-vitale-systematic)


You did it! The new feature you’ve been implementing is now ready and you can’t wait to ship it.

“Not so fast”. Oh no, it’s them: the guardians of compliance! You know what’s about to happen. You’ve been there before.

- Are you using any license that is not approved?
- Is there any CVE reported for the new dependencies you added?
- Can you guarantee the artifact running in production has not been tampered with?

Several checklists, paperwork, and meetings later, you’re finally approved for release. Not fun. Where did the developer joy go?

In this session, Alexandra and Thomas explore how to break the compliance barriers for developers, even in highly-regulated industries. The goal is to enhance the developer experience while letting the platform automate and enforce compliance and security checks.

You'll follow the mishaps of a developer and learn how to deal with compliance, using practical solutions based on OSS tools like Backstage, Dependency-Track, Sigstore and Buildpacks.

## Development environment (recommended)

This project uses [Flox](https://flox.dev/) to manage the development and build environment via [Nix](https://nixos.org). After [installing](https://flox.dev/docs/install-flox/install/) the Flox CLI (open-source), activate the environment:

```shell
flox activate
```

By doing so, you will have access to all the tools and dependencies needed to provision a Kubernetes cluster, install the Kadras Engineering Platform, and deploy the applications.

## Platform

This project relies on the Kadras Engineering Platform, an open-source project that provides common platform capabilities for building and operating cloud-native applications. The platform is built on top of Kubernetes and includes components such as Crossplane, Dependency Track, Knative, Contour, OpenTelemetry, and more.

We installed the platform on a Kubernetes cluster hosted at Hetzner, a European cloud provider. You can follow the installation instructions in the [Kadras documentation](https://kadras-io.github.io/kadras-docs/docs/hetzner/installation/) to set up your own instance of the platform.

The configuration of the platform is defined in the `values.yaml` file you can find in the root folder of this project. You should reference it when installing the platform based on the instructions in the documentation.
