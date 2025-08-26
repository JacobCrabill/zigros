const std = @import("std");
const utils = @import("../build_utils.zig");

const zig_ros = @import("zigros");
const ZigRos = zig_ros.ZigRos;

pub const BuildOpts = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode,
    strip: bool,
};

const RosIdlInterface = zig_ros.RosidlGenerator.Interface;

pub const Interfaces = struct {
    geographic_msgs: RosIdlInterface,
    mavros_msgs: RosIdlInterface,
    // unique_identifier_msgs: RosIdlInterface,
};

pub fn getInterfaces(b: *std.Build, zigros: *const ZigRos, opts: BuildOpts) Interfaces {
    const std_dep_args = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .linkage = opts.linkage,
        .strip = opts.strip,
    };

    const geographic = b.dependency("geographic_info", std_dep_args);
    const mavros = b.dependency("mavros", std_dep_args);

    //////////////////////////////////////////////////////////////////////////////////////
    // Custom ROS Interfaces
    //////////////////////////////////////////////////////////////////////////////////////
    const msg_compile_args: ZigRos.CompileArgs = .{ .target = opts.target, .optimize = opts.optimize, .linkage = opts.linkage };

    // // unique_identifier_msgs
    // var unique_identifier_msgs = zigros.createInterface(b, "unique_identifier_msgs", msg_compile_args);
    // const unique_identifier_msgs_msgs = utils.iterateMessages(b, "interfaces/unique_identifier_msgs") catch unreachable;
    // unique_identifier_msgs.addInterfaces(b.path("interfaces/unique_identifier_msgs"), unique_identifier_msgs_msgs);
    // unique_identifier_msgs.addDependency("builtin_interfaces", zigros.ros_libraries.builtin_interfaces);
    // unique_identifier_msgs.installArtifacts();

    // geographic_msgs
    var geographic_msgs = zigros.createInterface(b, "geographic_msgs", msg_compile_args);
    geographic_msgs.addInterfaces(geographic.path("geographic_msgs"), GeographicMsgFiles);
    geographic_msgs.addDependency("builtin_interfaces", zigros.ros_libraries.builtin_interfaces);
    geographic_msgs.addDependency("service_msgs", zigros.ros_libraries.service_msgs);
    geographic_msgs.addDependency("std_msgs", zigros.ros_libraries.std_msgs);
    geographic_msgs.addDependency("geometry_msgs", zigros.ros_libraries.geometry_msgs);
    // geographic_msgs.addDependency("unique_identifier_msgs", unique_identifier_msgs.artifacts);
    geographic_msgs.addDependency("unique_identifier_msgs", zigros.ros_libraries.unique_identifier_msgs);
    geographic_msgs.installArtifacts();

    // mavros_msgs
    var mavros_msgs = zigros.createInterface(b, "mavros_msgs", msg_compile_args);
    mavros_msgs.addInterfaces(mavros.path("mavros_msgs"), MavrosMsgFiles);
    mavros_msgs.addDependency("builtin_interfaces", zigros.ros_libraries.builtin_interfaces);
    mavros_msgs.addDependency("rcl_interfaces", zigros.ros_libraries.rcl_interfaces);
    mavros_msgs.addDependency("service_msgs", zigros.ros_libraries.service_msgs);
    mavros_msgs.addDependency("std_msgs", zigros.ros_libraries.std_msgs);
    mavros_msgs.addDependency("geometry_msgs", zigros.ros_libraries.geometry_msgs);
    mavros_msgs.addDependency("geographic_msgs", geographic_msgs.artifacts);
    mavros_msgs.installArtifacts();

    return .{
        .geographic_msgs = geographic_msgs.artifacts,
        .mavros_msgs = mavros_msgs.artifacts,
        // .unique_identifier_msgs = unique_identifier_msgs.artifacts,
    };
}

const GeographicMsgFiles: []const []const u8 = &.{
    "msg/BoundingBox.msg",
    "msg/GeoPath.msg",
    "msg/GeoPoint.msg",
    "msg/GeoPointStamped.msg",
    "msg/GeoPose.msg",
    "msg/GeoPoseStamped.msg",
    "msg/GeoPoseWithCovariance.msg",
    "msg/GeoPoseWithCovarianceStamped.msg",
    "msg/GeographicMap.msg",
    "msg/GeographicMapChanges.msg",
    "msg/KeyValue.msg",
    "msg/MapFeature.msg",
    "msg/RouteNetwork.msg",
    "msg/RoutePath.msg",
    "msg/RouteSegment.msg",
    "msg/WayPoint.msg",
    "srv/GetGeoPath.srv",
    "srv/GetGeographicMap.srv",
    "srv/GetRoutePlan.srv",
    "srv/UpdateGeographicMap.srv",
};

const MavrosMsgFiles: []const []const u8 = &.{
    "msg/ADSBVehicle.msg",
    "msg/ActuatorControl.msg",
    "msg/Altitude.msg",
    "msg/AttitudeTarget.msg",
    "msg/CamIMUStamp.msg",
    "msg/CameraImageCaptured.msg",
    "msg/CellularStatus.msg",
    "msg/CommandCode.msg",
    "msg/CompanionProcessStatus.msg",
    "msg/DebugValue.msg",
    "msg/ESCInfo.msg",
    "msg/ESCInfoItem.msg",
    "msg/ESCStatus.msg",
    "msg/ESCStatusItem.msg",
    "msg/ESCTelemetry.msg",
    "msg/ESCTelemetryItem.msg",
    "msg/EstimatorStatus.msg",
    "msg/ExtendedState.msg",
    "msg/FileEntry.msg",
    "msg/GPSINPUT.msg",
    "msg/GPSRAW.msg",
    "msg/GPSRTK.msg",
    "msg/GimbalDeviceAttitudeStatus.msg",
    "msg/GimbalDeviceInformation.msg",
    "msg/GimbalDeviceSetAttitude.msg",
    "msg/GimbalManagerInformation.msg",
    "msg/GimbalManagerSetAttitude.msg",
    "msg/GimbalManagerSetPitchyaw.msg",
    "msg/GimbalManagerStatus.msg",
    "msg/GlobalPositionTarget.msg",
    "msg/HilActuatorControls.msg",
    "msg/HilControls.msg",
    "msg/HilGPS.msg",
    "msg/HilSensor.msg",
    "msg/HilStateQuaternion.msg",
    "msg/HomePosition.msg",
    "msg/LandingTarget.msg",
    "msg/LogData.msg",
    "msg/LogEntry.msg",
    "msg/MagnetometerReporter.msg",
    "msg/ManualControl.msg",
    "msg/Mavlink.msg",
    "msg/MountControl.msg",
    "msg/NavControllerOutput.msg",
    "msg/OnboardComputerStatus.msg",
    "msg/OpticalFlow.msg",
    "msg/OpticalFlowRad.msg",
    "msg/OverrideRCIn.msg",
    "msg/Param.msg",
    "msg/ParamEvent.msg",
    "msg/ParamValue.msg",
    "msg/PlayTuneV2.msg",
    "msg/PositionTarget.msg",
    "msg/RCIn.msg",
    "msg/RCOut.msg",
    "msg/RTCM.msg",
    "msg/RTKBaseline.msg",
    "msg/RadioStatus.msg",
    "msg/State.msg",
    "msg/StatusEvent.msg",
    "msg/StatusText.msg",
    "msg/SysStatus.msg",
    "msg/TerrainReport.msg",
    "msg/Thrust.msg",
    "msg/TimesyncStatus.msg",
    "msg/Trajectory.msg",
    "msg/Tunnel.msg",
    "msg/VehicleInfo.msg",
    "msg/VfrHud.msg",
    "msg/Vibration.msg",
    "msg/Waypoint.msg",
    "msg/WaypointList.msg",
    "msg/WaypointReached.msg",
    "msg/WheelOdomStamped.msg",
    "srv/CommandAck.srv",
    "srv/CommandBool.srv",
    "srv/CommandHome.srv",
    "srv/CommandInt.srv",
    "srv/CommandLong.srv",
    "srv/CommandTOL.srv",
    "srv/CommandTOLLocal.srv",
    "srv/CommandTriggerControl.srv",
    "srv/CommandTriggerInterval.srv",
    "srv/CommandVtolTransition.srv",
    "srv/EndpointAdd.srv",
    "srv/EndpointDel.srv",
    "srv/FileChecksum.srv",
    "srv/FileClose.srv",
    "srv/FileList.srv",
    "srv/FileMakeDir.srv",
    "srv/FileOpen.srv",
    "srv/FileRead.srv",
    "srv/FileRemove.srv",
    "srv/FileRemoveDir.srv",
    "srv/FileRename.srv",
    "srv/FileTruncate.srv",
    "srv/FileWrite.srv",
    "srv/GimbalGetInformation.srv",
    "srv/GimbalManagerCameraTrack.srv",
    "srv/GimbalManagerConfigure.srv",
    "srv/GimbalManagerPitchyaw.srv",
    "srv/GimbalManagerSetRoi.srv",
    "srv/LogRequestData.srv",
    "srv/LogRequestEnd.srv",
    "srv/LogRequestList.srv",
    "srv/MessageInterval.srv",
    "srv/MountConfigure.srv",
    "srv/ParamGet.srv",
    "srv/ParamPull.srv",
    "srv/ParamPush.srv",
    "srv/ParamSet.srv",
    "srv/ParamSetV2.srv",
    "srv/SetMavFrame.srv",
    "srv/SetMode.srv",
    "srv/StreamRate.srv",
    "srv/VehicleInfoGet.srv",
    "srv/WaypointClear.srv",
    "srv/WaypointPull.srv",
    "srv/WaypointPush.srv",
    "srv/WaypointSetCurrent.srv",
};
