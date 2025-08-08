const std = @import("std");
const Build = std.Build;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Specify the default library linkage mode
    const linkage = b.option(std.builtin.LinkMode, "linkage", "static or dynamic linkage") orelse .static;

    // Upstream libfmt library source
    const upstream = b.dependency("libfmt", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    // Export the fmt module to downstream consumers
    const mod = b.addModule("fmt", .{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    mod.addIncludePath(upstream.path("include/"));
    mod.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "format.cc",
            "os.cc",
        },
        .flags = &.{
            "-std=c++17",
            "-DFMT_OS=1",
            "-Wall",
            "-Wextra",
            "-pedantic",
            "-Wconversion",
            "-Wundef",
            "-Wdeprecated",
            "-Wweak-vtables",
            "-Wshadow",
            "-Wno-gnu-zero-variadic-macro-arguments",
        },
    });
    if (linkage == .dynamic) {
        mod.addCMacro("FMT_SHARED", "1");
    }

    // Build and install the actual library
    const lib = b.addLibrary(.{
        .name = "fmt",
        .root_module = mod,
        .linkage = linkage,
    });

    lib.installHeadersDirectory(upstream.path("include"), "", .{});

    b.installArtifact(lib);
}
