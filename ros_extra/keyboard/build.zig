const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;

pub fn buildWithArgs(b: *std.Build, opts: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("keyboard", opts); // todo: take as input

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    utils.writeAmentIndexFile(b, "keyboard_handler");

    const keyboard_handler = b.addLibrary(.{
        .name = "keyboard_handler",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    keyboard_handler.addIncludePath(upstream.path("keyboard_handler/include"));
    keyboard_handler.addCSourceFiles(.{
        .root = upstream.path("keyboard_handler/src"),
        .files = &.{
            "keyboard_handler_base.cpp",
            "default_unix_key_map.cpp",
            "default_windows_key_map.cpp",
            "keyboard_handler_unix_impl.cpp",
            "keyboard_handler_windows_impl.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });

    keyboard_handler.installHeadersDirectory(
        upstream.path("keyboard_handler/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(keyboard_handler);

    return keyboard_handler;
}
