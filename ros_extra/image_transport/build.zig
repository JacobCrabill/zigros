const std = @import("std");

const zigros = @import("../../zigros/zigros.zig");
const utils = @import("../../build_utils.zig");
const RosidlGenerator = @import("../../ros_core/rosidl/src/RosidlGenerator.zig");

const Compile = std.Build.Step.Compile;

pub const Deps = struct {
    class_loader_lib: *Compile,
    message_filters_lib: *Compile,
    pluginlib_lib: *Compile,
    rclcpp: *Compile,
    rclcpp_components: *Compile,
    std_msgs: RosidlGenerator.Interface,
    sensor_msgs: RosidlGenerator.Interface,
    // TODO
    // opencv: *Compile, / opencv_include: *std.Build.LazyPath
};

pub fn buildWithArgs(
    b: *std.Build,
    deps: Deps,
    args: zigros.CompileArgs,
) *Compile {
    const upstream = b.dependency("image_common", args);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = args.target,
        .optimize = args.optimize,
        .link_libc = true,
        .link_libcpp = true,
        .pic = true,
    };

    const image_transport = b.addLibrary(.{
        .name = "image_transport",
        .root_module = b.createModule(std_module_opts),
        .linkage = args.linkage,
    });
    utils.writeAmentPackageIndexFile(b, "image_transport");

    image_transport.addIncludePath(upstream.path("image_transport/include"));
    image_transport.addCSourceFiles(.{
        .root = upstream.path("image_transport/src"),
        .files = &.{
            "camera_common.cpp",
            "publisher.cpp",
            "subscriber.cpp",
            "single_subscriber_publisher.cpp",
            "camera_publisher.cpp",
            "camera_subscriber.cpp",
            "image_transport.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Werror", "-Wpedantic", "-Wno-deprecated" },
    });
    image_transport.linkLibrary(deps.class_loader_lib);
    image_transport.linkLibrary(deps.message_filters_lib);
    image_transport.linkLibrary(deps.pluginlib_lib);
    image_transport.linkLibrary(deps.rclcpp);
    image_transport.linkLibrary(deps.rclcpp_components);
    deps.std_msgs.linkC(image_transport);
    deps.std_msgs.linkCpp(image_transport);
    deps.sensor_msgs.linkC(image_transport);
    deps.sensor_msgs.linkCpp(image_transport);

    // TODO: OpenCV
    utils.includeOpenCv(image_transport, args.target);

    image_transport.installHeadersDirectory(
        upstream.path("image_transport/include"),
        "",
        .{ .include_extensions = &.{ ".h", ".hpp" } },
    );
    b.installArtifact(image_transport);

    return image_transport;
}
