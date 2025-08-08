const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");

const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const DependentLibs = struct {
    ament_index_cpp: *Compile,
    class_loader_lib: *Compile,
    tinyxml2_lib: *Compile,
};

pub fn buildWithArgs(b: *std.Build, dependencies: DependentLibs, opts: CompileArgs) *Compile {
    const upstream = b.dependency("pluginlib", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
    };

    const pluginlib = b.addLibrary(.{
        .name = "pluginlib",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });
    pluginlib.addIncludePath(upstream.path("pluginlib/include"));

    // Here we create a dummy .cpp file in order to have something to install and link
    pluginlib.addCSourceFiles(.{
        .root = b.path("ros_deps/pluginlib"),
        .files = &.{"dummy_pluginlib.cpp"},
        .flags = &.{"--std=c++17"},
    });

    pluginlib.linkLibrary(dependencies.ament_index_cpp);
    pluginlib.linkLibrary(dependencies.class_loader_lib);
    pluginlib.linkLibrary(dependencies.tinyxml2_lib);
    // zigros.linkRclcpp(pluginlib);

    // pluginlib.installLibraryHeaders(dependencies.class_loader_lib);
    // pluginlib.installLibraryHeaders(dependencies.tinyxml2_lib);
    pluginlib.installHeadersDirectory(
        upstream.path("pluginlib/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(pluginlib);

    return pluginlib;
}
