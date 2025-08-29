const std = @import("std");
const zr = @import("build.zig");

const Compile = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;
const Target = std.Build.ResolvedTarget;

/// Basic options applied to most build targets
pub const BuildOpts = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode,
    strip: bool,
    rmw: RmwKind, // = .cyclonedds,
};

/// Available ROS MiddleWare options
pub const RmwKind = enum(u8) {
    cyclonedds,
    fastrtps,
    zenoh,
};

/// Link the chosen RMW implementation
pub fn linkRmw(step: *std.Build.Step.Compile, zigros: *const zr.ZigRos, rmw: RmwKind) void {
    switch (rmw) {
        .cyclonedds => zigros.linkRmwCycloneDds(step),
        .fastrtps => zigros.linkRmwFastRtps(step),
        .zenoh => zigros.linkRmwZenoh(step),
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
        .include_extensions = extensions orelse &.{ ".launch.py", ".sh" },
    });
}

/// Create the Ament package index file to make the package a member of our AMENT_PREFIX_PATH.
pub fn writeAmentPackageIndexFile(b: *std.Build, pkg_name: []const u8) void {
    const write_files = b.addWriteFiles();
    const cache_path = write_files.add(pkg_name, "");
    const pkg_file = b.fmt("share/ament_index/resource_index/packages/{s}", .{pkg_name});
    const install_file = b.addInstallFileWithDir(cache_path, .prefix, pkg_file);
    b.getInstallStep().dependOn(&install_file.step);
}

/// Write a dummy 'package.xml' file to make Ament and ClassLoader happy.
pub fn writeAmentPackageXml(b: *std.Build, pkg_name: []const u8) void {
    const write_files = b.addWriteFiles();
    const pkg_file = b.fmt("share/{s}/package.xml", .{pkg_name});
    const content = b.fmt("<package><name>{s}</name></package>", .{pkg_name});
    const package_wf = write_files.add("package.xml", content);
    const install_file = b.addInstallFileWithDir(package_wf, .prefix, pkg_file);
    b.getInstallStep().dependOn(&install_file.step);
}

/// Write an Ament resource_index file under the given subdir
pub fn writeAmentResourceIndexFile(b: *std.Build, pkg_name: []const u8, file_name: []const u8, content: []const u8) void {
    const write_files = b.addWriteFiles();
    const resource_file = b.fmt("share/ament_index/resource_index/{s}/{s}", .{ pkg_name, file_name });
    const resource_wf = write_files.add(file_name, content);
    const install_file = b.addInstallFileWithDir(resource_wf, .prefix, resource_file);
    b.getInstallStep().dependOn(&install_file.step);
}

/// Register a package as a plugin to another package.
/// Creates the package file in the plugin directory pointing to the
/// plugin_description.xml file in the package directory.
pub fn registerPluginlibPlugin(b: *std.Build, plugin: PluginDescription) void {
    const write_files = b.addWriteFiles();

    // Create the package plugin pointer file, then install it
    const plugin_registry_path = b.fmt("share/ament_index/resource_index/{s}__pluginlib__plugin/{s}", .{ plugin.kind, plugin.name });
    const content = b.fmt("share/{s}/plugin_description.xml", .{plugin.name});
    const plugin_wf = write_files.add("plugin_description.xml", content);

    const install_plugin_file = b.addInstallFileWithDir(plugin_wf, .prefix, plugin_registry_path);
    b.getInstallStep().dependOn(&install_plugin_file.step);

    // Install the plugin_description.xml file to the package dir
    const plugin_desc_path = b.fmt("share/{s}/plugin_description.xml", .{plugin.name});
    const install_description_file = b.addInstallFileWithDir(plugin.xml, .prefix, plugin_desc_path);
    b.getInstallStep().dependOn(&install_description_file.step);
}

/// Write a 'local_setup.sh' file to the install directory.
///
/// It will export the AMENT_PREFIX_PATH, PATH, and LD_LIBRARY_PATH necessary to run installed ROS nodes,
/// assuming all libraries were installed, and all "packages" were setup with an Ament index file.
///
/// If any "extra" contents are given, they will be added to the end of the setup script.
pub fn writeLocalSetupSh(b: *std.Build, rmw: RmwKind, extra: []const u8) void {
    const local_setup_sh = b.addWriteFiles();
    const main_contents: []const u8 =
        \\#!/bin/bash
        \\export ZIGROS_INSTALL_ROOT=$(dirname $(realpath ${BASH_SOURCE[0]}))
        \\export AMENT_PREFIX_PATH=${ZIGROS_INSTALL_ROOT}
        \\export PATH=${PATH}:${ZIGROS_INSTALL_ROOT}/bin/
        \\export LD_LIBRARY_PATH=${ZIGROS_INSTALL_ROOT}/lib/
        \\export ROS_DISTRO=jazzy
        \\export ROS_LOG_DIR=${ROS_LOG_DIR:-/data/logs/ros}
    ;
    const rmw_export = switch (rmw) {
        .cyclonedds => "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp",
        .fastrtps => "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp",
        .zenoh => "export RMW_IMPLEMENTATION=rmw_zenoh_cpp",
    };
    const contents = b.fmt("{s}\n{s}\n{s}\n", .{ main_contents, rmw_export, extra });

    const local_setup_sh_path = local_setup_sh.add("local_setup.sh", contents);
    const install_local_setup_sh = b.addInstallFileWithDir(local_setup_sh_path, .prefix, "local_setup.sh");
    b.getInstallStep().dependOn(&install_local_setup_sh.step);
}

/// A description of a Pluginlib plugin
pub const PluginDescription = struct {
    /// The name of the package implementing the plugin
    name: []const u8,
    /// The name of the package defining the base plugin type
    kind: []const u8,
    /// The path to the plugin_description.xml file to be installed from the package
    xml: LazyPath,
};

/// A description of a ROS package to be installed.
pub const RosPackageOptions = struct {
    /// Name of the package.
    pkg_name: []const u8,
    /// Path to the package's root source directory (which should contain params/, launch/, etc.).
    pkg_root: ?[]const u8 = null,
    /// Destination subdirectory for the installed files (by type).
    /// If null, defaults to the package name.
    dest_subdir: ?[]const u8 = null,
    /// Whether the package's 'params' directory should be copied to the install directory.
    /// (At the subdirectory <install_root>/launch/<dest_subdir>)
    install_params: bool = false,
    /// Whether the package's 'launch' directory should be copied to the install directory.
    /// (At the subdirectory <install_root>/<dest_subdir>)
    install_launch: bool = false,
    /// A description of the Pluginlib plugin this package implements, if applicable.
    plugin: ?PluginDescription = null,
};

/// Add a ROS package to our installation environment.
///
/// This includes installing param and launch files, if requested.
/// The Ament package index file is also created.
pub fn addRosPackage(b: *std.Build, opts: RosPackageOptions) void {
    writeAmentPackageIndexFile(b, opts.pkg_name);
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
    if (opts.plugin) |plugin| {
        writeAmentPackageXml(b, plugin.name);
        registerPluginlibPlugin(b, plugin);
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

    var msg_dir = try b.build_root.handle.openDir(path, .{ .iterate = true });
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

/// Adds a named write file and install step using the given name and path.
/// Optionally include a binary directory as well.
pub fn exportPythonLibrary(
    b: *std.Build,
    name: []const u8,
    source_path: LazyPath,
    bin_path: ?LazyPath,
) *std.Build.Step.WriteFile {
    var write_file = b.addNamedWriteFiles(name);

    _ = write_file.addCopyDirectory(source_path, "", .{ .include_extensions = &.{ ".py", ".em", ".in", ".json", ".lark" } });

    if (bin_path) |bin| {
        _ = write_file.addCopyDirectory(bin, "bin", .{});
    }

    var install_step = b.addInstallDirectory(.{
        .source_dir = write_file.getDirectory(),
        .install_dir = .{ .custom = "python" },
        .install_subdir = name,
    });
    install_step.step.dependOn(&write_file.step);
    b.getInstallStep().dependOn(&install_step.step);

    return write_file;
}
