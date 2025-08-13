const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const Interface = @import("../../ros_core/rosidl/src/RosidlGenerator.zig").Interface;

const Dependency = std.Build.Dependency;
const LazyPath = std.Build.LazyPath;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    typesupport_upstream: *Dependency,
    dynamic_typesupport_upstream: *Dependency,
    fastcdr: *Compile,
    fastdds: *Compile, // needed by the dynamic typesupport
    rmw: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_dynamic_typesupport: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_runtime_cpp: LazyPath,
    // needed by dynamic typesupport...?
    // rosidl_typesupport_introspection_c: *Compile,
    // rosidl_typesupport_introspection_cpp: *Compile,
};

pub const Artifacts = struct {
    rosidl_dynamic_typesupport_fastrtps: *Compile,
    rosidl_typesupport_fastrtps_c: *Compile,
    rosidl_typesupport_fastrtps_cpp: *Compile,
    rosidl_typesupport_fastrtps_c_py: std.Build.LazyPath, // Python package dir
    rosidl_typesupport_fastrtps_cpp_py: std.Build.LazyPath, // Python package dir
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps) Artifacts {
    const linkage = args.linkage;
    const typesupport_upstream = deps.typesupport_upstream;
    const std_mod_options: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const typesupport_fastrtps_upstream = deps.typesupport_upstream;

    // -------- FastRTPS TypeSupport - C (rmw_fastrtps_cpp) --------

    var rosidl_typesupport_fastrtps_c = b.addLibrary(.{
        .name = "rosidl_typesupport_fastrtps_c",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    rosidl_typesupport_fastrtps_c.addCSourceFiles(.{
        .root = typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_c/src"),
        .files = &.{ "identifier.cpp", "wstring_conversion.cpp" },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-frtti" },
    });
    rosidl_typesupport_fastrtps_c.addIncludePath(
        typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_c/include"),
    );
    rosidl_typesupport_fastrtps_c.installHeadersDirectory(
        typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_c/include"),
        "",
        .{
            .include_extensions = &.{ ".h", ".hpp" },
        },
    );
    zigros.linkDependencyStruct(rosidl_typesupport_fastrtps_c, deps, .cpp);
    // rosidl_typesupport_fastrtps_c.linkLibrary(deps.fastcdr);
    // rosidl_typesupport_fastrtps_c.linkLibrary(deps.rmw);
    // rosidl_typesupport_fastrtps_c.linkLibrary(deps.rosidl_runtime_c);

    b.installArtifact(rosidl_typesupport_fastrtps_c);

    // -------- FastRTPS TypeSupport - C++ (rmw_fastrtps_cpp) --------

    var rosidl_typesupport_fastrtps_cpp = b.addLibrary(.{
        .name = "rosidl_typesupport_fastrtps_cpp",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
        // .linkage = .dynamic, // FastRTPS calls dlopen() on this file; it HAS to be a .so file
    });

    rosidl_typesupport_fastrtps_cpp.addCSourceFiles(.{
        .root = typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_cpp/src"),
        .files = &.{ "identifier.cpp", "wstring_conversion.cpp" },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic", "-frtti" },
    });
    rosidl_typesupport_fastrtps_cpp.addIncludePath(typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_cpp/include"));
    rosidl_typesupport_fastrtps_cpp.installHeadersDirectory(typesupport_fastrtps_upstream.path("rosidl_typesupport_fastrtps_cpp/include"), "", .{
        .include_extensions = &.{ ".h", ".hpp" },
    });
    zigros.linkDependencyStruct(rosidl_typesupport_fastrtps_cpp, deps, .cpp);

    b.installArtifact(rosidl_typesupport_fastrtps_cpp);

    // -------- FastRTPS Dynamic TypeSupport (rmw_fastrtps_dynamic_cpp) --------

    const dynamic_upstream = deps.dynamic_typesupport_upstream;

    var rosidl_dynamic_typesupport_fastrtps = b.addLibrary(.{
        .name = "rosidl_dynamic_typesupport_fastrtps",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    if (args.optimize == .ReleaseSmall and linkage == .static) {
        rosidl_dynamic_typesupport_fastrtps.link_function_sections = true;
        rosidl_dynamic_typesupport_fastrtps.link_data_sections = true;
    }

    zigros.linkDependencyStruct(rosidl_dynamic_typesupport_fastrtps, deps, .cpp);

    rosidl_dynamic_typesupport_fastrtps.addCSourceFiles(.{
        .root = dynamic_upstream.path(""),
        .files = &.{
            "src/detail/fastrtps_dynamic_data.cpp",
            "src/detail/fastrtps_dynamic_type.cpp",
            "src/detail/fastrtps_serialization_support.cpp",
            "src/detail/utils.cpp",
            "src/identifier.cpp",
            "src/serialization_support.cpp",
        },
        .flags = &.{
            "--std=c++17",
            "-frtti",
            //"-fvisibility=hidden",
        },
    });
    rosidl_dynamic_typesupport_fastrtps.addIncludePath(dynamic_upstream.path("include"));
    rosidl_dynamic_typesupport_fastrtps.installHeadersDirectory(dynamic_upstream.path("include"), "", .{});

    b.installArtifact(rosidl_dynamic_typesupport_fastrtps);

    // -------- Python ROSIDL generator libraries ---------

    const rosidl_typesupport_fastrtps_c_py = utils.exportPythonLibrary(
        b,
        "rosidl_typesupport_fastrtps_c",
        typesupport_upstream.path("rosidl_typesupport_fastrtps_c"),
        typesupport_upstream.path("rosidl_typesupport_fastrtps_c/bin"),
    );
    const rosidl_typesupport_fastrtps_cpp_py = utils.exportPythonLibrary(
        b,
        "rosidl_typesupport_fastrtps_cpp",
        typesupport_upstream.path("rosidl_typesupport_fastrtps_cpp"),
        typesupport_upstream.path("rosidl_typesupport_fastrtps_cpp/bin"),
    );

    return .{
        .rosidl_dynamic_typesupport_fastrtps = rosidl_dynamic_typesupport_fastrtps,
        .rosidl_typesupport_fastrtps_c = rosidl_typesupport_fastrtps_c,
        .rosidl_typesupport_fastrtps_cpp = rosidl_typesupport_fastrtps_cpp,
        .rosidl_typesupport_fastrtps_c_py = rosidl_typesupport_fastrtps_c_py.getDirectory(),
        .rosidl_typesupport_fastrtps_cpp_py = rosidl_typesupport_fastrtps_cpp_py.getDirectory(),
    };
}
