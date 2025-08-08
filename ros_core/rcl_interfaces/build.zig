const std = @import("std");
const zigros = @import("../../zigros/zigros.zig");
const RosidlGenerator = @import("../rosidl/src/RosidlGenerator.zig");

const Dependency = std.Build.Dependency;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;
const CompileArgs = zigros.CompileArgs;

pub const Deps = struct {
    upstream: *Dependency,
    rosidl_generator: RosidlGenerator.Deps,
};

pub const BuildDeps = struct {
    rosidl_generator: RosidlGenerator.BuildDeps,
};

pub const Artifacts = struct {
    builtin_interfaces: RosidlGenerator.Interface,
    rosgraph_msgs: RosidlGenerator.Interface,
    service_msgs: RosidlGenerator.Interface,
    action_msgs: RosidlGenerator.Interface,
    unique_identifier_msgs: RosidlGenerator.Interface,
    type_description_interfaces: RosidlGenerator.Interface,
    statistics_msgs: RosidlGenerator.Interface,
    rcl_interfaces: RosidlGenerator.Interface,
    composition_interfaces: RosidlGenerator.Interface,
    lifecycle_msgs: RosidlGenerator.Interface,
};

pub fn buildWithArgs(b: *std.Build, args: CompileArgs, deps: Deps, build_deps: BuildDeps) Artifacts {
    const upstream = deps.upstream;

    // Built-In Interfaces
    var builtin_interfaces = RosidlGenerator.create(
        b,
        "builtin_interfaces",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    builtin_interfaces.addInterfaces(upstream.path("builtin_interfaces"), &.{
        "msg/Time.msg",
        "msg/Duration.msg",
    });

    builtin_interfaces.installArtifacts();

    // ROS Graph Messages
    var rosgraph_msgs = RosidlGenerator.create(
        b,
        "rosgraph_msgs",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    rosgraph_msgs.addInterfaces(upstream.path("rosgraph_msgs"), &.{
        "msg/Clock.msg",
    });

    rosgraph_msgs.addDependency("builtin_interfaces", builtin_interfaces.artifacts);
    rosgraph_msgs.installArtifacts();

    // Unique Identifier Message
    // This is so dumb that a single 'uint8[16] uuid' is an entirely separate repository
    var unique_identifier_msgs = RosidlGenerator.create(b, "unique_identifier_msgs", deps.rosidl_generator, build_deps.rosidl_generator, args);
    unique_identifier_msgs.addInterfaces(b.path("ros_core/rcl_interfaces/unique_identifier_msgs"), &.{"msg/UUID.msg"});
    unique_identifier_msgs.addDependency("builtin_interfaces", builtin_interfaces.artifacts);
    unique_identifier_msgs.installArtifacts();

    // Service Messages
    var service_msgs = RosidlGenerator.create(
        b,
        "service_msgs",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    service_msgs.addInterfaces(
        upstream.path("service_msgs"),
        &.{"msg/ServiceEventInfo.msg"},
    );

    service_msgs.addDependency("builtin_interfaces", builtin_interfaces.artifacts);

    service_msgs.installArtifacts();

    // Action Messages
    var action_msgs = RosidlGenerator.create(
        b,
        "action_msgs",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    action_msgs.addInterfaces(
        upstream.path("action_msgs"),
        &.{
            "msg/GoalInfo.msg",
            "msg/GoalStatus.msg",
            "msg/GoalStatusArray.msg",
            "srv/CancelGoal.srv",
        },
    );

    action_msgs.addDependency("builtin_interfaces", builtin_interfaces.artifacts);
    action_msgs.addDependency("unique_identifier_msgs", unique_identifier_msgs.artifacts);
    action_msgs.addDependency("service_msgs", service_msgs.artifacts);

    action_msgs.installArtifacts();

    // Type Description Interfaces
    var type_description_interfaces = RosidlGenerator.create(
        b,
        "type_description_interfaces",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    type_description_interfaces.addInterfaces(
        upstream.path("type_description_interfaces"),
        &.{
            "msg/Field.msg",
            "msg/FieldType.msg",
            "msg/IndividualTypeDescription.msg",
            "msg/KeyValue.msg",
            "msg/TypeDescription.msg",
            "msg/TypeSource.msg",
            "srv/GetTypeDescription.srv",
        },
    );

    type_description_interfaces.addDependency(
        "builtin_interfaces",
        builtin_interfaces.artifacts,
    );
    type_description_interfaces.addDependency("service_msgs", service_msgs.artifacts);

    type_description_interfaces.installArtifacts();

    // Statistics Messages
    var statistics_msgs = RosidlGenerator.create(
        b,
        "statistics_msgs",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    statistics_msgs.addInterfaces(
        upstream.path("statistics_msgs"),
        &.{
            "msg/MetricsMessage.msg",
            "msg/StatisticDataPoint.msg",
            "msg/StatisticDataType.msg",
        },
    );

    statistics_msgs.addDependency("builtin_interfaces", builtin_interfaces.artifacts);

    statistics_msgs.installArtifacts();

    // ROS C Library Interfaces
    var rcl_interfaces = RosidlGenerator.create(
        b,
        "rcl_interfaces",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    rcl_interfaces.addInterfaces(
        upstream.path("rcl_interfaces"),
        &.{
            "msg/FloatingPointRange.msg",
            "msg/IntegerRange.msg",
            "msg/ListParametersResult.msg",
            "msg/Log.msg",
            "msg/ParameterDescriptor.msg",
            "msg/ParameterEventDescriptors.msg",
            "msg/ParameterEvent.msg",
            "msg/Parameter.msg",
            "msg/ParameterType.msg",
            "msg/ParameterValue.msg",
            "msg/SetParametersResult.msg",
            "msg/LoggerLevel.msg",
            "msg/SetLoggerLevelsResult.msg",
            "srv/DescribeParameters.srv",
            "srv/GetParameters.srv",
            "srv/GetParameterTypes.srv",
            "srv/ListParameters.srv",
            "srv/SetParametersAtomically.srv",
            "srv/SetParameters.srv",
            "srv/GetLoggerLevels.srv",
            "srv/SetLoggerLevels.srv",
        },
    );

    rcl_interfaces.addDependency("builtin_interfaces", builtin_interfaces.artifacts);
    rcl_interfaces.addDependency("service_msgs", service_msgs.artifacts);

    rcl_interfaces.installArtifacts();

    // Composition Interfaces
    var composition_interfaces = RosidlGenerator.create(
        b,
        "composition_interfaces",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    composition_interfaces.addInterfaces(
        upstream.path("composition_interfaces"),
        &.{
            "srv/ListNodes.srv",
            "srv/LoadNode.srv",
            "srv/UnloadNode.srv",
        },
    );

    composition_interfaces.addDependency("rcl_interfaces", rcl_interfaces.artifacts);
    composition_interfaces.addDependency("builtin_interfaces", builtin_interfaces.artifacts);
    composition_interfaces.addDependency("service_msgs", service_msgs.artifacts);

    composition_interfaces.installArtifacts();

    // Lifecyle Messages
    var lifecycle_msgs = RosidlGenerator.create(
        b,
        "lifecycle_msgs",
        deps.rosidl_generator,
        build_deps.rosidl_generator,
        args,
    );

    lifecycle_msgs.addInterfaces(
        upstream.path("lifecycle_msgs"),
        &.{
            "msg/State.msg",
            "msg/Transition.msg",
            "msg/TransitionDescription.msg",
            "msg/TransitionEvent.msg",
            "srv/ChangeState.srv",
            "srv/GetAvailableStates.srv",
            "srv/GetAvailableTransitions.srv",
            "srv/GetState.srv",
        },
    );

    lifecycle_msgs.addDependency("builtin_interfaces", builtin_interfaces.artifacts);
    lifecycle_msgs.addDependency("service_msgs", service_msgs.artifacts);

    lifecycle_msgs.installArtifacts();

    return Artifacts{
        .builtin_interfaces = builtin_interfaces.artifacts,
        .rosgraph_msgs = rosgraph_msgs.artifacts,
        .action_msgs = action_msgs.artifacts,
        .service_msgs = service_msgs.artifacts,
        .unique_identifier_msgs = unique_identifier_msgs.artifacts,
        .type_description_interfaces = type_description_interfaces.artifacts,
        .statistics_msgs = statistics_msgs.artifacts,
        .rcl_interfaces = rcl_interfaces.artifacts,
        .composition_interfaces = composition_interfaces.artifacts,
        .lifecycle_msgs = lifecycle_msgs.artifacts,
    };
}
