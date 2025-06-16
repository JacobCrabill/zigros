const std = @import("std");
const zigros = @import("../zigros/zigros.zig");

const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    console_bridge: *Compile,
    rcutils: *Compile,
    rcpputils: *Compile,
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps) *Compile {
    const upstream = b.dependency("class_loader", args);

    const class_loader = b.addModule("class_loader", .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    });

    class_loader.addIncludePath(upstream.path("include"));
    class_loader.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "class_loader.cpp",
            "class_loader_core.cpp",
            "meta_object.cpp",
            "multi_library_class_loader.cpp",
        },
        .flags = &.{ "--std=c++17", "-frtti", "-Wall", "-Werror", "-Wpedantic" },
    });

    const class_loader_lib = b.addLibrary(.{
        .name = "class_loader",
        .root_module = class_loader,
        .linkage = args.linkage,
    });
    zigros.linkDependencyStruct(class_loader_lib, deps, .cpp);
    class_loader_lib.installLibraryHeaders(deps.console_bridge);
    class_loader_lib.installHeadersDirectory(
        upstream.path("include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(class_loader_lib);

    return class_loader_lib;
}
