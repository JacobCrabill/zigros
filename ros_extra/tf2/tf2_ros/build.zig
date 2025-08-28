const std = @import("std");

const zigros = @import("../../../zigros/zigros.zig");
const utils = @import("../../../build_utils.zig");
const RosidlGenerator = @import("../../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const RosIdlInterface = RosidlGenerator.Interface;

pub const Deps = struct {
    class_loader: *Compile,
    console_bridge: *Compile,
    message_filters_lib: *Compile,
    rclcpp: *Compile,
    rclcpp_action: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: std.Build.LazyPath,
    rosidl_typesupport_interface: std.Build.LazyPath,
    tracetools: std.Build.LazyPath,
    tf2_lib: *Compile,
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

    utils.writeAmentPackageIndexFile(b, "tf2_ros");

    const tf2_ros = b.addLibrary(.{
        .name = "tf2_ros",
        .root_module = b.createModule(std_module_opts),
        .linkage = args.linkage,
    });
    tf2_ros.addIncludePath(upstream.path("tf2_ros/include"));
    tf2_ros.addCSourceFiles(.{
        .root = upstream.path("tf2_ros/src"),
        .files = &.{
            "buffer.cpp",
            "create_timer_ros.cpp",
            "transform_listener.cpp",
            "buffer_client.cpp",
            "buffer_server.cpp",
            "transform_broadcaster.cpp",
            "static_transform_broadcaster.cpp",
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

    deps.action_msgs.link(tf2_ros);
    deps.builtin_interfaces.link(tf2_ros);
    deps.geometry_msgs.link(tf2_ros);
    deps.rcl_interfaces.link(tf2_ros);
    deps.service_msgs.link(tf2_ros);
    deps.statistics_msgs.link(tf2_ros);
    deps.std_msgs.link(tf2_ros);
    deps.tf2_msgs.link(tf2_ros);
    deps.unique_identifier_msgs.link(tf2_ros);
    deps.type_description_interfaces.link(tf2_ros);

    tf2_ros.linkLibrary(deps.class_loader);
    tf2_ros.linkLibrary(deps.console_bridge);
    tf2_ros.linkLibrary(deps.message_filters_lib);
    tf2_ros.linkLibrary(deps.rclcpp);
    tf2_ros.linkLibrary(deps.rclcpp_action);
    tf2_ros.linkLibrary(deps.rosidl_runtime_c);
    tf2_ros.linkLibrary(deps.tf2_lib);

    tf2_ros.addIncludePath(deps.rosidl_runtime_cpp);
    tf2_ros.addIncludePath(deps.rosidl_typesupport_interface);
    tf2_ros.addIncludePath(deps.tracetools);

    tf2_ros.installHeadersDirectory(
        upstream.path("tf2_ros/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(tf2_ros);

    // // Static Transform Publisher executable
    // // TODO: Needs access to RMW selection...
    // const static_transform_publisher = b.addExecutable(.{
    //     .name = "static_transform_publisher",
    //     .root_module = b.createModule(.{
    //         .target = args.target,
    //         .optimize = args.optimize,
    //         .strip = (args.optimize != .Debug),
    //         .pic = true,
    //     }),
    // });
    // // zigros.linkRclcpp(static_transform_publisher);
    // // zigros.linkLoggerSpd(static_transform_publisher);
    // // utils.linkRmw(static_transform_publisher, zigros, args.rmw);
    // deps.std_msgs.link(static_transform_publisher);
    // deps.geometry_msgs.link(static_transform_publisher);
    // deps.action_msgs.link(static_transform_publisher);
    // deps.unique_identifier_msgs.link(static_transform_publisher);
    // deps.tf2_msgs.link(static_transform_publisher);
    // static_transform_publisher.root_module.linkLibrary(tf2_ros);
    // static_transform_publisher.root_module.linkLibrary(deps.class_loader);
    // static_transform_publisher.root_module.linkLibrary(deps.console_bridge);
    // static_transform_publisher.root_module.linkLibrary(deps.message_filters_lib);
    // static_transform_publisher.root_module.linkLibrary(deps.tf2_lib);
    // static_transform_publisher.addIncludePath(upstream.path("tf2_ros/include"));
    // static_transform_publisher.addCSourceFiles(.{
    //     .root = upstream.path("tf2_ros/src"),
    //     .files = &.{
    //         "static_transform_broadcaster_program.cpp",
    //         "static_transform_broadcaster_node.cpp",
    //     },
    //     .flags = &.{
    //         "--std=c++17",
    //         "-Wall",
    //         "-Wextra",
    //         "-Wpedantic",
    //         "-Wno-deprecated",
    //         "-Wno-non-virtual-dtor",
    //         "-Wno-overloaded-virtual",
    //     },
    // });
    // b.installArtifact(static_transform_publisher);

    // TODO: Add tf2_echo, tf2_monitor executables if desired

    return tf2_ros;
}
