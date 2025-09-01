const std = @import("std");

const zigros = @import("zigros.zig");
const utils = @import("../build_utils.zig");

const Compile = std.Build.Step.Compile;
const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;

pub const Deps = struct {
    flags: *Dependency,
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
    const ros2_mod = b.createModule(.{
        .root_source_file = b.path("libs/dh_utils/src/cli.zig"),
        .target = args.target,
        .optimize = args.optimize,
        .strip = args.strip,
        .pic = true,
    });
    const ros2_cli = b.addExecutable(.{
        .name = "ros2_zig",
        .root_module = ros2_mod,
    });
    ros2_cli.bundle_compiler_rt = true;
    ros2_cli.linkLibCpp();
    ros2_cli.root_module.addImport("flags", deps.flags.module("flags"));
    ros2_cli.addIncludePath(b.path("libs/dh_utils/src/"));
    ros2_cli.addCSourceFile(.{ .file = b.path("libs/dh_utils/src/cli_commands.cpp"), .flags = &.{ "--std=c++17", "-Wno-deprecated" } });

    ros2_cli.linkLibrary(deps.dynmsg);
    ros2_cli.addIncludePath(deps.rosidl_runtime_cpp);
    ros2_cli.addIncludePath(deps.rosidl_typesupport_interface);
    ros2_cli.linkLibrary(deps.yaml_cpp);
    ros2_cli.linkLibrary(deps.rcl_logging_spdlog);

    deps.rclcpp.link(ros2_cli.root_module);
    deps.rcl.link(ros2_cli.root_module);
    deps.rmw.link(ros2_cli.root_module);

    b.installArtifact(ros2_cli);

    return ros2_cli;
}
