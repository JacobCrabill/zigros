const std = @import("std");

const zigros = @import("../zigros.zig");
const utils = @import("../../build_utils.zig");

const Compile = std.Build.Step.Compile;
const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;

pub const Deps = struct {
    dynmsg: *Compile,
    yaml_cpp: *Compile,
    rcl_logging_spdlog: *Compile,
    rosidl_runtime_cpp: LazyPath,
    rosidl_typesupport_interface: LazyPath,
    rcl: zigros.Rcl,
    rclcpp: zigros.Rclcpp,
    rmw: zigros.Rmw,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, args: zigros.CompileArgs) *Compile {
    const flags = b.dependency("flags", .{ .target = args.target, .optimize = args.optimize });

    const ros2_mod = b.createModule(.{
        .root_source_file = b.path("zigros/ros2/ros2.zig"),
        .target = args.target,
        .optimize = args.optimize,
        .strip = args.strip,
        .pic = true,
    });

    ros2_mod.addImport("flags", flags.module("flags"));
    ros2_mod.addIncludePath(b.path("zigros/ros2"));
    ros2_mod.addCSourceFile(.{ .file = b.path("zigros/ros2/cli_commands.cpp"), .flags = &.{ "--std=c++17", "-Wno-deprecated" } });

    ros2_mod.linkLibrary(deps.dynmsg);
    ros2_mod.addIncludePath(deps.rosidl_runtime_cpp);
    ros2_mod.addIncludePath(deps.rosidl_typesupport_interface);
    ros2_mod.linkLibrary(deps.yaml_cpp);
    ros2_mod.linkLibrary(deps.rcl_logging_spdlog);

    deps.rclcpp.link(ros2_mod);
    deps.rcl.link(ros2_mod);
    deps.rmw.link(ros2_mod);

    const ros2_cli = b.addExecutable(.{
        .name = "ros2",
        .root_module = ros2_mod,
    });
    ros2_cli.bundle_compiler_rt = true;
    ros2_cli.linkLibCpp();

    b.installArtifact(ros2_cli);

    return ros2_cli;
}
