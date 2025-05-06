const std = @import("std");

const zigros = @import("../zigros/zigros.zig");
const Interface = @import("../rosidl/src/RosidlGenerator.zig").Interface;

const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    upstream: *Dependency,
    rosidl_dynamic_typesupport_fastrtps_upstream: *Dependency,
    rosidl_typesupport_fastrtps_upstream: *Dependency,
    tracetools: LazyPath,
    rcutils: *Compile,
    fastcdr: *Compile,
    fastdds: *Compile,
    rcpputils: *Compile,
    rmw: *Compile,
    rmw_dds_common: *Compile,
    rmw_dds_common_interface: Interface,
    rosidl_runtime_c: *Compile,
    rosidl_typesupport_introspection_c: *Compile,
    rosidl_typesupport_introspection_cpp: *Compile,
    rosidl_dynamic_typesupport: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_runtime_cpp: LazyPath,
};

pub const Artifacts = struct {
    rosidl_dynamic_typesupport_fastrtps: *Compile,
    rosidl_typesupport_fastrtps_c: *Compile,
    rosidl_typesupport_fastrtps_cpp: *Compile,
    rmw_fastrtps_shared: *Compile,
    rmw_fastrtps: *Compile,
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps) Artifacts {
    const linkage = args.linkage;
    const upstream = deps.upstream;
    const std_mod_options: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const typesupport_fastrtps_upstream = deps.rosidl_typesupport_fastrtps_upstream;

    // FastRTPS TypeSupport - C
    var rosidl_typesupport_fastrtps_c = b.addLibrary(.{
        .name = "rosidl_typesupport_fastrtps_c",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    rosidl_typesupport_fastrtps_c.addCSourceFiles(.{
        .root = typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_c/src"),
        .files = &.{ "identifier.cpp", "wstring_conversion.cpp" },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });
    rosidl_typesupport_fastrtps_c.addIncludePath(typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_c/include"));
    rosidl_typesupport_fastrtps_c.installHeadersDirectory(typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_c/include"), "", .{
        .include_extensions = &.{ ".h", ".hpp" },
    });
    rosidl_typesupport_fastrtps_c.linkLibrary(deps.fastcdr);
    rosidl_typesupport_fastrtps_c.linkLibrary(deps.rosidl_runtime_c);

    b.installArtifact(rosidl_typesupport_fastrtps_c);

    // FastRTPS TypeSupport - C++
    var rosidl_typesupport_fastrtps_cpp = b.addLibrary(.{
        .name = "rosidl_typesupport_fastrtps_cpp",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    rosidl_typesupport_fastrtps_cpp.addCSourceFiles(.{
        .root = typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_cpp/src"),
        .files = &.{ "identifier.cpp", "wstring_conversion.cpp" },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });
    rosidl_typesupport_fastrtps_cpp.addIncludePath(typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_cpp/include"));
    rosidl_typesupport_fastrtps_cpp.installHeadersDirectory(typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_cpp/include"), "", .{
        .include_extensions = &.{ ".h", ".hpp" },
    });
    rosidl_typesupport_fastrtps_cpp.linkLibrary(deps.rmw);
    rosidl_typesupport_fastrtps_cpp.linkLibrary(deps.fastcdr);
    rosidl_typesupport_fastrtps_cpp.linkLibrary(deps.rosidl_runtime_c);

    b.installArtifact(rosidl_typesupport_fastrtps_cpp);

    // rosidl_dynamic_typesupport_fastrtps
    const dynamic_typesupport_fastrtps_upstream = deps.rosidl_dynamic_typesupport_fastrtps_upstream;

    var rosidl_dynamic_typesupport_fastrtps = b.addLibrary(.{
        .name = "rosidl_dynamic_typesupport_fastrtps",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    if (args.optimize == .ReleaseSmall and linkage == .static) {
        rosidl_dynamic_typesupport_fastrtps.link_function_sections = true;
        rosidl_dynamic_typesupport_fastrtps.link_data_sections = true;
    }

    rosidl_dynamic_typesupport_fastrtps.linkLibrary(rosidl_typesupport_fastrtps_c);
    rosidl_dynamic_typesupport_fastrtps.linkLibrary(rosidl_typesupport_fastrtps_cpp);
    zigros.linkDependencyStruct(rosidl_dynamic_typesupport_fastrtps, deps, .cpp);

    rosidl_dynamic_typesupport_fastrtps.addCSourceFiles(.{
        .root = dynamic_typesupport_fastrtps_upstream.path(""),
        .files = &.{
            "src/detail/fastrtps_dynamic_data.cpp",
            "src/detail/fastrtps_dynamic_type.cpp",
            "src/detail/fastrtps_serialization_support.cpp",
            "src/detail/utils.cpp",
            "src/identifier.cpp",
            "src/serialization_support.cpp",
        },
        .flags = &.{"-fvisibility=hidden"},
    });
    rosidl_dynamic_typesupport_fastrtps.addIncludePath(dynamic_typesupport_fastrtps_upstream.path("include"));
    rosidl_dynamic_typesupport_fastrtps.installHeadersDirectory(dynamic_typesupport_fastrtps_upstream.path("include"), "", .{});

    b.installArtifact(rosidl_dynamic_typesupport_fastrtps);

    // ---- Core FastRTPS Middleware -------------------------------------------

    const rmw_fastrtps_shared = b.addLibrary(.{
        .name = "rmw_fastrtps_shared_cpp",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    rmw_fastrtps_shared.addCSourceFiles(.{
        .root = upstream.path("rmw_fastrtps_shared_cpp/src"),
        .files = rmw_fastrtps_shared_files,
        .flags = &.{
            "--std=c++17",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wthread-safety",
            "-Wno-deprecated-declarations",
            "-Wno-unknown-pragmas",
        },
    });

    rmw_fastrtps_shared.addIncludePath(upstream.path("rmw_fastrtps_shared_cpp/include"));
    rmw_fastrtps_shared.installHeadersDirectory(upstream.path("rmw_fastrtps_shared_cpp/include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });

    rmw_fastrtps_shared.linkLibrary(rosidl_dynamic_typesupport_fastrtps);
    zigros.linkDependencyStruct(rmw_fastrtps_shared, deps, .cpp);

    b.installArtifact(rmw_fastrtps_shared);

    // ---- RMW FastRTPS -------------------------------------------------------

    const rmw_fastrtps = b.addLibrary(.{
        .name = "rmw_fastrtps_cpp",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    rmw_fastrtps.addCSourceFiles(.{
        .root = upstream.path("rmw_fastrtps_cpp/src"),
        .files = rmw_fastrtps_files,
        .flags = &.{
            "--std=c++17",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wthread-safety",
            "-Wno-deprecated-declarations",
            "-Wno-switch-bool",
            "-Wno-unknown-pragmas",
        },
    });

    rmw_fastrtps.addIncludePath(upstream.path("rmw_fastrtps_cpp/include"));
    rmw_fastrtps.installHeadersDirectory(upstream.path("rmw_fastrtps_cpp/include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });

    rmw_fastrtps.linkLibrary(rosidl_dynamic_typesupport_fastrtps);
    rmw_fastrtps.linkLibrary(rosidl_typesupport_fastrtps_c);
    rmw_fastrtps.linkLibrary(rosidl_typesupport_fastrtps_cpp);
    rmw_fastrtps.linkLibrary(rmw_fastrtps_shared);
    zigros.linkDependencyStruct(rmw_fastrtps, deps, .cpp);

    b.installArtifact(rmw_fastrtps);

    return .{
        .rosidl_dynamic_typesupport_fastrtps = rosidl_dynamic_typesupport_fastrtps,
        .rosidl_typesupport_fastrtps_c = rosidl_typesupport_fastrtps_c,
        .rosidl_typesupport_fastrtps_cpp = rosidl_typesupport_fastrtps_cpp,
        .rmw_fastrtps_shared = rmw_fastrtps_shared,
        .rmw_fastrtps = rmw_fastrtps,
    };
}

const rmw_fastrtps_shared_files: []const []const u8 = &.{
    "custom_participant_info.cpp",
    "custom_publisher_info.cpp",
    "custom_subscriber_info.cpp",
    "create_rmw_gid.cpp",
    "demangle.cpp",
    "init_rmw_context_impl.cpp",
    "listener_thread.cpp",
    "namespace_prefix.cpp",
    "participant.cpp",
    "publisher.cpp",
    "qos.cpp",
    "rmw_client.cpp",
    "rmw_compare_gids_equal.cpp",
    "rmw_count.cpp",
    "rmw_event.cpp",
    "rmw_features.cpp",
    "rmw_get_endpoint_network_flow.cpp",
    "rmw_get_gid_for_client.cpp",
    "rmw_get_gid_for_publisher.cpp",
    "rmw_get_topic_endpoint_info.cpp",
    "rmw_guard_condition.cpp",
    "rmw_init.cpp",
    "rmw_logging.cpp",
    "rmw_node.cpp",
    "rmw_node_info_and_types.cpp",
    "rmw_node_names.cpp",
    "rmw_publish.cpp",
    "rmw_publisher.cpp",
    "rmw_qos.cpp",
    "rmw_request.cpp",
    "rmw_response.cpp",
    "rmw_security_logging.cpp",
    "rmw_service.cpp",
    "rmw_service_names_and_types.cpp",
    "rmw_service_server_is_available.cpp",
    "rmw_subscription.cpp",
    "rmw_take.cpp",
    "rmw_topic_names_and_types.cpp",
    "rmw_trigger_guard_condition.cpp",
    "rmw_wait.cpp",
    "rmw_wait_set.cpp",
    "subscription.cpp",
    "time_utils.cpp",
    "TypeSupport_impl.cpp",
    "utils.cpp",
};

const rmw_fastrtps_files: []const []const u8 = &.{
    "get_client.cpp",
    "get_participant.cpp",
    "get_publisher.cpp",
    "get_service.cpp",
    "get_subscriber.cpp",
    "identifier.cpp",
    "init_rmw_context_impl.cpp",
    "publisher.cpp",
    "rmw_logging.cpp",
    "rmw_client.cpp",
    "rmw_compare_gids_equal.cpp",
    "rmw_count.cpp",
    "rmw_dynamic_message_type_support.cpp",
    "rmw_event.cpp",
    "rmw_features.cpp",
    "rmw_get_gid_for_client.cpp",
    "rmw_get_gid_for_publisher.cpp",
    "rmw_get_implementation_identifier.cpp",
    "rmw_get_serialization_format.cpp",
    "rmw_get_topic_endpoint_info.cpp",
    "rmw_guard_condition.cpp",
    "rmw_init.cpp",
    "rmw_node.cpp",
    "rmw_node_info_and_types.cpp",
    "rmw_node_names.cpp",
    "rmw_publish.cpp",
    "rmw_publisher.cpp",
    "rmw_qos.cpp",
    "rmw_request.cpp",
    "rmw_response.cpp",
    "rmw_serialize.cpp",
    "rmw_service.cpp",
    "rmw_service_names_and_types.cpp",
    "rmw_service_server_is_available.cpp",
    "rmw_subscription.cpp",
    "rmw_take.cpp",
    "rmw_topic_names_and_types.cpp",
    "rmw_trigger_guard_condition.cpp",
    "rmw_wait.cpp",
    "rmw_wait_set.cpp",
    "serialization_format.cpp",
    "subscription.cpp",
    "type_support_common.cpp",
    "rmw_get_endpoint_network_flow.cpp",
};
