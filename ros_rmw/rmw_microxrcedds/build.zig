const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const Interface = @import("../../ros_core/rosidl/src/RosidlGenerator.zig").Interface;

const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    upstream: *Dependency,
    microcdr: *Compile,
    uxrce_client: *Compile,
    rcutils: *Compile,
    rmw: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_runtime_cpp: LazyPath,
};

pub const Artifacts = struct {
    rosidl_typesupport_uxrce_c: *Compile,
    rosidl_typesupport_uxrce_cpp: *Compile,
    rmw_uxrce: *Compile,
};

/// Only one UXRCE transport can be supported at a time in the build.
pub const Transport = enum(u8) {
    serial,
    udp,
    tcp,
    custom,
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps, transport: Transport) Artifacts {
    const linkage = args.linkage;
    const upstream = deps.upstream;
    const std_mod_options: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const uxrce_client = deps.uxrce_client;
    const microcdr = deps.microcdr;

    const rmw_microxrcedds = b.addLibrary(.{
        .name = "rmw_microxrcedds",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    var use_udp: ?i32 = null;
    var use_tcp: ?i32 = null;
    var use_serial: ?i32 = null;
    var use_custom: ?i32 = null;
    var use_ipv4: ?i32 = null;
    switch (transport) {
        .udp => {
            use_udp = 1;
            use_ipv4 = 1;
        },
        .tcp => {
            use_tcp = 1;
            use_ipv4 = 1;
        },
        .serial => {
            use_serial = 1;
        },
        .custom => {
            use_custom = 1;
        },
    }

    const config_h = b.addConfigHeader(.{
        .style = .{ .cmake = upstream.path("rmw_microxrcedds_c/src/config.h.in") },
        .include_path = "rmw_microxrcedds_c/config.h",
    }, .{
        .RMW_UXRCE_TRANSPORT_UDP = use_udp,
        .RMW_UXRCE_TRANSPORT_TCP = use_tcp,
        .RMW_UXRCE_TRANSPORT_SERIAL = use_serial,
        .RMW_UXRCE_TRANSPORT_CUSTOM = use_custom,
        .RMW_UXRCE_TRANSPORT_IPV4 = use_ipv4,
        .RMW_UXRCE_TRANSPORT_IPV6 = null,
        .RMW_UXRCE_USE_REFS = null,
        .RMW_UXRCE_ALLOW_DYNAMIC_ALLOCATIONS = 1,
        .RMW_UXRCE_GRAPH = null,
        .RMW_UROS_ERROR_HANDLING = null,

        .RMW_UXRCE_DEFAULT_UDP_IP = "127.0.0.1",
        .RMW_UXRCE_DEFAULT_UDP_PORT = "8888",
        .RMW_UXRCE_DEFAULT_TCP_IP = "127.0.0.1",
        .RMW_UXRCE_DEFAULT_TCP_PORT = "8888",
        .RMW_UXRCE_DEFAULT_SERIAL_DEVICE = "/dev/ttyAMA0",

        .RMW_UXRCE_ENTITY_CREATION_TIMEOUT = 1000,
        .RMW_UXRCE_ENTITY_DESTROY_TIMEOUT = 1000,

        .RMW_UXRCE_STREAM_HISTORY_INPUT = null,
        .RMW_UXRCE_STREAM_HISTORY_OUTPUT = null,
        .RMW_UXRCE_STREAM_HISTORY = 64,
        .RMW_UXRCE_PUBLISH_RELIABLE_TIMEOUT = 1000,
        .RMW_UXRCE_MAX_HISTORY = 128,

        .RMW_UXRCE_MAX_SESSIONS = 10,
        .RMW_UXRCE_MAX_NODES = 100,
        .RMW_UXRCE_MAX_PUBLISHERS = 500,
        .RMW_UXRCE_MAX_SUBSCRIPTIONS = 500,
        .RMW_UXRCE_MAX_SERVICES = 250,
        .RMW_UXRCE_MAX_CLIENTS = 250,
        .RMW_UXRCE_MAX_TOPICS = -1,
        .RMW_UXRCE_MAX_WAIT_SETS = 10,
        .RMW_UXRCE_MAX_GUARD_CONDITION = 10,

        .RMW_UXRCE_NODE_NAME_MAX_LENGTH = 128,
        .RMW_UXRCE_TOPIC_NAME_MAX_LENGTH = 128,
        .RMW_UXRCE_TYPE_NAME_MAX_LENGTH = 256,

        .RMW_UXRCE_REF_BUFFER_LENGTH = 100,
    });
    rmw_microxrcedds.addConfigHeader(config_h);
    rmw_microxrcedds.installConfigHeader(config_h);

    rmw_microxrcedds.addIncludePath(upstream.path("rmw_microxrcedds_c/include"));
    rmw_microxrcedds.addCSourceFiles(.{
        .root = upstream.path("rmw_microxrcedds_c/src"),
        .files = sources,
        .flags = &.{
            "--std=c99",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Werror-implicit-function-declaration",
            "-Wcast-align=strict",
            "-Wno-unknown-pragmas",
        },
    });
    rmw_microxrcedds.installHeadersDirectory(upstream.path("include"), "", .{});

    rmw_microxrcedds.linkLibrary(microcdr);
    rmw_microxrcedds.linkLibrary(uxrce_client);

    b.installArtifact(rmw_microxrcedds);

    return .{
        // rosidl_dynamic_typesupport_uxrce: *Compile,
        // rosidl_typesupport_uxrce_c: *Compile,
        // rosidl_typesupport_uxrce_cpp: *Compile,
        .rmw_uxrce = rmw_microxrcedds,
    };
}

const sources: []const []const u8 = &.{
    "identifiers.c",
    "memory.c",
    "rmw_client.c",
    "rmw_compare_gids_equal.c",
    "rmw_count.c",
    "rmw_event.c",
    "rmw_features.c",
    "rmw_get_gid_for_publisher.c",
    "rmw_get_gid_for_client.c",
    "rmw_get_implementation_identifier.c",
    "rmw_get_serialization_format.c",
    "rmw_get_topic_endpoint_info.c",
    "rmw_get_endpoint_network_flow.c",
    "rmw_qos_profile_check_compatible.c",
    "rmw_dynamic_message_type_support.c",
    "rmw_guard_condition.c",
    "rmw_init.c",
    "rmw_logging.c",
    "rmw_microxrcedds_topic.c",
    "rmw_node.c",
    "rmw_node_info_and_types.c",
    "rmw_node_names.c",
    "rmw_publish.c",
    "rmw_publisher.c",
    "rmw_request.c",
    "rmw_response.c",
    "rmw_serialize.c",
    "rmw_service.c",
    "rmw_service_names_and_types.c",
    "rmw_service_server_is_available.c",
    "rmw_subscription.c",
    "rmw_take.c",
    "rmw_topic_names_and_types.c",
    "rmw_trigger_guard_condition.c",
    "rmw_wait.c",
    "rmw_wait_set.c",
    "types.c",
    "utils.c",
    "callbacks.c",
    "rmw_event_callbacks.c",
    "rmw_uxrce_transports.c",
    "rmw_microros/continous_serialization.c",
    "rmw_microros/init_options.c",
    "rmw_microros/time_sync.c",
    "rmw_microros/ping.c",
    "rmw_microros/timing.c",
    "rmw_microros/discovery.c", // RMW_UXRCE_TRANSPORT_UDP or RMW_UXRCE_TRANSPORT_TCP
    "rmw_microros/custom_transport.c", // RMW_UXRCE_TRANSPORT_CUSTOM
    "rmw_graph.c", // RMW_UXRCE_GRAPH
    "rmw_microros/error_handling.c", // RMW_UROS_ERROR_HANDLING
};
