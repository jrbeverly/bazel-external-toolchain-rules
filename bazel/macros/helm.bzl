def _copy_cmd(directory, files):
    return "\n".join(["cp {} {}/.".format(f.path, directory) for f in files])

def _helm_repository_impl(ctx):
    helm = ctx.toolchains["@bazel_toolchain_helm//:toolchain_type"].toolinfo
    yq = ctx.toolchains["@bazel_toolchain_yq//:toolchain_type"].toolinfo

    index = ctx.actions.declare_file("{}.yaml".format(ctx.attr.name))
    build_file = ctx.actions.declare_file("{}.sh".format(ctx.attr.name))
    chart_directory = ctx.actions.declare_directory("{}.charts".format(ctx.attr.name))

    ctx.actions.expand_template(
        output = build_file,
        template = ctx.file._cmd_tpl,
        substitutions = {
            "{copy_cmd}": _copy_cmd(chart_directory.path, ctx.files.charts),
            "{directory}": chart_directory.path,
            "{output}": index.path,
            "{helm_path}": helm.tool.path,
            "{yq_path}": yq.tool.path,
        },
    )
    ctx.actions.run(
        inputs = ctx.files.charts + [helm.tool, yq.tool],
        outputs = [index, chart_directory],
        mnemonic = "HelmRepositoryInitialize",
        progress_message = "Generating helm repository",
        executable = build_file,
    )
    return [DefaultInfo(files = depset([index]))]

helm_repository = rule(
    implementation = _helm_repository_impl,
    attrs = {
        "charts": attr.label_list(
            mandatory = True,
            doc = "Charts",
            allow_files = True,
        ),
        "_cmd_tpl": attr.label(
            allow_single_file = True,
            default = "//bazel/macros:helm_repository_tpl",
        ),
    },
    toolchains = [
        "@bazel_toolchain_helm//:toolchain_type",
        "@bazel_toolchain_yq//:toolchain_type",
    ],
)
