const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;

pub const MsgDeps = struct {
    rosidl_generator_build_deps: RosidlGenerator.BuildDeps,
    rosidl_generator_deps: RosidlGenerator.Deps,
};

pub const Deps = struct {
    ament_index_cpp: *Compile,
    pluginlib: *Compile,
    rclcpp: *Compile,
    rcpputils: *Compile,
    rcutils: *Compile,
    tinyxml2: *Compile,
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
};

pub const RosbagTransportDeps = struct {
    keyboard_handler: *Compile,
    rcl_interfaces: RosidlGenerator.Interface,
    rclcpp_components: *Compile,
    statistics_msgs: RosidlGenerator.Interface,
    rosgraph_msgs: RosidlGenerator.Interface,
};

pub const McapDeps = struct {
    zstd: *Compile,
    lz4: *Compile,
};

pub const Artifacts = struct {
    rosbag2_storage: *Compile,
    rosbag2_storage_mcap: *Compile,
    rosbag2_cpp: *Compile,
    rosbag2_compression: *Compile,
    rosbag2_transport: *Compile,
    rosbag2_interfaces: RosidlGenerator.Interface,
    mcap: *Compile,
};

pub fn buildWithArgs(b: *std.Build, msg_deps: MsgDeps, deps: Deps, mcap_deps: McapDeps, transport_deps: RosbagTransportDeps, opts: zigros.CompileArgs) Artifacts {
    const upstream = b.dependency("rosbag2", opts); // todo: take as input

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    // ---- rosbag2_storage ---------------------------------------------------

    utils.writeAmentPackageIndexFile(b, "rosbag2_storage");

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
        .flags = &.{ "-fPIC", "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wno-deprecated" },
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

    utils.writeAmentPackageIndexFile(b, "rosbag2_cpp");

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
        .flags = &.{
            "-fPIC",           "--std=c++17",
            "-Wall",           "-Wextra",
            "-Wpedantic",      "-Wthread-safety",
            "-Wno-deprecated",
        },
    });
    rosbag2_cpp.linkLibrary(rosbag2_storage);

    // ament_index_cpp: *Compile,
    // pluginlib: *Compile,
    // rclcpp: *Compile,
    // rcpputils: *Compile,
    // rcutils: *Compile,
    // rmw: *Compile,
    // rmw_implementation: *Compile, // proxy RMW implementation
    // rosidl_runtime_c: *Compile,
    // rosidl_runtime_cpp: LazyPath,
    // rosidl_typesupport_c: *Compile,
    // rosidl_typesupport_cpp: *Compile,
    // rosidl_typesupport_interface: LazyPath,
    // rosidl_typesupport_introspection_c: *Compile,
    // rosidl_typesupport_introspection_cpp: *Compile,
    // tracetools: LazyPath, // needed for rclcpp
    // yaml_cpp: *Compile,
    // builtin_interfaces: RosidlGenerator.Interface,
    // service_msgs: RosidlGenerator.Interface,
    // type_description_interfaces: RosidlGenerator.Interface,
    zigros.linkDependencyStruct(rosbag2_cpp, deps, .cpp);

    rosbag2_cpp.installHeadersDirectory(
        upstream.path("rosbag2_cpp/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(rosbag2_cpp);

    // ---- MCAP Library ----
    // rosbag2 just takes the header-only mcap library and turns it into a precompiled lib
    // (main.cpp just does #define MCAP_IMPLEMENTATION and #include <mcap/mcap.h>)
    const mcap = b.dependency("mcap", .{}); // todo: take as input

    const mcap_vendor = b.addLibrary(.{
        .name = "mcap",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    mcap_vendor.addIncludePath(upstream.path("mcap_vendor/src"));
    mcap_vendor.addIncludePath(mcap.path("cpp/mcap/include"));
    mcap_vendor.addCSourceFile(.{
        .file = upstream.path("mcap_vendor/src/main.cpp"),
        .flags = &.{
            "-fPIC",                "--std=c++17",
            "-Wall",                "-Wextra",
            "-Wpedantic",           "-Wno-deprecated",
            "-fvisibility=default",
        },
    });
    mcap_vendor.linkLibrary(mcap_deps.lz4);
    mcap_vendor.linkLibrary(mcap_deps.zstd);
    mcap_vendor.installHeadersDirectory(mcap.path("cpp/mcap/include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });

    b.installArtifact(mcap_vendor);

    // ---- rosbag2_storage_mcap ----
    // find_package(mcap_vendor REQUIRED)
    // find_package(pluginlib REQUIRED)
    // find_package(rcutils REQUIRED)
    // find_package(rosbag2_storage REQUIRED)
    // find_package(yaml_cpp_vendor REQUIRED)
    // find_package(yaml-cpp REQUIRED)

    const rosbag2_storage_mcap = b.addLibrary(.{
        .name = "rosbag2_storage_mcap",
        .root_module = b.createModule(std_module_opts),
        // HACK: pluginlib requires this :(
        .linkage = .dynamic, // opts.linkage,
    });

    rosbag2_storage_mcap.addIncludePath(upstream.path("rosbag2_storage_mcap/include"));
    rosbag2_storage_mcap.addCSourceFile(.{
        .file = upstream.path("rosbag2_storage_mcap/src/mcap_storage.cpp"),
        .flags = &.{
            "-fPIC",                                       "--std=c++17",
            "-Wall",                                       "-Wextra",
            "-Wpedantic",                                  "-Wno-deprecated",
            "-DROSBAG2_STORAGE_MCAP_HAS_STORAGE_OPTIONS",  "-DROSBAG2_STORAGE_MCAP_WRITER_CREATES_DIRECTORY",
            "-DROSBAG2_STORAGE_MCAP_OVERRIDE_SEEK_METHOD", "-DROSBAG2_STORAGE_MCAP_HAS_YAML_HPP",
            "-DROSBAG2_STORAGE_MCAP_HAS_SET_READ_ORDER",   "-DROSBAG2_STORAGE_MCAP_HAS_UPDATE_METADATA",
            "-fvisibility=default",
        },
    });

    rosbag2_storage_mcap.linkLibrary(mcap_vendor);
    rosbag2_storage_mcap.linkLibrary(rosbag2_storage);
    zigros.linkDependencyStruct(rosbag2_storage_mcap, deps, .cpp);

    rosbag2_storage_mcap.installHeadersDirectory(
        upstream.path("rosbag2_storage_mcap/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(rosbag2_storage_mcap);

    // ---- rosbag2 interfaces ----
    var rosbag2_interfaces = RosidlGenerator.create(
        b,
        "rosbag2_interfaces",
        msg_deps.rosidl_generator_deps,
        msg_deps.rosidl_generator_build_deps,
        opts,
    );
    rosbag2_interfaces.addInterfaces(
        upstream.path("rosbag2_interfaces"),
        &.{
            "msg/ReadSplitEvent.msg",
            "msg/WriteSplitEvent.msg",
            "srv/Burst.srv",
            "srv/GetRate.srv",
            "srv/IsPaused.srv",
            "srv/Pause.srv",
            "srv/Play.srv",
            "srv/PlayNext.srv",
            "srv/Resume.srv",
            "srv/Seek.srv",
            "srv/SetRate.srv",
            "srv/Snapshot.srv",
            "srv/SplitBagfile.srv",
            "srv/Stop.srv",
            "srv/TogglePaused.srv",
        },
    );
    rosbag2_interfaces.addDependency("builtin_interfaces", deps.builtin_interfaces);
    rosbag2_interfaces.addDependency("service_msgs", deps.service_msgs);

    rosbag2_interfaces.installArtifacts();

    // ---- rosbag2_compression ----

    const rosbag2_compression = b.addLibrary(.{
        .name = "rosbag2_compression",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    rosbag2_compression.addIncludePath(upstream.path("rosbag2_compression/include"));
    rosbag2_compression.addCSourceFiles(.{
        .root = upstream.path("rosbag2_compression/src/rosbag2_compression"),
        .files = &.{
            "compression_factory.cpp",
            "compression_options.cpp",
            "sequential_compression_reader.cpp",
            "sequential_compression_writer.cpp",
        },
        .flags = &.{
            "-fPIC",      "--std=c++17",
            "-Wall",      "-Wextra",
            "-Wpedantic", "-Wno-deprecated",
        },
    });

    rosbag2_compression.linkLibrary(rosbag2_storage);
    rosbag2_compression.linkLibrary(rosbag2_cpp);
    zigros.linkDependencyStruct(rosbag2_compression, deps, .cpp);

    rosbag2_compression.installHeadersDirectory(
        upstream.path("rosbag2_compression/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(rosbag2_compression);

    // ---- rosbag2_transport ----

    const rosbag2_transport = b.addLibrary(.{
        .name = "rosbag2_transport",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    rosbag2_transport.addIncludePath(upstream.path("rosbag2_transport/include"));
    rosbag2_transport.addCSourceFiles(.{
        .root = upstream.path("rosbag2_transport/src/rosbag2_transport"),
        .files = &.{
            "bag_rewrite.cpp",
            "player.cpp",
            "play_options.cpp",
            "player_service_client.cpp",
            "reader_writer_factory.cpp",
            "recorder.cpp",
            "record_options.cpp",
            "topic_filter.cpp",
            "config_options_from_node_params.cpp",
        },
        .flags = &.{ "-fPIC", "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wno-deprecated" },
    });

    rosbag2_transport.linkLibrary(rosbag2_storage);
    rosbag2_transport.linkLibrary(rosbag2_cpp);
    rosbag2_transport.linkLibrary(rosbag2_compression);
    rosbag2_interfaces.artifacts.link(rosbag2_transport);
    zigros.linkDependencyStruct(rosbag2_transport, deps, .cpp);
    zigros.linkDependencyStruct(rosbag2_transport, transport_deps, .cpp);

    rosbag2_transport.installHeadersDirectory(
        upstream.path("rosbag2_transport/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(rosbag2_transport);

    return .{
        .rosbag2_storage = rosbag2_storage,
        .rosbag2_storage_mcap = rosbag2_storage_mcap,
        .rosbag2_cpp = rosbag2_cpp,
        .rosbag2_interfaces = rosbag2_interfaces.artifacts,
        .rosbag2_compression = rosbag2_compression,
        .rosbag2_transport = rosbag2_transport,
        .mcap = mcap_vendor,
    };
}
