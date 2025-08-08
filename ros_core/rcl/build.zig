const std = @import("std");
const zigros = @import("../../zigros/zigros.zig");
const Interface = @import("../rosidl/src/RosidlGenerator.zig").Interface;

const Dependency = std.Build.Dependency;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;
const LazyPath = std.Build.LazyPath;

pub const Deps = struct {
    upstream: *Dependency,
    rcutils: *Compile,
    yaml: *Compile,
    rmw: *Compile,
    tracetools: LazyPath,
    rosidl_runtime_c: *Compile,
    rosidl_dynamic_typesupport: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rcl_logging_interface: *Compile,
    type_description_interfaces: Interface,
    action_msgs: Interface,
    service_msgs: Interface,
    unique_identifier_msgs: Interface,
    builtin_interfaces: Interface,
    rcl_interfaces: Interface,
    lifecycle_msgs: Interface,
};

pub const Artifacts = struct {
    rcl_yaml_param_parser: *Compile,
    rcl: *Compile,
    rcl_action: *Compile,
    rcl_lifecycle: *Compile,
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps) Artifacts {
    const target = args.target;
    const optimize = args.optimize;
    const linkage = args.linkage;

    const upstream = deps.upstream;

    var yaml_param_parser = b.addLibrary(.{
        .name = "rcl_yaml_param_parser",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        }),
        .linkage = linkage,
    });

    yaml_param_parser.linkLibC();

    yaml_param_parser.addIncludePath(upstream.path("rcl_yaml_param_parser/include"));
    yaml_param_parser.installHeadersDirectory(
        upstream.path("rcl_yaml_param_parser/include"),
        "",
        .{},
    );

    yaml_param_parser.addCSourceFiles(.{
        .root = upstream.path("rcl_yaml_param_parser"),
        .files = &.{
            "src/add_to_arrays.c",
            "src/namespace.c",
            "src/node_params.c",
            "src/parse.c",
            "src/parser.c",
            "src/yaml_variant.c",
        },
        .flags = &.{
            "-fvisibility=hidden",
        },
    });
    yaml_param_parser.linkLibrary(deps.rmw);

    yaml_param_parser.linkLibrary(deps.yaml);
    yaml_param_parser.linkLibrary(deps.rcutils);
    yaml_param_parser.installLibraryHeaders(deps.yaml);
    yaml_param_parser.installLibraryHeaders(deps.rcutils);
    b.installArtifact(yaml_param_parser);

    var rcl = b.addLibrary(.{
        .name = "rcl",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        }),
        .linkage = linkage,
    });

    rcl.addIncludePath(deps.tracetools);

    rcl.addIncludePath(upstream.path("rcl/include"));
    rcl.addIncludePath(upstream.path("rcl/src"));
    rcl.installHeadersDirectory(upstream.path("rcl/include"), "", .{});

    zigros.linkDependencyStruct(rcl, deps, .c);
    rcl.linkLibrary(yaml_param_parser);
    rcl.installLibraryHeaders(yaml_param_parser);

    rcl.addCSourceFiles(.{
        .root = upstream.path("rcl/src/rcl"),
        .files = &.{
            "arguments.c",
            "client.c",
            "common.c",
            "context.c",
            "discovery_options.c",
            "domain_id.c",
            "dynamic_message_type_support.c",
            "event.c",
            "expand_topic_name.c",
            "graph.c",
            "guard_condition.c",
            "init.c",
            "init_options.c",
            "lexer.c",
            "lexer_lookahead.c",
            "localhost.c",
            "logging.c",
            "logging_rosout.c",
            "log_level.c",
            "network_flow_endpoints.c",
            "node.c",
            "node_options.c",
            "node_resolve_name.c",
            "node_type_cache.c",
            "publisher.c",
            "remap.c",
            "rmw_implementation_identifier_check.c",
            "security.c",
            "service.c",
            "service_event_publisher.c",
            "subscription.c",
            "time.c",
            "timer.c",
            "type_description_conversions.c",
            "type_hash.c",
            "validate_enclave_name.c",
            "validate_topic_name.c",
            "wait.c",
        },
        .flags = &.{
            "-DROS_PACKAGE_NAME=\"rcl\"",
            "-fvisibility=hidden",
        },
    });
    b.installArtifact(rcl);

    var rcl_action = b.addLibrary(.{
        .name = "rcl_action",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        }),
        .linkage = linkage,
    });

    rcl_action.addIncludePath(deps.tracetools);

    rcl_action.addIncludePath(upstream.path("rcl_action/include"));
    rcl_action.addIncludePath(upstream.path("rcl_action/src"));
    rcl_action.installHeadersDirectory(upstream.path("rcl_action/include"), "", .{});
    // Private headers that shouldn't be installed
    rcl_action.installHeadersDirectory(upstream.path("rcl_action/src/rcl_action"), "", .{});

    zigros.linkDependencyStruct(rcl_action, deps, .c);
    rcl_action.linkLibrary(yaml_param_parser);
    rcl_action.linkLibrary(rcl);
    rcl_action.installLibraryHeaders(yaml_param_parser);
    rcl_action.installLibraryHeaders(rcl);

    rcl_action.addCSourceFiles(.{
        .root = upstream.path("rcl_action/src/rcl_action"),
        .files = &.{
            "action_client.c",
            "action_server.c",
            "goal_handle.c",
            "goal_state_machine.c",
            "graph.c",
            "names.c",
            "types.c",
        },
        .flags = &.{
            "-DROS_PACKAGE_NAME=\"rcl_action\"",
            "-fvisibility=hidden",
        },
    });
    b.installArtifact(rcl_action);

    var rcl_lifecycle = b.addLibrary(.{
        .name = "rcl_lifecycle",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        }),
        .linkage = linkage,
    });

    rcl_lifecycle.addIncludePath(deps.tracetools);

    rcl_lifecycle.addIncludePath(upstream.path("rcl_lifecycle/include"));
    rcl_lifecycle.addIncludePath(upstream.path("rcl_lifecycle/src"));
    rcl_lifecycle.installHeadersDirectory(upstream.path("rcl_lifecycle/include"), "", .{});

    zigros.linkDependencyStruct(rcl_lifecycle, deps, .c);
    rcl_lifecycle.linkLibrary(rcl);
    rcl_lifecycle.installLibraryHeaders(rcl);

    rcl_lifecycle.addCSourceFiles(.{
        .root = upstream.path("rcl_lifecycle/src"),
        .files = &.{
            "com_interface.c",
            "default_state_machine.c",
            "rcl_lifecycle.c",
            "transition_map.c",
        },
        .flags = &.{
            "-DROS_PACKAGE_NAME=\"rcl_lifecycle\"",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wformat=2",
            "-Wconversion",
            "-Wshadow",
            "-Wsign-conversion",
        },
    });
    b.installArtifact(rcl_lifecycle);

    return Artifacts{
        .rcl_yaml_param_parser = yaml_param_parser,
        .rcl = rcl,
        .rcl_action = rcl_action,
        .rcl_lifecycle = rcl_lifecycle,
    };
}
