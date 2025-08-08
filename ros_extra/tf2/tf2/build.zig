const std = @import("std");

const zigros = @import("../../../zigros/zigros.zig");
const utils = @import("../../../build_utils.zig");
const RosidlGenerator = @import("../../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;

pub const Deps = struct {
    rcutils: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: std.Build.LazyPath,
    rosidl_typesupport_interface: std.Build.LazyPath,
    builtin_interfaces: RosidlGenerator.Interface,
    std_msgs: RosidlGenerator.Interface,
    geometry_msgs: RosidlGenerator.Interface,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, opts: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("geometry2", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    utils.writeAmentIndexFile(b, "tf2");

    const tf2 = b.addLibrary(.{
        .name = "tf2",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    tf2.addIncludePath(upstream.path("tf2/include"));
    tf2.addCSourceFiles(.{
        .root = upstream.path("tf2/src"),
        .files = &.{
            "buffer_core.cpp",
            "cache.cpp",
            "static_cache.cpp",
            "time.cpp",
        },
        .flags = &.{
            "--std=c++17",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wno-deprecated",
            "-Wno-non-virtual-dtor",
            "-Wno-overloaded-virtual",
        },
    });
    tf2.linkLibrary(deps.rcutils);
    tf2.linkLibrary(deps.rosidl_runtime_c);
    deps.builtin_interfaces.link(tf2);
    deps.std_msgs.link(tf2);
    deps.geometry_msgs.link(tf2);
    tf2.addIncludePath(deps.rosidl_runtime_cpp);
    tf2.addIncludePath(deps.rosidl_typesupport_interface);

    tf2.installHeadersDirectory(
        upstream.path("tf2/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(tf2);

    return tf2;
}
