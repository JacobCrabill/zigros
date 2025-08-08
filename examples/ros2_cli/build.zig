const std = @import("std");
const zr = @import("zigros");
const utils = @import("build_utils.zig");

const Compile = std.Build.Step.Compile;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .static;
    const rmw = b.option(utils.RmwKind, "rmw", "ROS MiddleWare to use. NOTE: FastRTPS not yet working!") orelse .cyclonedds;

    // Check the ABI to determine compability with certain features like shared-memory
    const has_shm: bool = if (rmw == .cyclonedds and target.result.abi == .gnu) true else false;

    // Standard build options to use for all packages
    const build_opts: utils.BuildOpts = .{
        .optimize = optimize,
        .target = target,
        .linkage = linkage,
        .rmw = rmw,
    };

    const zigros_dep = b.dependency("zigros", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
        .@"system-python" = false,
    });

    const zigros = zr.ZigRos.init(zigros_dep) orelse return; // return early if lazy deps are needed

    if (has_shm) {
        // Install the RouDi (Iceoryx Routing and Discovery) executable from ZigRos
        // This is used by CycloneDDS for shared-memory message transport, but requires GNU libC
        b.installArtifact(zigros_dep.artifact("iox-roudi"));
    }

    const upstream = b.dependency("dynmsg", build_opts);

    // ROS2 CLI Tool (Replace Python with a compiled language!)
    const ros2_cli = b.addExecutable(.{
        .name = "ros2_cli",
        .target = build_opts.target,
        .optimize = build_opts.optimize,
    });
    ros2_cli.addCSourceFiles(.{
        .root = upstream.path("dynmsg_demo/src"),
        .files = &.{ "cli.cpp", "cli_tool.cpp", "typesupport_utils.cpp" },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wno-deprecated" },
    });
    ros2_cli.addIncludePath(upstream.path("dynmsg_demo/include"));
    ros2_cli.linkLibrary(zigros.ros_libraries.dynmsg);
    ros2_cli.addIncludePath(zigros.ros_libraries.rosidl_runtime_cpp);
    ros2_cli.addIncludePath(zigros.ros_libraries.rosidl_typesupport_interface);
    ros2_cli.linkLibrary(zigros.ros_libraries.yaml_cpp);
    zigros.linkRcl(ros2_cli);
    utils.linkRmw(ros2_cli, &zigros, rmw);

    b.installArtifact(ros2_cli);
}
