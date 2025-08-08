const std = @import("std");
const utils = @import("../../build_utils.zig");

const Step = std.Build.Step;

pub const GTestLibs = struct {
    gtest: *std.Build.Step.Compile,
    gtest_main: *std.Build.Step.Compile,
};

pub fn getLibraries(b: *std.Build, opts: utils.BuildOpts) GTestLibs {
    const gtest = b.dependency("gtest", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
    };

    // GTest Library
    const gtest_all = b.addModule("gtest", std_module_opts);
    gtest_all.addIncludePath(gtest.path("googletest"));
    gtest_all.addIncludePath(gtest.path("googletest/include"));
    gtest_all.addCSourceFiles(.{
        .root = gtest.path("googletest/src"),
        .files = &.{"gtest-all.cc"},
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });
    const gtest_lib = b.addLibrary(.{
        .name = "gtest",
        .root_module = gtest_all,
        .linkage = .static,
    });
    gtest_lib.installHeadersDirectory(gtest.path("googletest/include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });
    b.installArtifact(gtest_lib);

    // GTest Main Library
    const gtest_main = b.addModule("gtest", std_module_opts);
    gtest_main.addIncludePath(gtest.path("googletest"));
    gtest_main.addIncludePath(gtest.path("googletest/include"));
    gtest_main.addCSourceFiles(.{
        .root = gtest.path("googletest/src"),
        .files = &.{"gtest_main.cc"},
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Wpedantic" },
    });
    const gtest_main_lib = b.addLibrary(.{
        .name = "gtest_main",
        .root_module = gtest_main,
        .linkage = .static,
    });
    b.installArtifact(gtest_main_lib);

    return .{ .gtest = gtest_lib, .gtest_main = gtest_main_lib };
}
