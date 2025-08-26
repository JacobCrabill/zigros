const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");

const Compile = std.Build.Step.Compile;

pub const Deps = struct {
    yaml_cpp: *Compile,
    rcutils: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_typesupport_introspection_c: *Compile,
    rosidl_typesupport_introspection_cpp: *Compile,
    rosidl_runtime_cpp: std.Build.LazyPath,
    rosidl_typesupport_interface: std.Build.LazyPath,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, args: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("dynmsg", args);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    // Dynamic Message Introspection Library

    const dynmsg = b.addLibrary(.{
        .name = "dynmsg",
        .root_module = b.createModule(std_module_opts),
        .linkage = args.linkage,
    });

    const config_h = b.addConfigHeader(
        .{
            .style = .{ .cmake = upstream.path("dynmsg/include/dynmsg/config.hpp.in") },
            .include_path = "dynmsg/config.hpp",
        },
        .{
            .DYNMSG_VALUE_ONLY = 1,
            .DYNMSG_YAML_CPP_BAD_INT8_HANDLING = 1,
            .DYNMSG_PARSER_DEBUG = null,
        },
    );
    dynmsg.addConfigHeader(config_h);
    dynmsg.installConfigHeader(config_h);

    dynmsg.addIncludePath(upstream.path("dynmsg/include"));
    dynmsg.addCSourceFiles(.{
        .root = upstream.path("dynmsg/src"),
        .files = &.{
            "msg_parser_c.cpp",
            "msg_parser_cpp.cpp",
            "message_reading_c.cpp",
            "message_reading_cpp.cpp",
            "typesupport.cpp",
            "vector_utils.cpp",
            "string_utils.cpp",
            "yaml_utils.cpp",
        },
        .flags = &.{ "--std=c++14", "-Wall", "-Werror", "-Wpedantic", "-fPIC" },
    });
    dynmsg.linkLibrary(deps.rcutils);
    dynmsg.linkLibrary(deps.rosidl_runtime_c);
    dynmsg.linkLibrary(deps.rosidl_typesupport_introspection_c);
    dynmsg.linkLibrary(deps.rosidl_typesupport_introspection_cpp);
    dynmsg.linkLibrary(deps.yaml_cpp);
    dynmsg.addIncludePath(deps.rosidl_runtime_cpp);
    dynmsg.addIncludePath(deps.rosidl_typesupport_interface);

    dynmsg.installHeadersDirectory(
        upstream.path("dynmsg/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(dynmsg);

    // TODO: Migrate to examples folder
    // // ROS2 CLI Tool (Replace Python with a compiled language!)
    // const ros2_cli = b.addExecutable(.{
    //    .root_module = b.createModule(.{
    //     .name = "ros2_cli",
    //     .target = args.target,
    //     .optimize = args.optimize,
    //     }),
    // });
    // ros2_cli.addCSourceFiles(.{
    //     .root = upstream.path("dynmsg_demo/src"),
    //     .files = &.{ "cli.cpp", "cli_tool.cpp", "typesupport_utils.cpp" },
    //     .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wno-deprecated" },
    // });
    // ros2_cli.addIncludePath(upstream.path("dynmsg_demo/include"));
    // ros2_cli.linkLibrary(dynmsg);
    // ros2_cli.addIncludePath(deps.rosidl_runtime_cpp);
    // ros2_cli.addIncludePath(deps.rosidl_typesupport_interface);
    // ros2_cli.linkLibrary(deps.yaml_cpp);
    // zigros.linkRcl(ros2_cli);
    // utils.linkRmw(ros2_cli, zigros, rmw);

    // b.installArtifact(ros2_cli);

    return dynmsg;
}
