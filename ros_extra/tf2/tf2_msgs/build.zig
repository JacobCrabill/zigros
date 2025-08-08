const std = @import("std");

const zigros = @import("../../../zigros/zigros.zig");
const utils = @import("../../../build_utils.zig");

const RosidlGenerator = @import("../../../ros_core/rosidl/src/RosidlGenerator.zig");
const RosIdlInterface = RosidlGenerator.Interface;

pub const BuildDeps = struct {
    rosidl_generator: RosidlGenerator.BuildDeps,
};

pub const Deps = struct {
    rosidl_generator: RosidlGenerator.Deps,
    action_msgs: RosIdlInterface,
    builtin_interfaces: RosIdlInterface,
    geometry_msgs: RosIdlInterface,
    service_msgs: RosIdlInterface,
    std_msgs: RosIdlInterface,
    unique_identifier_msgs: RosIdlInterface,
};

pub fn getInterface(
    b: *std.Build,
    build_deps: BuildDeps,
    deps: Deps,
    args: zigros.CompileArgs,
) RosIdlInterface {
    const upstream = b.dependency("geometry2", args);

    const Tf2MsgFiles: []const []const u8 = &.{
        "action/LookupTransform.action",
        "msg/TF2Error.msg",
        "msg/TFMessage.msg",
        "srv/FrameGraph.srv",
    };

    var tf2_msgs = RosidlGenerator.create(
        b,
        "tf2_msgs",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );
    tf2_msgs.addInterfaces(upstream.path("tf2_msgs"), Tf2MsgFiles);
    tf2_msgs.addDependency("builtin_interfaces", deps.builtin_interfaces);
    tf2_msgs.addDependency("service_msgs", deps.service_msgs);
    tf2_msgs.addDependency("std_msgs", deps.std_msgs);
    tf2_msgs.addDependency("action_msgs", deps.action_msgs);
    tf2_msgs.addDependency("geometry_msgs", deps.geometry_msgs);
    tf2_msgs.addDependency("unique_identifier_msgs", deps.unique_identifier_msgs);
    tf2_msgs.installArtifacts();

    return tf2_msgs.artifacts;
}
