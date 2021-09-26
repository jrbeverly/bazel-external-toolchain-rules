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

## Custom Tool Stores

These can then be combined with custom storages for tools, rather than just relying on the `http_archive`. An example would be an `s3_archive` rule that can retrieve these tools from an AWS S3 Bucket responsible for storing these binaries.

The aim of this would be to enable the above rules (`register_external_toolchain(s)`) to support tools or systems that augment the processing of the read toolchain file. If done right, it would allow something like mirroring all toolchain dependencies to an internal store with minimal manual intervention:

1. Run a command to download all the toolchains to a custom local directory (`toolchains download --directory <xyz>`)
2. Upload this directory to a minio or hosted file store (`aws s3 sync --recursive <xyz>/ s3://...`)
3. Map the toolchains to the now vendored path (`toolchains vendor s3 s3://...`)
4. In bazel, modify the `register_external_toolchains` to add an adaptor/affix/aspect/etc that supports downloading from S3.

The above is the scenario this idea was explored, but the hope would be letting the `.toolchain` (& potentially supporting files) act as the source of truth about toolchains, and letting Bazel interpret it.
