const std = @import("std");
const zigros = @import("../../zigros/zigros.zig");

const Step = std.Build.Step;

pub fn buildWithArgs(b: *std.Build, args: zigros.CompileArgs) *Step.Compile {
    const upstream = b.dependency("console_bridge", args);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
    };

    const console_bridge = b.addModule("console_bridge", std_module_opts);

    // This is so annoying - the CMake-generated header console_bridge_export.h does practically nothing...
    console_bridge.addIncludePath(b.path("ros_deps/console_bridge/include"));
    console_bridge.addIncludePath(upstream.path("include"));
    console_bridge.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{"console.cpp"},
        .flags = &.{ "--std=c++17", "-frtti", "-Wall", "-Wextra", "-Werror" },
    });

    const console_bridge_lib = b.addLibrary(.{
        .name = "console_bridge",
        .root_module = console_bridge,
        .linkage = args.linkage,
    });
    console_bridge_lib.installHeadersDirectory(
        upstream.path("include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    console_bridge_lib.installHeader(b.path("ros_deps/console_bridge/include/console_bridge_export.h"), "console_bridge_export.h");
    b.installArtifact(console_bridge_lib);

    return console_bridge_lib;
}
