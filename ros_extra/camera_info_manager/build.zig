const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const RosIdlInterface = RosidlGenerator.Interface;

pub const Deps = struct {
    class_loader: *Compile,
    console_bridge: *Compile,
    message_filters_lib: *Compile,
    rclcpp: *Compile,
    rclcpp_action: *Compile,
    rclcpp_lifecycle: *Compile,
    rosidl_runtime_c: *Compile,
    yaml_cpp_lib: *Compile,
    rosidl_runtime_cpp: std.Build.LazyPath,
    rosidl_typesupport_interface: std.Build.LazyPath,
    tracetools: std.Build.LazyPath,
    action_msgs: RosIdlInterface,
    builtin_interfaces: RosIdlInterface,
    geometry_msgs: RosIdlInterface,
    lifecycle_msgs: RosIdlInterface,
    rcl_interfaces: RosIdlInterface,
    service_msgs: RosIdlInterface,
    sensor_msgs: RosIdlInterface,
    statistics_msgs: RosIdlInterface,
    std_msgs: RosIdlInterface,
    unique_identifier_msgs: RosIdlInterface,
    type_description_interfaces: RosIdlInterface,
};

pub const Artifacts = struct {
    camera_calibration_parsers: *Compile,
    camera_info_manager: *Compile,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, opts: zigros.CompileArgs) Artifacts {
    const upstream = b.dependency("image_common", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const camera_calibration_parsers = b.addLibrary(.{
        .name = "camera_calibration_parsers",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    camera_calibration_parsers.addIncludePath(upstream.path("camera_calibration_parsers/include"));
    camera_calibration_parsers.addCSourceFiles(.{
        .root = upstream.path("camera_calibration_parsers/src"),
        .files = &.{
            "parse.cpp",
            "parse_ini.cpp",
            "parse_yml.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Werror", "-Wpedantic", "-Wno-deprecated" },
    });
    deps.action_msgs.stepLink(camera_calibration_parsers);
    deps.builtin_interfaces.stepLink(camera_calibration_parsers);
    deps.geometry_msgs.stepLink(camera_calibration_parsers);
    deps.rcl_interfaces.stepLink(camera_calibration_parsers);
    deps.sensor_msgs.stepLink(camera_calibration_parsers);
    deps.service_msgs.stepLink(camera_calibration_parsers);
    deps.statistics_msgs.stepLink(camera_calibration_parsers);
    deps.std_msgs.stepLink(camera_calibration_parsers);
    deps.type_description_interfaces.stepLink(camera_calibration_parsers);
    deps.unique_identifier_msgs.stepLink(camera_calibration_parsers);

    camera_calibration_parsers.linkLibrary(deps.class_loader);
    camera_calibration_parsers.linkLibrary(deps.console_bridge);
    camera_calibration_parsers.linkLibrary(deps.message_filters_lib);
    camera_calibration_parsers.linkLibrary(deps.rclcpp);
    camera_calibration_parsers.linkLibrary(deps.rclcpp_action);
    camera_calibration_parsers.linkLibrary(deps.rosidl_runtime_c);

    camera_calibration_parsers.addIncludePath(deps.rosidl_runtime_cpp);
    camera_calibration_parsers.addIncludePath(deps.rosidl_typesupport_interface);
    camera_calibration_parsers.addIncludePath(deps.tracetools);
    if (b.named_lazy_paths.get("sensor_msgs")) |sensor_msgs_inc| {
        camera_calibration_parsers.addIncludePath(sensor_msgs_inc);
    }

    camera_calibration_parsers.linkLibrary(deps.yaml_cpp_lib);
    camera_calibration_parsers.installHeadersDirectory(
        upstream.path("camera_calibration_parsers/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(camera_calibration_parsers);

    const camera_info_manager = b.addLibrary(.{
        .name = "camera_info_manager",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    camera_info_manager.addIncludePath(upstream.path("camera_info_manager/include"));
    camera_info_manager.addCSourceFiles(.{
        .root = upstream.path("camera_info_manager/src"),
        .files = &.{"camera_info_manager.cpp"},
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Werror", "-Wpedantic", "-Wno-deprecated" },
    });

    deps.action_msgs.stepLink(camera_info_manager);
    deps.builtin_interfaces.stepLink(camera_info_manager);
    deps.geometry_msgs.stepLink(camera_info_manager);
    deps.lifecycle_msgs.stepLink(camera_info_manager);
    deps.rcl_interfaces.stepLink(camera_info_manager);
    deps.sensor_msgs.stepLink(camera_info_manager);
    deps.service_msgs.stepLink(camera_info_manager);
    deps.statistics_msgs.stepLink(camera_info_manager);
    deps.std_msgs.stepLink(camera_info_manager);
    deps.type_description_interfaces.stepLink(camera_info_manager);
    deps.unique_identifier_msgs.stepLink(camera_info_manager);

    camera_info_manager.linkLibrary(deps.class_loader);
    camera_info_manager.linkLibrary(deps.console_bridge);
    camera_info_manager.linkLibrary(deps.message_filters_lib);
    camera_info_manager.linkLibrary(deps.rclcpp);
    camera_info_manager.linkLibrary(deps.rclcpp_action);
    camera_info_manager.linkLibrary(deps.rclcpp_lifecycle);
    camera_info_manager.linkLibrary(deps.rosidl_runtime_c);

    camera_info_manager.addIncludePath(deps.rosidl_runtime_cpp);
    camera_info_manager.addIncludePath(deps.rosidl_typesupport_interface);
    camera_info_manager.addIncludePath(deps.tracetools);
    if (b.named_lazy_paths.get("sensor_msgs")) |sensor_msgs_inc| {
        camera_info_manager.addIncludePath(sensor_msgs_inc);
    }

    camera_info_manager.linkLibrary(camera_calibration_parsers);

    camera_info_manager.installHeadersDirectory(
        upstream.path("camera_info_manager/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(camera_info_manager);

    return .{
        .camera_calibration_parsers = camera_calibration_parsers,
        .camera_info_manager = camera_info_manager,
    };
}
