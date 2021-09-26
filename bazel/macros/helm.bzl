def _copy_cmd(cmd, directory, files):
    return "\n".join(["{} {} {}/.".format(cmd, f.path, directory) for f in files])

def _helm_repository_impl(ctx):
    helm = ctx.toolchains["@bazel_toolchain_helm//:toolchain_type"].toolinfo
    yq = ctx.toolchains["@bazel_toolchain_yq//:toolchain_type"].toolinfo

    index = ctx.actions.declare_file("{}.yaml".format(ctx.attr.name))
    build_file = ctx.actions.declare_file("{}.{}".format(ctx.attr.name, ctx.attr.extension))
    chart_directory = ctx.actions.declare_directory("{}.charts".format(ctx.attr.name))

    ctx.actions.expand_template(
        output = build_file,
        template = ctx.file.cmd_tpl,
        substitutions = {
            "{copy_cmd}": _copy_cmd(ctx.attr.cmd_copy, chart_directory.path, ctx.files.charts),
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

_helm_repository = rule(
    implementation = _helm_repository_impl,
    attrs = {
        "charts": attr.label_list(
            mandatory = True,
            doc = "Charts",
            allow_files = True,
        ),
        "extension": attr.string(
            mandatory = True,
        ),
        "cmd_copy": attr.string(
            mandatory = True,
        ),
        "cmd_tpl": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
    },
    toolchains = [
        "@bazel_toolchain_helm//:toolchain_type",
        "@bazel_toolchain_yq//:toolchain_type",
    ],
)

def helm_repository(name, charts, **kwargs):
    _helm_repository(
        name = name,
        charts = charts,
        extension = select({
            "@bazel_tools//src/conditions:host_windows": "bat",
            "//conditions:default": "sh",
        }),
        cmd_copy = select({
            "@bazel_tools//src/conditions:host_windows": "copy",
            "//conditions:default": "cp",
        }),
        cmd_tpl = select({
            "@bazel_tools//src/conditions:host_windows": "//bazel/macros:helm_repository.bat.tpl",
            "//conditions:default": "//bazel/macros:helm_repository.sh.tpl",
        }),
        **kwargs
    )
