const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;

pub const Deps = struct {
    ament_index_cpp: *Compile,
    pluginlib: *Compile,
    rclcpp: *Compile,
    rcpputils: *Compile,
    rcutils: *Compile,
    rmw: *Compile,
    rmw_implementation: *Compile, // proxy RMW implementation
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: LazyPath,
    rosidl_typesupport_c: *Compile,
    rosidl_typesupport_cpp: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_typesupport_introspection_c: *Compile,
    rosidl_typesupport_introspection_cpp: *Compile,
    tracetools: LazyPath, // needed for rclcpp
    yaml_cpp: *Compile,
    builtin_interfaces: RosidlGenerator.Interface,
    service_msgs: RosidlGenerator.Interface,
    type_description_interfaces: RosidlGenerator.Interface,
    // TODO: dependencies of dependencies
};

pub const Artifacts = struct {
    rosbag2_storage: *Compile,
    rosbag2_cpp: *Compile,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, opts: zigros.CompileArgs) Artifacts {
    const upstream = b.dependency("rosbag2", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    // ---- rosbag2_storage ---------------------------------------------------

    utils.writeAmentIndexFile(b, "rosbag2_storage");

    const rosbag2_storage = b.addLibrary(.{
        .name = "rosbag2_storage",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    rosbag2_storage.addIncludePath(upstream.path("rosbag2_storage/include"));
    rosbag2_storage.addCSourceFiles(.{
        .root = upstream.path("rosbag2_storage/src"),
        .files = &.{
            "rosbag2_storage/qos.cpp",
            "rosbag2_storage/default_storage_id.cpp",
            "rosbag2_storage/metadata_io.cpp",
            "rosbag2_storage/ros_helper.cpp",
            "rosbag2_storage/storage_factory.cpp",
            "rosbag2_storage/storage_options.cpp",
            "rosbag2_storage/base_io_interface.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });

    // TODO: limit to only the bare necessities
    // find_package(pluginlib REQUIRED)
    // find_package(rcutils REQUIRED)
    // find_package(rclcpp REQUIRED)
    // find_package(rmw REQUIRED)
    // find_package(yaml_cpp_vendor REQUIRED)
    // find_package(yaml-cpp REQUIRED)
    zigros.linkDependencyStruct(rosbag2_storage, deps, .cpp);

    rosbag2_storage.installHeadersDirectory(
        upstream.path("rosbag2_storage/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(rosbag2_storage);

    // ---- rosbag2_cpp ---------------------------------------------------

    utils.writeAmentIndexFile(b, "rosbag2_cpp");

    const rosbag2_cpp = b.addLibrary(.{
        .name = "rosbag2_cpp",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    rosbag2_cpp.addIncludePath(upstream.path("rosbag2_cpp/include"));
    rosbag2_cpp.addCSourceFiles(.{
        .root = upstream.path("rosbag2_cpp/src"),
        .files = &.{
            "rosbag2_cpp/cache/cache_consumer.cpp",
            "rosbag2_cpp/cache/circular_message_cache.cpp",
            "rosbag2_cpp/cache/message_cache.cpp",
            "rosbag2_cpp/cache/message_cache_buffer.cpp",
            "rosbag2_cpp/cache/message_cache_circular_buffer.cpp",
            "rosbag2_cpp/clocks/time_controller_clock.cpp",
            "rosbag2_cpp/message_definitions/local_message_definition_source.cpp",
            "rosbag2_cpp/readers/sequential_reader.cpp",
            "rosbag2_cpp/types/introspection_message.cpp",
            "rosbag2_cpp/types/introspection_message.cpp",
            "rosbag2_cpp/converter.cpp",
            "rosbag2_cpp/info.cpp",
            "rosbag2_cpp/reader.cpp",
            "rosbag2_cpp/reindexer.cpp",
            "rosbag2_cpp/rmw_implemented_serialization_format_converter.cpp",
            "rosbag2_cpp/serialization_format_converter_factory.cpp",
            "rosbag2_cpp/service_utils.cpp",
            "rosbag2_cpp/typesupport_helpers.cpp",
            "rosbag2_cpp/writer.cpp",
            "rosbag2_cpp/writers/sequential_writer.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wthread-safety" },
    });
    rosbag2_cpp.linkLibrary(rosbag2_storage);

    zigros.linkDependencyStruct(rosbag2_cpp, deps, .cpp);

    rosbag2_cpp.installHeadersDirectory(
        upstream.path("rosbag2_cpp/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(rosbag2_cpp);

    return .{ .rosbag2_storage = rosbag2_storage, .rosbag2_cpp = rosbag2_cpp };
}
