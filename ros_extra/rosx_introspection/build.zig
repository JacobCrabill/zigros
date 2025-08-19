const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;

pub const Deps = struct {
    ament_index_cpp: *Compile,
    rapidjson: *Compile,
    fastcdr: *Compile,
    rclcpp: *Compile,
    // TODO
    rosbag2_cpp: *Compile,
    rosidl_runtime_cpp: LazyPath,
    builtin_interfaces: RosidlGenerator.Interface,
    rcl_interfaces: RosidlGenerator.Interface,
    service_msgs: RosidlGenerator.Interface,
    rosidl_typesupport_interface: LazyPath,
    type_description_interfaces: RosidlGenerator.Interface,
    tracetools: LazyPath,
    statistics_msgs: RosidlGenerator.Interface,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, args: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("rosx_introspection", args);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    utils.writeAmentIndexFile(b, "rosx_introspection");

    const rosx_introspection = b.addLibrary(.{
        .name = "rosx_introspection",
        .root_module = b.createModule(std_module_opts),
        .linkage = args.linkage,
    });
    rosx_introspection.addIncludePath(upstream.path("include"));
    rosx_introspection.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "ros_type.cpp",
            "ros_field.cpp",
            "stringtree_leaf.cpp",
            "ros_message.cpp",
            "ros_parser.cpp",
            "deserializer.cpp",
            "serializer.cpp",
            "ros_utils/message_definition_cache.cpp",
            "ros_utils/ros2_helpers.cpp",
        },
        .flags = &.{
            "--std=c++17",
            "-fPIC",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wno-deprecated",
            "-Wno-non-virtual-dtor",
            "-Wno-overloaded-virtual",
        },
    });

    zigros.linkDependencyStruct(rosx_introspection, deps, .cpp);

    rosx_introspection.installHeadersDirectory(upstream.path("include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });
    b.installArtifact(rosx_introspection);

    return rosx_introspection;
}
