const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    std_msgs: RosidlGenerator.Interface,
};

pub fn buildWithArgs(b: *std.Build, deps: Deps, args: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("message_filters", args);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const message_filters = b.addLibrary(.{
        .name = "message_filters",
        .root_module = b.createModule(std_module_opts),
        .linkage = args.linkage,
    });
    message_filters.addIncludePath(upstream.path("include"));
    message_filters.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{"connection.cpp"},
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });
    deps.std_msgs.linkC(message_filters);
    deps.std_msgs.linkCpp(message_filters);

    message_filters.installHeadersDirectory(
        upstream.path("include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(message_filters);

    return message_filters;
}
