const std = @import("std");
const zigros = @import("../../zigros/zigros.zig");

const Compile = std.Build.Step.Compile;

pub fn buildWithArgs(b: *std.Build, opts: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("rapidjson", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    // HACK: Use a .c file to have something to compile and install.
    // Zig Build doesn't really play well with header-only libraries.
    const rapidjson = b.addLibrary(.{
        .name = "rapidjson",
        .root_module = b.createModule(std_module_opts),
        .linkage = .static,
    });
    rapidjson.addIncludePath(upstream.path("include"));
    rapidjson.addCSourceFile(.{
        .file = b.path("ros_extra/rapidjson/dummy_rapidjson.cpp"),
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Werror", "-Wno-missing-field-initializers" },
    });
    rapidjson.installHeadersDirectory(upstream.path("include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });
    b.installArtifact(rapidjson);

    return rapidjson;
}
