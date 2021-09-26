# bazel-external-toolchain-rules

Experimenting with setting up Bazel toolchains using an externally managed `.toolchain` file, that is responsible for defining properties such as:

- System compatibility
- Integrity Checks
- Tool retrieval locations

## Notes

This idea came out of the idea of having Bazel rules that were not aware of how toolchains were defined (or what systems they are compatible with), and instead being entirely based on the lock file (`.toolchain`) available in the caller environment. This means that the bazel rules can in essence just be extensions of the command line specification.

Repositories would have a collection of `.toolchain` files, that could be used by other services (e.g. pre-baked GitPod/Codespace/DevContainers, local installs, etc). When used by Bazel, these files would be read by Bazel and converted into the appropriate rules for downloading & setting up the toolchain.

The basic idea scratched out:

```python
load("//bazel/macros:load_all.bzl", "register_external_toolchains")

register_external_toolchains(
    name = "external_toolchains",
    toolchains = {
        "//bazel/toolchains:helm.toolchain": "bazel_toolchain_helm",
        "//bazel/toolchains:yq.toolchain": "bazel_toolchain_yq",
    },
)
```

Local or imported rules can be specified in the string field (`bazel_toolchain_helm`), making it simple to map the toolchain definition to the toolchain use in Bazel.

```ini
Name=yq
Version=4.13.2

[linux_amd64]
OS=linux
CPU=x86_64
Executable=yq_linux_amd64
URL=https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_linux_amd64.tar.gz
Sha256Sum=b462478cfee8fb02b1b6bbee87b2b1d2f0ef4f0b693a95c04308006f04cc525e

[darwin_amd64]
OS=osx
CPU=x86_64
Executable=yq_darwin_amd64
URL=https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_darwin_amd64.tar.gz
Sha256Sum=cf0cbf49a423d515d69879c08af4bab64af09f29b949545aa8e3d771a94a3db7

[windows_amd64]
OS=windows
CPU=x86_64
Executable=yq_windows_amd64.exe
URL=https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_windows_amd64.zip
Sha256Sum=0b08de85f4de4b55e98fcd69c707bea52f91478603cc4221c024ddd80cfd6141
```

## Custom Tool Stores

These can then be combined with custom storages for tools, rather than just relying on the `http_archive`. An example would be an `s3_archive` rule that can retrieve these tools from an AWS S3 Bucket responsible for storing these binaries.

The aim of this would be to enable the above rules (`register_external_toolchain(s)`) to support tools or systems that augment the processing of the read toolchain file. If done right, it would allow something like mirroring all toolchain dependencies to an internal store with minimal manual intervention:

1. Run a command to download all the toolchains to a custom local directory (`toolchains download --directory <xyz>`)
2. Upload this directory to a minio or hosted file store (`aws s3 sync --recursive <xyz>/ s3://...`)
3. Map the toolchains to the now vendored path (`toolchains vendor s3 s3://...`)
4. In bazel, modify the `register_external_toolchains` to add an adaptor/affix/aspect/etc that supports downloading from S3.

The above is the scenario this idea was explored, but the hope would be letting the `.toolchain` (& potentially supporting files) act as the source of truth about toolchains, and letting Bazel interpret it.


## Design Jots

- Instead of URLs for downloading the toolchains, what if instead they were content-addressable?
- Rather than using bazel to perform the analysis, would it be possible to have a tool generate the entire compatibility-layer? Thus allowing us to only define the necessary "version" components in a bazel compatible way?
- Would a system like `gazelle` make more sense? Having a tool read the `.toolchain` file, then generate all the `repository_rule` bindings (& use `netrc` instead of custom rules?)
