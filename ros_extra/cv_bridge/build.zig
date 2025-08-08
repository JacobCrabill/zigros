const std = @import("std");
const zr = @import("zigros");
const utils = @import("../../build_utils.zig");

const Step = std.Build.Step;

pub fn getLibrary(b: *std.Build, zigros: *const zr.ZigRos, opts: utils.BuildOpts) *Step.Compile {
    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
    };

    const vision_opencv = b.dependency("vision_opencv", opts);
    const boost_config = b.dependency("boost_config", opts);
    const boost_endian = b.dependency("boost_endian", opts);

    const cv_bridge = b.addLibrary(.{
        .name = "cv_bridge",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });
    utils.writeAmentIndexFile(b, "cv_bridge");

    // This is so dumb - the CMake-generated header cv_bridge_export.h does practically nothing...
    cv_bridge.addIncludePath(b.path("ros_extra/cv_bridge/include"));

    cv_bridge.addIncludePath(vision_opencv.path("cv_bridge/include"));
    cv_bridge.addCSourceFiles(.{
        .root = vision_opencv.path("cv_bridge/src"),
        .files = &.{
            "cv_bridge.cpp",
            "cv_mat_sensor_msgs_image_type_adapter.cpp",
            "rgb_colors.cpp",
        },
        .flags = &.{ "-std=c++17", "-Wno-deprecated" },
    });
    cv_bridge.addIncludePath(boost_config.path("include"));
    cv_bridge.addIncludePath(boost_endian.path("include"));
    utils.includeOpenCv(cv_bridge, opts.target);

    zigros.linkRclcpp(cv_bridge);
    zigros.ros_libraries.std_msgs.linkC(cv_bridge);
    zigros.ros_libraries.std_msgs.linkCpp(cv_bridge);
    zigros.ros_libraries.sensor_msgs.linkC(cv_bridge);
    zigros.ros_libraries.sensor_msgs.linkCpp(cv_bridge);

    cv_bridge.installHeadersDirectory(
        vision_opencv.path("cv_bridge/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    cv_bridge.installHeader(b.path("ros_extra/cv_bridge/include/cv_bridge/cv_bridge_export.h"), "cv_bridge/cv_bridge_export.h");
    b.installArtifact(cv_bridge);

    return cv_bridge;
}
