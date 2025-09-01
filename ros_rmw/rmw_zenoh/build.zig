const std = @import("std");
const utils = @import("../../build_utils.zig");

const zigros = @import("../../zigros/zigros.zig");
const Interface = @import("../../ros_core/rosidl/src/RosidlGenerator.zig").Interface;

const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    upstream: *Dependency,
    zenoh_cpp_dep: *Dependency,
    ament_index_cpp: *Compile,
    tracetools: LazyPath,
    rcutils: *Compile,
    fastcdr: *Compile,
    rcpputils: *Compile,
    rmw: *Compile,
    rosidl_dynamic_typesupport: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: LazyPath,
    rosidl_typesupport_fastrtps_c: *Compile,
    rosidl_typesupport_fastrtps_cpp: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_typesupport_introspection_c: *Compile,
    rosidl_typesupport_introspection_cpp: *Compile,
    zenohc_library_path: ?[]const u8,
    zenohc_include_path: ?[]const u8,
};

pub const Artifacts = struct {
    rmw_zenoh_cpp: *Compile,
    zenohd: *Compile,
    zenoh_config: LazyPath,
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

    const rmw_zenoh = b.addLibrary(.{
        .name = "rmw_zenoh_cpp",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    rmw_zenoh.addCSourceFiles(.{
        .root = upstream.path("rmw_zenoh_cpp/src"),
        .files = rmw_zenoh_srcs,
        .flags = &.{ "-DZENOHCXX_ZENOHC", "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wthread-safety", "-Wno-deprecated-declarations", "-Wno-unknown-pragmas", "-frtti" },
    });
    rmw_zenoh.addIncludePath(upstream.path("rmw_zenoh_cpp/src/detail")); // They don't use standard src/include organization
    rmw_zenoh.addIncludePath(deps.zenoh_cpp_dep.path("include"));

    rmw_zenoh.linkSystemLibrary2("zenohc", .{
        .search_strategy = .paths_first,
        .preferred_link_mode = .static,
    });
    if (deps.zenohc_include_path) |zenoch_inc| {
        rmw_zenoh.addSystemIncludePath(.{ .cwd_relative = zenoch_inc });
    }
    if (deps.zenohc_library_path) |zenoch_lib| {
        rmw_zenoh.addLibraryPath(.{ .cwd_relative = zenoch_lib });
    }

    zigros.linkDependencyStruct(rmw_zenoh, deps, .cpp);

    b.installArtifact(rmw_zenoh);

    const zenohd = b.addExecutable(.{
        .name = "zenohd",
        .root_module = b.createModule(.{
            .target = args.target,
            .optimize = args.optimize,
            .strip = args.optimize != .Debug,
        }),
    });

    zenohd.addIncludePath(upstream.path("rmw_zenoh_cpp/src/detail")); // They don't use standard src/include organization
    zenohd.addIncludePath(deps.zenoh_cpp_dep.path("include"));
    zenohd.addCSourceFiles(.{
        .root = upstream.path("rmw_zenoh_cpp/src"),
        .files = zenohd_srcs,
        .flags = &.{ "-DZENOHCXX_ZENOHC", "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-Wthread-safety", "-Wno-deprecated-declarations", "-Wno-unknown-pragmas", "-frtti" },
    });

    zenohd.linkLibrary(deps.ament_index_cpp);
    zenohd.linkLibrary(deps.rcpputils);
    zenohd.linkLibrary(deps.rcutils);
    zenohd.linkLibrary(deps.rmw);

    zenohd.linkSystemLibrary2("zenohc", .{
        .search_strategy = .paths_first,
        .preferred_link_mode = .static,
    });
    if (deps.zenohc_include_path) |zenoch_inc| {
        zenohd.addSystemIncludePath(.{ .cwd_relative = zenoch_inc });
    }
    if (deps.zenohc_library_path) |zenoch_lib| {
        zenohd.addLibraryPath(.{ .cwd_relative = zenoch_lib });
    }

    b.installArtifact(zenohd);

    // Setup Ament; add to our install environment; install the Zenoh config files
    utils.writeAmentPackageIndexFile(b, "rmw_zenoh_cpp");
    b.installDirectory(.{
        .source_dir = upstream.path("rmw_zenoh_cpp/config"),
        .install_dir = .prefix,
        .install_subdir = "share/rmw_zenoh_cpp/config",
    });
    var zenoh_config = b.addNamedWriteFiles("zenoh_config");
    _ = zenoh_config.addCopyDirectory(
        upstream.path("rmw_zenoh_cpp/config"),
        "share/rmw_zenoh_cpp/config",
        .{ .include_extensions = &.{ ".json", ".json5" } },
    );

    return .{
        .rmw_zenoh_cpp = rmw_zenoh,
        .zenohd = zenohd,
        .zenoh_config = zenoh_config.getDirectory(),
    };
}

const rmw_zenoh_srcs: []const []const u8 = &.{
    "detail/attachment_helpers.cpp",
    "detail/cdr.cpp",
    "detail/event.cpp",
    "detail/identifier.cpp",
    "detail/graph_cache.cpp",
    "detail/guard_condition.cpp",
    "detail/liveliness_utils.cpp",
    "detail/logging.cpp",
    "detail/message_type_support.cpp",
    "detail/qos.cpp",
    "detail/rmw_client_data.cpp",
    "detail/rmw_context_impl_s.cpp",
    "detail/rmw_publisher_data.cpp",
    "detail/rmw_node_data.cpp",
    "detail/rmw_service_data.cpp",
    "detail/rmw_subscription_data.cpp",
    "detail/service_type_support.cpp",
    "detail/simplified_xxhash3.cpp",
    "detail/type_support.cpp",
    "detail/type_support_common.cpp",
    "detail/zenoh_config.cpp",
    "detail/zenoh_utils.cpp",
    "rmw_event.cpp",
    "rmw_get_network_flow_endpoints.cpp",
    "rmw_get_node_info_and_types.cpp",
    "rmw_get_service_names_and_types.cpp",
    "rmw_get_topic_endpoint_info.cpp",
    "rmw_get_topic_names_and_types.cpp",
    "rmw_init_options.cpp",
    "rmw_init.cpp",
    "rmw_qos.cpp",
    "rmw_zenoh.cpp",
};

const zenohd_srcs: []const []const u8 = &.{
    "detail/liveliness_utils.cpp",
    "detail/logging.cpp",
    "detail/qos.cpp",
    "detail/simplified_xxhash3.cpp",
    "detail/zenoh_config.cpp",
    "zenohd/main.cpp",
};
