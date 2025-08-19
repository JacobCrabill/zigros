const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const Interface = @import("../../ros_core/rosidl/src/RosidlGenerator.zig").Interface;

const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    ament_index_cpp: *Compile,
    rcutils: *Compile,
    rcpputils: *Compile,
    rmw: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_dynamic_typesupport: *Compile,
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps) *Compile {
    const upstream = b.dependency("rmw_implementation", .{});
    const std_mod_options: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    // ---- Core FastRTPS Middleware -------------------------------------------

    const rmw_implementation = b.addLibrary(.{
        .name = "rmw_implementation",
        .root_module = b.createModule(std_mod_options),
        .linkage = args.linkage,
    });

    rmw_implementation.addIncludePath(upstream.path("rmw_implementation/src"));
    rmw_implementation.addCSourceFile(.{
        .file = upstream.path("rmw_implementation/src/functions.cpp"),
        .flags = &.{
            "--std=c++17",
            "-fPIC",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
        },
    });

    zigros.linkDependencyStruct(rmw_implementation, deps, .cpp);

    b.installArtifact(rmw_implementation);

    return rmw_implementation;
}
