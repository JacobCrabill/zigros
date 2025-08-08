const std = @import("std");
const zr = @import("zigros");

const Compile = std.Build.Step.Compile;
const Target = std.Build.ResolvedTarget;

/// Basic options applied to most build targets
pub const BuildOpts = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode,
    rmw: RmwKind, // = .cyclonedds,
};

/// Available ROS MiddleWare options
pub const RmwKind = enum(u8) {
    cyclonedds,
    fastrtps,
};

/// Link the chosen RMW implementation
pub fn linkRmw(step: *std.Build.Step.Compile, zigros: *const zr.ZigRos, rmw: RmwKind) void {
    switch (rmw) {
        .cyclonedds => zigros.linkRmwCycloneDds(step),
        .fastrtps => zigros.linkRmwFastRtps(step),
    }
}

/// Install paramter files for a package.
///
/// Copy all files from the given parameters directory <params_src_dir>
/// to the install folder at the location 'params/<params_dest_subdir>'.
/// If no extensions are given, defaults to '*.yaml'.
pub fn installParameterFiles(
    b: *std.Build,
    params_src_dir: []const u8,
    params_dest_subdir: []const u8,
    extensions: ?[]const []const u8,
) void {
    b.installDirectory(.{
        .source_dir = b.path(params_src_dir),
        .install_dir = .prefix,
        .install_subdir = b.fmt("params/{s}", .{params_dest_subdir}),
        .include_extensions = extensions orelse &.{".yaml"},
    });
}

/// Install launch files for a package.
///
/// Copy all files from the given launch directory <launch_src_dir>
/// to the install folder at the location 'launch/<params_dest_subdir>'.
/// If no extensions are given, defaults to '*.launch.py'.
pub fn installLaunchFiles(
    b: *std.Build,
    launch_src_dir: []const u8,
    launch_dest_subdir: []const u8,
    extensions: ?[]const []const u8,
) void {
    b.installDirectory(.{
        .source_dir = b.path(launch_src_dir),
        .install_dir = .prefix,
        .install_subdir = b.fmt("launch/{s}", .{launch_dest_subdir}),
        .include_extensions = extensions orelse &.{".launch.py"},
    });
}

/// Create the Ament package index file to make the package a member of our AMENT_PREFIX_PATH.
pub fn writeAmentIndexFile(b: *std.Build, pkg_name: []const u8) void {
    const write_files = b.addWriteFiles();
    const cache_path = write_files.add(pkg_name, "");
    const pkg_file = b.fmt("share/ament_index/resource_index/packages/{s}", .{pkg_name});
    const install_file = b.addInstallFileWithDir(cache_path, .prefix, pkg_file);
    b.getInstallStep().dependOn(&install_file.step);
}

pub const RosPackageOptions = struct {
    /// Name of the package
    pkg_name: []const u8,
    /// Path to the package's root source directory (which should contain params/, launch/, etc.)
    pkg_root: ?[]const u8 = null,
    /// Destination subdirectory for the installed files (by type). Default
    /// If null, defaults to the package name.
    dest_subdir: ?[]const u8 = null,
    /// Whether the params directory should be copied to the install directory
    /// (At the subdirectory <install_root>/launch/<dest_subdir>)
    install_params: bool = false,
    /// Whether the launch directory should be copied to the install directory
    /// (At the subdirectory <install_root>/dest_subdir)
    install_launch: bool = false,
};

/// Add a ROS package to our installation environment.
///
/// This includes installing param and launch files, if requested.
/// The Ament package index file is also created.
pub fn addRosPackage(b: *std.Build, opts: RosPackageOptions) void {
    writeAmentIndexFile(b, opts.pkg_name);
    if (opts.install_params) {
        const src_dir = b.fmt("{s}/params", .{opts.pkg_root.?});
        const dest_subdir = opts.dest_subdir orelse opts.pkg_name;
        installParameterFiles(b, src_dir, dest_subdir, null);
    }
    if (opts.install_launch) {
        const src_dir = b.fmt("{s}/launch", .{opts.pkg_root.?});
        const dest_subdir = opts.dest_subdir orelse opts.pkg_name;
        installLaunchFiles(b, src_dir, dest_subdir, null);
    }
}

/// Configure the basic install and run rules for a unit test executable.
///
/// In particular, adds the test to be run as part of the "test" step, and
/// sets the AMENT_PREFIX_PATH environment variable so that your test may use
/// ament APIs such as ament_index_cpp::get_package_prefix("foo");
///
/// If you need custom setup of your test (such as custom runtime arguments),
/// copy-paste the contents of this function and adjust as needed.
pub fn setupUnitTest(b: *std.Build, run_tests_step: *std.Build.Step, test_exe: *std.Build.Step.Compile) void {
    const test_exe_install = b.addInstallArtifact(test_exe, .{
        .dest_dir = .{ .override = .{ .custom = "test" } },
    });
    b.getInstallStep().dependOn(&test_exe_install.step);

    // Create the run step for the test and add it to the top-level 'test' step
    // Set the AMENT_PREFIX_PATH env var so it can find the installed paramter files
    const run_test_exe = b.addRunArtifact(test_exe);
    run_test_exe.setEnvironmentVariable("AMENT_PREFIX_PATH", b.install_path);
    run_tests_step.dependOn(&run_test_exe.step);
}

/// Iterate a directory containing msg/, srv/, action/ and return all ROS message files
pub fn iterateMessages(b: *std.Build, path: []const u8) ![]const []const u8 {
    var msgs = std.ArrayList([]const u8).init(b.allocator);

    var msg_dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer msg_dir.close();

    var msg_dir_iter = msg_dir.iterate();
    while (try msg_dir_iter.next()) |msg_subdir| {
        if (msg_subdir.kind == .directory) {
            var dir = try msg_dir.openDir(msg_subdir.name, .{ .iterate = true });
            defer dir.close();

            var iter = dir.iterate();
            while (try iter.next()) |entry| {
                if (entry.kind == .file) {
                    const extension = std.fs.path.extension(entry.name);
                    const is_msg = std.mem.eql(u8, ".msg", extension);
                    const is_srv = std.mem.eql(u8, ".srv", extension);
                    const is_action = std.mem.eql(u8, ".action", extension);
                    if (is_msg or is_srv or is_action) {
                        // Have to duplicate the filename b/c the iterator owns it
                        try msgs.append(try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ msg_subdir.name, entry.name }));
                    }
                }
            }
        }
    }

    return try msgs.toOwnedSlice();
}
