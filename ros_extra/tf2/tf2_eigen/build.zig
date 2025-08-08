const std = @import("std");

const zigros = @import("../../../zigros/zigros.zig");
const utils = @import("../../../build_utils.zig");
const RosidlGenerator = @import("../../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const RosIdlInterface = RosidlGenerator.Interface;

pub const Deps = struct {
    eigen: *std.Build.Dependency,
    class_loader: *Compile,
    console_bridge: *Compile,
    message_filters_lib: *Compile,
    rclcpp: *Compile,
    rclcpp_action: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: std.Build.LazyPath,
    rosidl_typesupport_interface: std.Build.LazyPath,
    tracetools: std.Build.LazyPath,
    tf2: *Compile,
    tf2_ros: *Compile,
    tf2_msgs: RosIdlInterface,
    action_msgs: RosIdlInterface,
    builtin_interfaces: RosIdlInterface,
    geometry_msgs: RosIdlInterface,
    rcl_interfaces: RosIdlInterface,
    service_msgs: RosIdlInterface,
    statistics_msgs: RosIdlInterface,
    std_msgs: RosIdlInterface,
    unique_identifier_msgs: RosIdlInterface,
    type_description_interfaces: RosIdlInterface,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, args: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("geometry2", args);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    utils.writeAmentIndexFile(b, "tf2_eigen");

    const tf2_eigen = b.addLibrary(.{
        .name = "tf2_eigen",
        .root_module = b.createModule(std_module_opts),
        .linkage = args.linkage,
    });
    tf2_eigen.addIncludePath(upstream.path("tf2_eigen/include"));
    tf2_eigen.addCSourceFiles(.{
        .root = b.path("ros_extra/tf2/tf2_eigen/"),
        .files = &.{
            "dummy.cpp",
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
    tf2_eigen.addIncludePath(deps.eigen.path(""));

    deps.action_msgs.link(tf2_eigen);
    deps.builtin_interfaces.link(tf2_eigen);
    deps.geometry_msgs.link(tf2_eigen);
    deps.rcl_interfaces.link(tf2_eigen);
    deps.service_msgs.link(tf2_eigen);
    deps.statistics_msgs.link(tf2_eigen);
    deps.std_msgs.link(tf2_eigen);
    deps.tf2_msgs.link(tf2_eigen);
    deps.unique_identifier_msgs.link(tf2_eigen);
    deps.type_description_interfaces.link(tf2_eigen);

    tf2_eigen.linkLibrary(deps.class_loader);
    tf2_eigen.linkLibrary(deps.console_bridge);
    tf2_eigen.linkLibrary(deps.message_filters_lib);
    tf2_eigen.linkLibrary(deps.rclcpp);
    tf2_eigen.linkLibrary(deps.rclcpp_action);
    tf2_eigen.linkLibrary(deps.rosidl_runtime_c);
    tf2_eigen.linkLibrary(deps.tf2);
    tf2_eigen.linkLibrary(deps.tf2_ros);

    tf2_eigen.addIncludePath(deps.rosidl_runtime_cpp);
    tf2_eigen.addIncludePath(deps.rosidl_typesupport_interface);
    tf2_eigen.addIncludePath(deps.tracetools);

    tf2_eigen.installHeadersDirectory(
        upstream.path("tf2_eigen/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(tf2_eigen);

    return tf2_eigen;
}
