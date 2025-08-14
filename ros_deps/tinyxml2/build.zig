const std = @import("std");
const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");

const Dependency = std.Build.Dependency;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub fn buildWithArgs(b: *std.Build, opts: CompileArgs) *Compile {
    const upstream = b.dependency("tinyxml2", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const tinyxml2 = b.addModule("tinyxml2", std_module_opts);

    tinyxml2.addIncludePath(upstream.path("."));
    tinyxml2.addCSourceFiles(.{
        .root = upstream.path("."),
        .files = &.{"tinyxml2.cpp"},
        .flags = &.{ "--std=c++17", "-Wall", "-Werror", "-Wpedantic" },
    });

    const tinyxml2_lib = b.addLibrary(.{
        .name = "tinyxml2",
        .root_module = tinyxml2,
        .linkage = opts.linkage,
    });
    tinyxml2_lib.installHeadersDirectory(
        upstream.path("."),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(tinyxml2_lib);

    return tinyxml2_lib;
}
