const std = @import("std");
const zigros = @import("zigros/zigros.zig");

const ament_index = @import("ros_deps/ament_index/build.zig");
const geographic = @import("ros_deps/geographic/build.zig");
const pluginlib = @import("ros_deps/pluginlib/build.zig");
const tinyxml2 = @import("ros_deps/tinyxml2/build.zig");

const libstatistics_collector = @import("ros_core/libstatistics_collector/build.zig");
const rcl = @import("ros_core/rcl/build.zig");
const rcl_logging = @import("ros_core/rcl_logging/build.zig");
const rcl_interfaces = @import("ros_core/rcl_interfaces/build.zig");
const rclcpp = @import("ros_core/rclcpp/build.zig");
const rcpputils = @import("ros_core/rcpputils/build.zig");
const rcutils = @import("ros_core/rcutils/build.zig");
const ros2_tracing = @import("ros_core/ros2_tracing/build.zig");
const rosidl = @import("ros_core/rosidl/build.zig");

const rmw = @import("ros_rmw/rmw/build.zig");
const rmw_dds_common = @import("ros_rmw/rmw_dds_common/build.zig");
const rmw_cyclonedds = @import("ros_rmw/rmw_cyclonedds/build.zig");
const rmw_fastrtps = @import("ros_rmw/rmw_fastrtps/build.zig");
const rmw_zenoh = @import("ros_rmw/rmw_zenoh/build.zig");
// const rmw_uxrce = @import("ros_rmw/rmw_microxrcedds/build.zig");
const typesupport_fastrtps = @import("ros_rmw/typesupport_fastrtps//build.zig");

// Additional, proxy RMW wrapper
const rmw_impl = @import("ros_rmw/rmw_implementation/build.zig");

const class_loader = @import("ros_deps/class_loader/build.zig");
const console_bridge = @import("ros_deps/console_bridge/build.zig");
const camera_info = @import("ros_extra/camera_info_manager/build.zig");
const common_interfaces = @import("interfaces/common_interfaces/build.zig");
const dynmsg = @import("ros_extra/dynmsg/build.zig");
// const image_transport = @import("ros_extra/image_transport/build.zig");
const message_filters = @import("ros_extra/message_filters/build.zig");
const tf2 = @import("ros_extra/tf2/build.zig");
const zstd = @import("ros_extra/zstd/build.zig");
const rapidjson = @import("ros_extra/rapidjson/build.zig");
const rosbag2 = @import("ros_extra/rosbag2/build.zig");
const rosx_introspection = @import("ros_extra/rosx_introspection/build.zig");

pub const RosidlGenerator = @import("ros_core/rosidl/src/RosidlGenerator.zig");

pub const utils = @import("build_utils.zig");

const LazyPath = std.Build.LazyPath;
const Dependency = std.Build.Dependency;
const Compile = std.Build.Step.Compile;
const Module = std.Build.Module;
const WriteFile = std.Build.Step.WriteFile;

const UpstreamDependencies = struct {
    eigen: *Dependency,
    rcutils: *Dependency,
    rcpputils: *Dependency,
    rosidl: *Dependency,
    rosidl_typesupport: *Dependency,
    rosidl_dynamic_typesupport: *Dependency,
    rosidl_dynamic_typesupport_fastrtps: *Dependency,
    rosidl_typesupport_fastrtps: *Dependency,
    rmw: *Dependency,
    rmw_dds_common: *Dependency,
    rcl_logging: *Dependency,
    spdlog: *Dependency,
    rcl_interfaces: *Dependency,
    common_interfaces: *Dependency,
    ros2_tracing: *Dependency,
    rcl: *Dependency,
    rmw_cyclonedds: *Dependency,
    rmw_fastrtps: *Dependency,
    rmw_zenoh: *Dependency,
    // rmw_uxrce: *Dependency,
    libstatistics_collector: *Dependency,
    ament_index: *Dependency,
    rclcpp: *Dependency,
};

pub const RosLibraries = struct {
    rcutils: *Compile,
    rcpputils: *Compile,
    rosidl_typesupport_interface: LazyPath,
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: LazyPath,
    rosidl_typesupport_introspection_c: *Compile,
    rosidl_typesupport_introspection_cpp: *Compile,
    rosidl_typesupport_c: *Compile,
    rosidl_typesupport_cpp: *Compile,
    rosidl_dynamic_typesupport: *Compile,
    rosidl_dynamic_typesupport_fastrtps: *Compile,
    rosidl_typesupport_fastrtps_c: *Compile,
    rosidl_typesupport_fastrtps_cpp: *Compile,
    // rosidl_typesupport_microxrcedds_c: *Compile,
    // rosidl_typesupport_microxrcedds_cpp: *Compile,
    rmw: *Compile,
    rmw_dds_common: *Compile,
    rmw_dds_common_interface: RosidlGenerator.Interface,
    rcl_logging_interface: *Compile,
    rcl_logging_spdlog: *Compile,
    builtin_interfaces: RosidlGenerator.Interface,
    rosgraph_msgs: RosidlGenerator.Interface,
    action_msgs: RosidlGenerator.Interface,
    service_msgs: RosidlGenerator.Interface,
    unique_identifier_msgs: RosidlGenerator.Interface,
    type_description_interfaces: RosidlGenerator.Interface,
    statistics_msgs: RosidlGenerator.Interface,
    rcl_interfaces: RosidlGenerator.Interface,
    composition_interfaces: RosidlGenerator.Interface,
    lifecycle_msgs: RosidlGenerator.Interface,
    tracetools: LazyPath,
    rcl_yaml_param_parser: *Compile,
    yaml: *Compile, // External
    yaml_cpp: *Compile, // External
    geographic: *Compile,
    pluginlib: *Compile,
    tinyxml2: *Compile,
    camera_calibration_parsers: *Compile,
    camera_info_manager: *Compile,
    class_loader: *Compile,
    console_bridge: *Compile,
    dynmsg: *Compile,
    // image_transport: *Compile,
    message_filters: *Compile,
    tf2: *Compile,
    tf2_msgs: RosidlGenerator.Interface,
    tf2_ros: *Compile,
    tf2_eigen: *Compile,
    rcl: *Compile,
    rcl_action: *Compile,
    rcl_lifecycle: *Compile,
    rmw_cyclonedds_cpp: *Compile,
    rmw_fastrtps_cpp: *Compile,
    // rmw_fastrtps_dynamic_cpp: *Compile,
    rmw_fastrtps_shared_cpp: *Compile,
    rmw_zenoh_cpp: *Compile,
    // rmw_uxrce: *Compile,
    // microcdr: *Compile, // External
    // uxrce_client: *Compile, // External
    cyclonedds: *Compile,
    fastdds: *Compile,
    fastcdr: *Compile,
    libstatistics_collector: *Compile,
    ament_index_cpp: *Compile,
    rclcpp: *Compile,
    rclcpp_action: *Compile,
    rclcpp_components: *Compile,
    rclcpp_lifecycle: *Compile,
    // common_interfaces:
    actionlib_msgs: RosidlGenerator.Interface,
    diagnostic_msgs: RosidlGenerator.Interface,
    geometry_msgs: RosidlGenerator.Interface,
    nav_msgs: RosidlGenerator.Interface,
    sensor_msgs: RosidlGenerator.Interface,
    shape_msgs: RosidlGenerator.Interface,
    std_msgs: RosidlGenerator.Interface,
    std_srvs: RosidlGenerator.Interface,
    stereo_msgs: RosidlGenerator.Interface,
    trajectory_msgs: RosidlGenerator.Interface,
    visualization_msgs: RosidlGenerator.Interface,
};

pub const PythonLibraries = struct {
    empy: ?LazyPath,
    lark: ?LazyPath,
    rcutils: LazyPath,
    rosidl_adapter: LazyPath,
    rosidl_cli: LazyPath,
    rosidl_pycommon: LazyPath,
    rosidl_generator_c: LazyPath,
    rosidl_generator_cpp: LazyPath,
    rosidl_generator_type_description: LazyPath,
    rosidl_parser: LazyPath,
    rosidl_typesupport_introspection_c: LazyPath,
    rosidl_typesupport_introspection_cpp: LazyPath,
    rosidl_typesupport_c: LazyPath,
    rosidl_typesupport_cpp: LazyPath,
    // RMW-specific typesupport generator libraries.
    // These are extensions normally registered via CMake via Ament to generate
    // additional, RMW-specific typesupport libraries.
    rosidl_typesupport_fastrtps_c: LazyPath,
    rosidl_typesupport_fastrtps_cpp: LazyPath,
};

//  Extracts the expected artifacts given a package name
fn extractInterface(dep: *std.Build.Dependency, name: []const u8) RosidlGenerator.Interface {
    var buf: [256]u8 = undefined;
    return RosidlGenerator.Interface{
        .share = dep.namedWriteFiles(name).getDirectory(),
        .include_dir = dep.builder.named_lazy_paths.get(name),
        .interface_c = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_generator_c",
            .{name},
        ) catch @panic("Buffer too small")),
        .interface_cpp = dep.namedWriteFiles(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_generator_cpp",
            .{name},
        ) catch @panic("Buffer too small")).getDirectory(),
        .typesupport_c = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_typesupport_c",
            .{name},
        ) catch @panic("Buffer too small")),
        .typesupport_cpp = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_typesupport_cpp",
            .{name},
        ) catch @panic("Buffer too small")),
        .typesupport_introspection_c = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_typesupport_introspection_c",
            .{name},
        ) catch @panic("Buffer too small")),
        .typesupport_introspection_cpp = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_typesupport_introspection_cpp",
            .{name},
        ) catch @panic("Buffer too small")),
        .typesupport_fastrtps_c = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_typesupport_fastrtps_c",
            .{name},
        ) catch @panic("Buffer too small")),
        .typesupport_fastrtps_cpp = dep.artifact(std.fmt.bufPrint(
            &buf,
            "{s}__rosidl_typesupport_fastrtps_cpp",
            .{name},
        ) catch @panic("Buffer too small")),
    };
}

// The build/configure step sets this if its missing lazy deps which allows the ZigRos init call to return null if it's not set
var lazy_deps_needed = false;

pub const ZigRos = struct {
    pub const CompileArgs = zigros.CompileArgs;

    ros_libraries: RosLibraries,
    python_libraries: PythonLibraries,
    python: zigros.PythonDep,
    type_description_generator: *Compile,
    adapter_generator: *Compile,
    code_generator: *Compile,

    // Will return null if lazy_deps_needed is set
    pub fn init(dep: *std.Build.Dependency) ?ZigRos {
        if (lazy_deps_needed) return null;
        const system_python = if (dep.builder.user_input_options.get(system_python_arg_name)) |option| switch (option.value) {
            .flag => true,
            .scalar => |s| std.mem.eql(u8, s, "true"),
            else => system_python_default,
        } else system_python_default;

        return ZigRos{
            .ros_libraries = .{
                .rcutils = dep.artifact("rcutils"),
                .rcpputils = dep.artifact("rcpputils"),
                .rosidl_typesupport_interface = dep.namedWriteFiles(
                    "rosidl_typesupport_interface",
                ).getDirectory(),
                .rosidl_runtime_c = dep.artifact("rosidl_runtime_c"),
                .rosidl_runtime_cpp = dep.namedWriteFiles("rosidl_runtime_cpp").getDirectory(),
                .rosidl_typesupport_c = dep.artifact("rosidl_typesupport_c"),
                .rosidl_typesupport_cpp = dep.artifact("rosidl_typesupport_cpp"),
                .rosidl_typesupport_introspection_c = dep.artifact(
                    "rosidl_typesupport_introspection_c",
                ),
                .rosidl_typesupport_introspection_cpp = dep.artifact(
                    "rosidl_typesupport_introspection_cpp",
                ),
                .rosidl_dynamic_typesupport = dep.artifact("rosidl_dynamic_typesupport"),
                .rosidl_dynamic_typesupport_fastrtps = dep.artifact("rosidl_dynamic_typesupport_fastrtps"),
                .rosidl_typesupport_fastrtps_c = dep.artifact("rosidl_typesupport_fastrtps_c"),
                .rosidl_typesupport_fastrtps_cpp = dep.artifact("rosidl_typesupport_fastrtps_cpp"),
                // .rosidl_typesupport_microxrcedds_c = dep.artifact("rosidl_typesupport_microxrcedds_c"),
                // .rosidl_typesupport_microxrcedds_cpp = dep.artifact("rosidl_typesupport_microxrcedds_cpp"),
                .rmw = dep.artifact("rmw"),
                .rmw_dds_common = dep.artifact("rmw_dds_common"),
                .rmw_dds_common_interface = extractInterface(dep, "rmw_dds_common"),
                .rcl_logging_interface = dep.artifact("rcl_logging_interface"),
                .rcl_logging_spdlog = dep.artifact("rcl_logging_spdlog"),
                .builtin_interfaces = extractInterface(dep, "builtin_interfaces"),
                .rosgraph_msgs = extractInterface(dep, "rosgraph_msgs"),
                .action_msgs = extractInterface(dep, "action_msgs"),
                .service_msgs = extractInterface(dep, "service_msgs"),
                .unique_identifier_msgs = extractInterface(dep, "unique_identifier_msgs"),
                .type_description_interfaces = extractInterface(dep, "type_description_interfaces"),
                .statistics_msgs = extractInterface(dep, "statistics_msgs"),
                .rcl_interfaces = extractInterface(dep, "rcl_interfaces"),
                .composition_interfaces = extractInterface(dep, "composition_interfaces"),
                .lifecycle_msgs = extractInterface(dep, "lifecycle_msgs"),
                .tracetools = dep.namedWriteFiles("tracetools").getDirectory(),
                .rcl_yaml_param_parser = dep.artifact("rcl_yaml_param_parser"),
                .yaml = dep.artifact("yaml"), // External
                .yaml_cpp = dep.artifact("yaml-cpp"), // External
                .camera_calibration_parsers = dep.artifact("camera_calibration_parsers"),
                .camera_info_manager = dep.artifact("camera_info_manager"),
                .class_loader = dep.artifact("class_loader"),
                .console_bridge = dep.artifact("console_bridge"),
                .dynmsg = dep.artifact("dynmsg"),
                .geographic = dep.artifact("geographic"),
                .message_filters = dep.artifact("message_filters"),
                .pluginlib = dep.artifact("pluginlib"),
                .tf2 = dep.artifact("tf2"),
                .tf2_eigen = dep.artifact("tf2_eigen"),
                .tf2_msgs = extractInterface(dep, "tf2_msgs"),
                .tf2_ros = dep.artifact("tf2_ros"),
                .tinyxml2 = dep.artifact("tinyxml2"),
                .rcl = dep.artifact("rcl"),
                .rcl_action = dep.artifact("rcl_action"),
                .rcl_lifecycle = dep.artifact("rcl_lifecycle"),
                .rmw_cyclonedds_cpp = dep.artifact("rmw_cyclonedds_cpp"),
                .rmw_fastrtps_cpp = dep.artifact("rmw_fastrtps_cpp"),
                // .rmw_fastrtps_dynamic_cpp = dep.artifact("rmw_fastrtps_dynamic_cpp"),
                .rmw_fastrtps_shared_cpp = dep.artifact("rmw_fastrtps_shared_cpp"),
                .rmw_zenoh_cpp = dep.artifact("rmw_zenoh_cpp"),
                // .rmw_uxrce = dep.artifact("rmw_uxrce"),
                // .microcdr = dep.artifact("microcdr"),
                // .uxrce_client = dep.artifact("uxrce_client"),
                // TODO: other uxrce libs
                .cyclonedds = dep.artifact("cyclonedds"), // External
                .fastdds = dep.artifact("fast-dds"), // External
                .fastcdr = dep.artifact("fast-cdr"), // External
                .libstatistics_collector = dep.artifact("libstatistics_collector"),
                .ament_index_cpp = dep.artifact("ament_index_cpp"),
                .rclcpp = dep.artifact("rclcpp"),
                .rclcpp_action = dep.artifact("rclcpp_action"),
                .rclcpp_components = dep.artifact("rclcpp_components"),
                .rclcpp_lifecycle = dep.artifact("rclcpp_lifecycle"),
                .actionlib_msgs = extractInterface(dep, "actionlib_msgs"),
                .diagnostic_msgs = extractInterface(dep, "diagnostic_msgs"),
                .geometry_msgs = extractInterface(dep, "geometry_msgs"),
                .nav_msgs = extractInterface(dep, "nav_msgs"),
                .sensor_msgs = extractInterface(dep, "sensor_msgs"),
                .shape_msgs = extractInterface(dep, "shape_msgs"),
                .std_msgs = extractInterface(dep, "std_msgs"),
                .std_srvs = extractInterface(dep, "std_srvs"),
                .stereo_msgs = extractInterface(dep, "stereo_msgs"),
                .trajectory_msgs = extractInterface(dep, "trajectory_msgs"),
                .visualization_msgs = extractInterface(dep, "visualization_msgs"),
            },
            .python_libraries = .{
                .empy = if (!system_python) dep.builder.lazyDependency("empy", .{}).?.path("") else null,
                .lark = if (!system_python) dep.builder.lazyDependency("lark", .{}).?.path("") else null,
                .rcutils = dep.namedWriteFiles("rcutils").getDirectory(),
                .rosidl_adapter = dep.namedWriteFiles("rosidl_adapter").getDirectory(),
                .rosidl_cli = dep.namedWriteFiles("rosidl_cli").getDirectory(),
                .rosidl_pycommon = dep.namedWriteFiles("rosidl_pycommon").getDirectory(),
                .rosidl_generator_c = dep.namedWriteFiles("rosidl_generator_c").getDirectory(),
                .rosidl_generator_cpp = dep.namedWriteFiles("rosidl_generator_cpp").getDirectory(),
                .rosidl_generator_type_description = dep.namedWriteFiles("rosidl_generator_type_description").getDirectory(),
                .rosidl_parser = dep.namedWriteFiles("rosidl_parser").getDirectory(),
                .rosidl_typesupport_introspection_c = dep.namedWriteFiles("rosidl_typesupport_introspection_c").getDirectory(),
                .rosidl_typesupport_introspection_cpp = dep.namedWriteFiles("rosidl_typesupport_introspection_cpp").getDirectory(),
                .rosidl_typesupport_c = dep.namedWriteFiles("rosidl_typesupport_c").getDirectory(),
                .rosidl_typesupport_cpp = dep.namedWriteFiles("rosidl_typesupport_cpp").getDirectory(),
                .rosidl_typesupport_fastrtps_c = dep.namedWriteFiles("rosidl_typesupport_fastrtps_c").getDirectory(),
                .rosidl_typesupport_fastrtps_cpp = dep.namedWriteFiles("rosidl_typesupport_fastrtps_cpp").getDirectory(),
            },
            .python = if (!system_python)
                // note python is forced to musl to fix an issue building within alpine
                .{ .build = dep.builder.lazyDependency("python", .{ .optimize = .ReleaseFast, .target = dep.builder.resolveTargetQuery(.{ .abi = .musl }) }).?.artifact("cpython") }
            else
                .{ .system = system_python_exe },
            .type_description_generator = dep.artifact("type_description_generator"),
            .adapter_generator = dep.artifact("adapter_generator"),
            .code_generator = dep.artifact("code_generator"),
        };
    }

    pub fn linkRcl(self: ZigRos, step: *Compile) void {
        step.linkLibrary(self.ros_libraries.rcutils);
        step.linkLibrary(self.ros_libraries.rcl);
        step.linkLibrary(self.ros_libraries.rcl_action);
        step.linkLibrary(self.ros_libraries.rcl_lifecycle);
        step.linkLibrary(self.ros_libraries.rmw);
        step.linkLibrary(self.ros_libraries.rcl_yaml_param_parser);
        step.linkLibrary(self.ros_libraries.yaml);
        self.ros_libraries.rcl_interfaces.linkC(step);
        self.ros_libraries.type_description_interfaces.linkC(step);
        step.linkLibrary(self.ros_libraries.rosidl_runtime_c);
        self.ros_libraries.service_msgs.linkC(step);
        self.ros_libraries.builtin_interfaces.linkC(step);
        step.addIncludePath(self.ros_libraries.rosidl_typesupport_interface);
        step.linkLibrary(self.ros_libraries.rosidl_dynamic_typesupport);

        // step.installLibraryHeaders(self.ros_libraries.rcutils);
        // step.installLibraryHeaders(self.ros_libraries.rcl);
        // step.installLibraryHeaders(self.ros_libraries.rcl_action);
        // step.installLibraryHeaders(self.ros_libraries.rcl_lifecycle);
        // step.installLibraryHeaders(self.ros_libraries.rmw);
        // step.installLibraryHeaders(self.ros_libraries.rcl_yaml_param_parser);
        // step.installLibraryHeaders(self.ros_libraries.yaml);
        // step.installLibraryHeaders(self.ros_libraries.rosidl_runtime_c);
        // step.installLibraryHeaders(self.ros_libraries.rosidl_dynamic_typesupport);
    }

    pub fn linkRclcpp(self: ZigRos, step: *Compile) void {
        self.linkRcl(step);
        self.ros_libraries.rcl_interfaces.linkCpp(step);
        self.ros_libraries.type_description_interfaces.linkCpp(step);
        self.ros_libraries.service_msgs.linkCpp(step);
        self.ros_libraries.builtin_interfaces.linkCpp(step);
        self.ros_libraries.statistics_msgs.link(step);
        self.ros_libraries.rosgraph_msgs.link(step);
        self.ros_libraries.composition_interfaces.link(step);
        self.ros_libraries.lifecycle_msgs.link(step);

        step.addIncludePath(self.ros_libraries.tracetools);
        step.addIncludePath(self.ros_libraries.rosidl_runtime_cpp);
        step.root_module.linkLibrary(self.ros_libraries.rosidl_typesupport_introspection_cpp);
        step.root_module.linkLibrary(self.ros_libraries.libstatistics_collector);
        step.root_module.linkLibrary(self.ros_libraries.ament_index_cpp);
        step.root_module.linkLibrary(self.ros_libraries.rclcpp);
        step.root_module.linkLibrary(self.ros_libraries.rclcpp_action);
        step.root_module.linkLibrary(self.ros_libraries.rclcpp_components);
        step.root_module.linkLibrary(self.ros_libraries.rclcpp_lifecycle);
        step.root_module.linkLibrary(self.ros_libraries.rcpputils);
    }

    pub fn linkTf2(self: ZigRos, step: *Compile) void {
        step.linkLibrary(self.ros_libraries.tf2);
        step.linkLibrary(self.ros_libraries.tf2_ros);
        self.ros_libraries.tf2_msgs.linkCpp(step);
    }

    pub fn linkRmwCycloneDds(self: ZigRos, step: *Compile) void {
        step.linkLibrary(self.ros_libraries.rmw_cyclonedds_cpp);
        step.linkLibrary(self.ros_libraries.cyclonedds);
    }

    pub fn linkRmwFastRtps(self: ZigRos, step: *Compile) void {
        if (step.kind == .exe or (step.kind == .lib and step.linkage != null and step.linkage.? == .dynamic)) {
            // ---- Only choose one of fastrtps_cpp or fastrtps_dynamic_cpp! ----
            step.linkLibrary(self.ros_libraries.rmw_fastrtps_cpp);
            // step.linkLibrary(self.ros_libraries.rmw_fastrtps_dynamic_cpp);

            // Always link all typesupport libraries...?
            step.linkLibrary(self.ros_libraries.rosidl_dynamic_typesupport_fastrtps);
            step.linkLibrary(self.ros_libraries.rosidl_typesupport_fastrtps_c);
            step.linkLibrary(self.ros_libraries.rosidl_typesupport_fastrtps_cpp);

            // ---- Always link the 'shared' libraries ----
            step.linkLibrary(self.ros_libraries.rmw_fastrtps_shared_cpp);
            step.linkLibrary(self.ros_libraries.fastdds);
            step.linkLibrary(self.ros_libraries.fastcdr);
        } else {
            // ---- Only choose one of fastrtps_cpp or fastrtps_dynamic_cpp! ----
            step.addIncludePath(self.ros_libraries.rmw_fastrtps_cpp.getEmittedIncludeTree());
            // step.addIncludePath(self.ros_libraries.rmw_fastrtps_dynamic_cpp.getEmittedIncludeTree());

            // Always link all typesupport libraries...?
            step.addIncludePath(self.ros_libraries.rosidl_dynamic_typesupport_fastrtps.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.rosidl_typesupport_fastrtps_c.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.rosidl_typesupport_fastrtps_cpp.getEmittedIncludeTree());

            // ---- Always link the 'shared' libraries ----
            step.addIncludePath(self.ros_libraries.rmw_fastrtps_shared_cpp.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.fastdds.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.fastcdr.getEmittedIncludeTree());
        }
    }

    pub fn linkRmwZenoh(self: ZigRos, step: *Compile) void {
        if (step.kind == .exe) {
            step.linkLibrary(self.ros_libraries.rmw_zenoh_cpp);
            step.linkLibrary(self.ros_libraries.rosidl_typesupport_fastrtps_c);
            step.linkLibrary(self.ros_libraries.rosidl_typesupport_fastrtps_cpp);
            step.linkLibrary(self.ros_libraries.fastcdr);
            step.linkLibrary(self.ros_libraries.fastdds);
        } else {
            step.addIncludePath(self.ros_libraries.rmw_zenoh_cpp.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.rosidl_typesupport_fastrtps_c.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.rosidl_typesupport_fastrtps_cpp.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.fastcdr.getEmittedIncludeTree());
            step.addIncludePath(self.ros_libraries.fastdds.getEmittedIncludeTree());
        }
    }

    pub fn linkLoggerSpd(self: ZigRos, step: *Compile) void {
        step.linkLibrary(self.ros_libraries.rcl_logging_spdlog);
    }

    pub fn createInterface(
        self: ZigRos,
        b: *std.Build,
        name: []const u8,
        compile_args: zigros.CompileArgs,
    ) *RosidlGenerator {
        // TODO fix this. we need the correct python at some time
        return RosidlGenerator.create(
            b,
            name,
            .{
                .rosidl_runtime_c = self.ros_libraries.rosidl_runtime_c,
                .rosidl_runtime_cpp = self.ros_libraries.rosidl_runtime_cpp,
                .rosidl_typesupport_interface = self.ros_libraries.rosidl_typesupport_interface,
                .rosidl_typesupport_c = self.ros_libraries.rosidl_typesupport_c,
                .rosidl_typesupport_cpp = self.ros_libraries.rosidl_typesupport_cpp,
                .rosidl_typesupport_introspection_c = self.ros_libraries.rosidl_typesupport_introspection_c,
                .rosidl_typesupport_introspection_cpp = self.ros_libraries.rosidl_typesupport_introspection_cpp,
                .rosidl_typesupport_fastrtps_c = self.ros_libraries.rosidl_typesupport_fastrtps_c,
                .rosidl_typesupport_fastrtps_cpp = self.ros_libraries.rosidl_typesupport_fastrtps_cpp,
                .rcutils = self.ros_libraries.rcutils,
                .fastcdr = self.ros_libraries.fastcdr,
            },
            .{
                .python = self.python, // TODO not sure how to get the correct python;
                .empy = self.python_libraries.empy,
                .lark = self.python_libraries.lark,
                .rosidl_cli = self.python_libraries.rosidl_cli,
                .rosidl_adapter = self.python_libraries.rosidl_adapter,
                .rosidl_parser = self.python_libraries.rosidl_parser,
                .rosidl_pycommon = self.python_libraries.rosidl_pycommon,
                .rosidl_generator_type_description = self.python_libraries.rosidl_generator_type_description,
                .rosidl_generator_c = self.python_libraries.rosidl_generator_c,
                .rosidl_generator_cpp = self.python_libraries.rosidl_generator_cpp,
                .rosidl_typesupport_c = self.python_libraries.rosidl_typesupport_c,
                .rosidl_typesupport_cpp = self.python_libraries.rosidl_typesupport_cpp,
                .rosidl_typesupport_introspection_c = self.python_libraries.rosidl_typesupport_introspection_c,
                .rosidl_typesupport_introspection_cpp = self.python_libraries.rosidl_typesupport_introspection_cpp,
                .rosidl_typesupport_fastrtps_c = self.python_libraries.rosidl_typesupport_fastrtps_c,
                .rosidl_typesupport_fastrtps_cpp = self.python_libraries.rosidl_typesupport_fastrtps_cpp,
                .type_description_generator = self.type_description_generator,
                .adapter_generator = self.adapter_generator,
                .code_generator = self.code_generator,
            },
            compile_args,
        );
    }
};

const system_python_default = false;
const system_python_arg_name = "system-python";
const system_python_exe = "python3";

pub fn build(b: *std.Build) void {
    // Common compile arguments that all ROS subbuilds accept
    const compile_args = zigros.CompileArgs{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .linkage = b.option(
            std.builtin.LinkMode,
            "linkage",
            "Specify static or dynamic linkage",
        ) orelse .static,
    };

    const system_python = b.option(
        bool,
        system_python_arg_name,
        "If specified, use the system python and python dependencies instead of building python from source. This will save some time on first build, but adds system dependencies outside of zigs control.",
    ) orelse false;

    // Much of ROS requires python for code generation during the build process.
    var python_libraries = PythonLibraries{
        .empy = null,
        .lark = null,
        .rcutils = undefined,
        .rosidl_adapter = undefined,
        .rosidl_cli = undefined,
        .rosidl_pycommon = undefined,
        .rosidl_generator_c = undefined,
        .rosidl_generator_cpp = undefined,
        .rosidl_generator_type_description = undefined,
        .rosidl_parser = undefined,
        .rosidl_typesupport_introspection_c = undefined,
        .rosidl_typesupport_introspection_cpp = undefined,
        .rosidl_typesupport_c = undefined,
        .rosidl_typesupport_cpp = undefined,
        .rosidl_typesupport_fastrtps_c = undefined,
        .rosidl_typesupport_fastrtps_cpp = undefined,
    };

    // All upstream dependencies are direct ROS packages that do not contain zig build files
    // As such, we don't need to pass any arguments
    const upstream_dependencies = UpstreamDependencies{
        .eigen = b.dependency("eigen", .{}),
        .rcutils = b.dependency("rcutils", .{}),
        .rcpputils = b.dependency("rcpputils", .{}),
        .rosidl = b.dependency("rosidl", .{}),
        .rosidl_typesupport = b.dependency("rosidl_typesupport", .{}),
        .rosidl_dynamic_typesupport = b.dependency("rosidl_dynamic_typesupport", .{}),
        .rosidl_dynamic_typesupport_fastrtps = b.dependency("rosidl_dynamic_typesupport_fastrtps", .{}),
        .rosidl_typesupport_fastrtps = b.dependency("rosidl_typesupport_fastrtps", .{}),
        .rmw = b.dependency("rmw", .{}),
        .rmw_dds_common = b.dependency("rmw_dds_common", .{}),
        .rcl_logging = b.dependency("rcl_logging", .{}),
        .spdlog = b.dependency("spdlog", .{}),
        .rcl_interfaces = b.dependency("rcl_interfaces", .{}),
        .common_interfaces = b.dependency("ros2_common_interfaces", .{}),
        .ros2_tracing = b.dependency("ros2_tracing", .{}),
        .rcl = b.dependency("rcl", .{}),
        .rmw_cyclonedds = b.dependency("rmw_cyclonedds", .{}),
        .rmw_fastrtps = b.dependency("rmw_fastrtps", .{}),
        .rmw_zenoh = b.dependency("rmw_zenoh", .{}),
        // .rmw_uxrce = b.dependency("rmw_microxrcedds", .{}),
        .libstatistics_collector = b.dependency("libstatistics_collector", .{}),
        .ament_index = b.dependency("ament_index", .{}),
        .rclcpp = if (compile_args.linkage == .static) b.lazyDependency("rclcpp", .{}) orelse blk: {
            lazy_deps_needed = true;
            break :blk undefined;
        } else b.lazyDependency("rclcpp_visibility_control", .{}) orelse blk: {
            lazy_deps_needed = true;
            break :blk undefined;
        },
    };

    const python = if (system_python)
        zigros.PythonDep{ .system = system_python_exe }
    else blk: {
        const empy = b.lazyDependency("empy", .{});
        const lark = b.lazyDependency("lark", .{});
        // note python is forced to musl to fix an issue building within alpine.
        // The target here is native + musl since python is only used during build.
        const py = b.lazyDependency("python", .{ .optimize = .ReleaseFast, .target = b.resolveTargetQuery(.{ .abi = .musl }) });
        if (empy != null and lark != null and py != null) {
            python_libraries.empy = empy.?.path("");
            python_libraries.lark = lark.?.path("");
            break :blk zigros.PythonDep{ .build = py.?.artifact("cpython") };
        } else {
            lazy_deps_needed = true;
            break :blk undefined;
        }
    };

    // All lazy deps need to be sorted by now
    if (lazy_deps_needed) return;

    var ros_libraries: RosLibraries = undefined;
    const rcutils_artifacts = rcutils.buildWithArgs(
        b,
        compile_args,
        .{ .upstream = upstream_dependencies.rcutils },
        .{ .python = python, .empy = python_libraries.empy },
    );

    ros_libraries.ament_index_cpp = ament_index.buildWithArgs(b, compile_args);

    ros_libraries.rcutils = rcutils_artifacts.rcutils;
    python_libraries.rcutils = rcutils_artifacts.rcutils_py.getDirectory();

    ros_libraries.rcpputils = rcpputils.buildWithArgs(
        b,
        compile_args,
        .{ .upstream = upstream_dependencies.rcpputils, .rcutils = ros_libraries.rcutils },
    );

    const rosidl_artifacts = rosidl.buildWithArgs(b, compile_args, .{
        .rosidl_upstream = b.dependency("rosidl", .{}),
        .rosidl_typesupport_upstream = b.dependency("rosidl_typesupport", .{}),
        .rosidl_dynamic_typesupport_upstream = b.dependency("rosidl_dynamic_typesupport", .{}),
        .rcutils = ros_libraries.rcutils,
        .rcpputils = ros_libraries.rcpputils,
    }, .{ .python = python, .empy = python_libraries.empy });

    ros_libraries.rosidl_typesupport_interface = rosidl_artifacts.rosidl_typesupport_interface;
    ros_libraries.rosidl_runtime_c = rosidl_artifacts.rosidl_runtime_c;
    ros_libraries.rosidl_runtime_cpp = rosidl_artifacts.rosidl_runtime_cpp;
    ros_libraries.rosidl_typesupport_introspection_c =
        rosidl_artifacts.rosidl_typesupport_introspection_c;
    ros_libraries.rosidl_typesupport_introspection_cpp =
        rosidl_artifacts.rosidl_typesupport_introspection_cpp;
    ros_libraries.rosidl_typesupport_c = rosidl_artifacts.rosidl_typesupport_c;
    ros_libraries.rosidl_typesupport_cpp = rosidl_artifacts.rosidl_typesupport_cpp;
    ros_libraries.rosidl_dynamic_typesupport = rosidl_artifacts.rosidl_dynamic_typesupport;
    python_libraries.rosidl_adapter = rosidl_artifacts.rosidl_adapter_py;
    python_libraries.rosidl_cli = rosidl_artifacts.rosidl_cli_py;
    python_libraries.rosidl_pycommon = rosidl_artifacts.rosidl_pycommon_py;
    python_libraries.rosidl_generator_c = rosidl_artifacts.rosidl_generator_c_py;
    python_libraries.rosidl_generator_cpp = rosidl_artifacts.rosidl_generator_cpp_py;
    python_libraries.rosidl_generator_type_description =
        rosidl_artifacts.rosidl_generator_type_description_py;
    python_libraries.rosidl_parser = rosidl_artifacts.rosidl_parser_py;
    python_libraries.rosidl_typesupport_introspection_c =
        rosidl_artifacts.rosidl_typesupport_introspection_c_py;
    python_libraries.rosidl_typesupport_introspection_cpp =
        rosidl_artifacts.rosidl_typesupport_introspection_cpp_py;
    python_libraries.rosidl_typesupport_c = rosidl_artifacts.rosidl_typesupport_c_py;
    python_libraries.rosidl_typesupport_cpp = rosidl_artifacts.rosidl_typesupport_cpp_py;

    ros_libraries.rmw = rmw.buildWithArgs(b, compile_args, .{
        .upstream = upstream_dependencies.rmw,
        .rcutils = ros_libraries.rcutils,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
    });

    const fastdds = b.dependency("fastdds", compile_args).artifact("fast-dds");
    const fastcdr = b.dependency("fastcdr", compile_args).artifact("fast-cdr");
    b.installArtifact(fastcdr);
    b.installArtifact(fastdds);
    ros_libraries.fastcdr = fastcdr;
    ros_libraries.fastdds = fastdds;

    // Build the underlying typesupport library for FastRTPS
    // This will be used by the individual typesupport libraries for every generated interface
    const fastrtps_typesupport_libs = typesupport_fastrtps.buildWithArgs(
        b,
        compile_args,
        .{
            .typesupport_upstream = b.dependency("rosidl_typesupport_fastrtps", .{}),
            .dynamic_typesupport_upstream = b.dependency("rosidl_dynamic_typesupport_fastrtps", .{}),
            .fastcdr = fastcdr,
            .fastdds = fastdds,
            .rmw = ros_libraries.rmw,
            .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
            .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
            .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
            .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
        },
    );
    ros_libraries.rosidl_dynamic_typesupport_fastrtps = fastrtps_typesupport_libs.rosidl_dynamic_typesupport_fastrtps;
    ros_libraries.rosidl_typesupport_fastrtps_c = fastrtps_typesupport_libs.rosidl_typesupport_fastrtps_c;
    ros_libraries.rosidl_typesupport_fastrtps_cpp = fastrtps_typesupport_libs.rosidl_typesupport_fastrtps_cpp;
    python_libraries.rosidl_typesupport_fastrtps_c =
        fastrtps_typesupport_libs.rosidl_typesupport_fastrtps_c_py;
    python_libraries.rosidl_typesupport_fastrtps_cpp =
        fastrtps_typesupport_libs.rosidl_typesupport_fastrtps_cpp_py;

    const rosidl_generator_deps = RosidlGenerator.Deps{
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .rosidl_typesupport_c = ros_libraries.rosidl_typesupport_c,
        .rosidl_typesupport_cpp = ros_libraries.rosidl_typesupport_cpp,
        .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .rosidl_typesupport_fastrtps_c = ros_libraries.rosidl_typesupport_fastrtps_c,
        .rosidl_typesupport_fastrtps_cpp = ros_libraries.rosidl_typesupport_fastrtps_cpp,
        .rcutils = ros_libraries.rcutils,
        .fastcdr = fastcdr,
    };
    const rosidl_generator_build_deps = RosidlGenerator.BuildDeps{
        .python = python,
        .empy = python_libraries.empy,
        .lark = python_libraries.lark,
        .rosidl_cli = python_libraries.rosidl_cli,
        .rosidl_adapter = python_libraries.rosidl_adapter,
        .rosidl_parser = python_libraries.rosidl_parser,
        .rosidl_pycommon = python_libraries.rosidl_pycommon,
        .rosidl_generator_type_description = python_libraries.rosidl_generator_type_description,
        .rosidl_generator_c = python_libraries.rosidl_generator_c,
        .rosidl_generator_cpp = python_libraries.rosidl_generator_cpp,
        .rosidl_typesupport_c = python_libraries.rosidl_typesupport_c,
        .rosidl_typesupport_cpp = python_libraries.rosidl_typesupport_cpp,
        .rosidl_typesupport_introspection_c = python_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = python_libraries.rosidl_typesupport_introspection_cpp,
        .rosidl_typesupport_fastrtps_c = python_libraries.rosidl_typesupport_fastrtps_c,
        .rosidl_typesupport_fastrtps_cpp = python_libraries.rosidl_typesupport_fastrtps_cpp,
        .type_description_generator = rosidl_artifacts.type_description_generator,
        .adapter_generator = rosidl_artifacts.adapter_generator,
        .code_generator = rosidl_artifacts.code_generator,
    };

    const rmw_dds_common_artifacts = rmw_dds_common.buildWithArgs(
        b,
        compile_args,
        .{
            .upstream = upstream_dependencies.rmw_dds_common,
            .rcutils = ros_libraries.rcutils,
            .rcpputils = ros_libraries.rcpputils,
            .rmw = ros_libraries.rmw,
            .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
            .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
            .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
            .rosidl_generator = rosidl_generator_deps,
        },
        .{ .rosidl_generator = rosidl_generator_build_deps },
    );

    ros_libraries.rmw_dds_common = rmw_dds_common_artifacts.rmw_dds_common;
    ros_libraries.rmw_dds_common_interface = rmw_dds_common_artifacts.rmw_dds_common_interface;

    const rcl_logging_artifacts = rcl_logging.buildWithArgs(
        b,
        compile_args,
        .{
            .upstream = upstream_dependencies.rcl_logging,
            .spdlog = upstream_dependencies.spdlog,
            .rcutils = ros_libraries.rcutils,
            .rcpputils = ros_libraries.rcpputils,
        },
    );

    ros_libraries.rcl_logging_interface = rcl_logging_artifacts.rcl_logging_interface;
    ros_libraries.rcl_logging_spdlog = rcl_logging_artifacts.rcl_logging_spdlog;

    const rcl_interfaces_artifacts = rcl_interfaces.buildWithArgs(
        b,
        compile_args,
        .{
            .upstream = upstream_dependencies.rcl_interfaces,
            .rosidl_generator = rosidl_generator_deps,
        },
        .{ .rosidl_generator = rosidl_generator_build_deps },
    );

    ros_libraries.builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces;
    ros_libraries.rosgraph_msgs = rcl_interfaces_artifacts.rosgraph_msgs;
    ros_libraries.action_msgs = rcl_interfaces_artifacts.action_msgs;
    ros_libraries.service_msgs = rcl_interfaces_artifacts.service_msgs;
    ros_libraries.unique_identifier_msgs = rcl_interfaces_artifacts.unique_identifier_msgs;
    ros_libraries.type_description_interfaces =
        rcl_interfaces_artifacts.type_description_interfaces;
    ros_libraries.statistics_msgs = rcl_interfaces_artifacts.statistics_msgs;
    ros_libraries.rcl_interfaces = rcl_interfaces_artifacts.rcl_interfaces;
    ros_libraries.composition_interfaces = rcl_interfaces_artifacts.composition_interfaces;
    ros_libraries.lifecycle_msgs = rcl_interfaces_artifacts.lifecycle_msgs;

    ros_libraries.tracetools = ros2_tracing.build(b);

    const common_interfaces_artifacts = common_interfaces.buildWithArgs(
        b,
        compile_args,
        .{
            .upstream = upstream_dependencies.common_interfaces,
            .rosidl_generator = rosidl_generator_deps,
            .builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces,
            .service_msgs = rcl_interfaces_artifacts.service_msgs,
        },
        .{
            .rosidl_generator = rosidl_generator_build_deps,
        },
    );

    ros_libraries.actionlib_msgs = common_interfaces_artifacts.actionlib_msgs;
    ros_libraries.diagnostic_msgs = common_interfaces_artifacts.diagnostic_msgs;
    ros_libraries.geometry_msgs = common_interfaces_artifacts.geometry_msgs;
    ros_libraries.nav_msgs = common_interfaces_artifacts.nav_msgs;
    ros_libraries.sensor_msgs = common_interfaces_artifacts.sensor_msgs;
    ros_libraries.shape_msgs = common_interfaces_artifacts.shape_msgs;
    ros_libraries.std_msgs = common_interfaces_artifacts.std_msgs;
    ros_libraries.std_srvs = common_interfaces_artifacts.std_srvs;
    ros_libraries.stereo_msgs = common_interfaces_artifacts.stereo_msgs;
    ros_libraries.trajectory_msgs = common_interfaces_artifacts.trajectory_msgs;
    ros_libraries.visualization_msgs = common_interfaces_artifacts.visualization_msgs;

    ros_libraries.yaml = b.dependency("yaml", compile_args).artifact("yaml");
    ros_libraries.yaml_cpp = b.dependency("yaml_cpp", compile_args).artifact("yaml-cpp");
    // re-install libs so we can grab it directly from the zigros dependency later
    b.installArtifact(ros_libraries.yaml);
    b.installArtifact(ros_libraries.yaml_cpp);

    const rcl_artifacts = rcl.buildWithArgs(
        b,
        compile_args,
        .{
            .upstream = upstream_dependencies.rcl,
            .rcutils = ros_libraries.rcutils,
            .yaml = ros_libraries.yaml,
            .rmw = ros_libraries.rmw,
            .tracetools = ros_libraries.tracetools,
            .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
            .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
            .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
            .rcl_logging_interface = ros_libraries.rcl_logging_interface,
            .type_description_interfaces = ros_libraries.type_description_interfaces,
            .action_msgs = ros_libraries.action_msgs,
            .service_msgs = ros_libraries.service_msgs,
            .builtin_interfaces = ros_libraries.builtin_interfaces,
            .rcl_interfaces = ros_libraries.rcl_interfaces,
            .lifecycle_msgs = ros_libraries.lifecycle_msgs,
            // TODO: still need to properly handle dependencies
            // (unique_identifier_msgs only needed as a transitive dependency from action_msgs)
            .unique_identifier_msgs = ros_libraries.unique_identifier_msgs,
        },
    );

    ros_libraries.rcl_yaml_param_parser = rcl_artifacts.rcl_yaml_param_parser;
    ros_libraries.rcl = rcl_artifacts.rcl;
    ros_libraries.rcl_action = rcl_artifacts.rcl_action;
    ros_libraries.rcl_lifecycle = rcl_artifacts.rcl_lifecycle;

    ros_libraries.tinyxml2 = tinyxml2.buildWithArgs(b, compile_args);

    ros_libraries.console_bridge = console_bridge.buildWithArgs(b, compile_args);
    ros_libraries.class_loader = class_loader.buildWithArgs(b, compile_args, .{
        .console_bridge = ros_libraries.console_bridge,
        .rcutils = ros_libraries.rcutils,
        .rcpputils = ros_libraries.rcpputils,
    });

    ros_libraries.pluginlib = pluginlib.buildWithArgs(b, .{
        .ament_index_cpp = ros_libraries.ament_index_cpp,
        .class_loader_lib = ros_libraries.class_loader,
        .tinyxml2_lib = ros_libraries.tinyxml2,
    }, compile_args);
    ros_libraries.message_filters = message_filters.buildWithArgs(b, .{ .std_msgs = ros_libraries.std_msgs }, compile_args);
    ros_libraries.dynmsg = dynmsg.buildWithArgs(b, .{
        .yaml_cpp = ros_libraries.yaml_cpp,
        .rcutils = ros_libraries.rcutils,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
    }, compile_args);

    // Currently, due to MUSL libC limitations around pthreads,
    // Iceoryx shared-memory is only supported for GNU libC
    const abi = compile_args.target.result.abi;
    const enable_shm: bool = if (abi == .musl) false else true;

    const cyclonedds_dep = b.dependency("cyclonedds", .{
        .target = compile_args.target,
        .optimize = compile_args.optimize,
        .linkage = compile_args.linkage,
        .enable_shm = enable_shm,
    });
    const cyclonedds = cyclonedds_dep.artifact("cyclonedds");
    b.installArtifact(cyclonedds);

    if (enable_shm) {
        // // Iceoryx RouDi (Routing and Discovery) only exists with shared-memory support
        // const iox_roudi = cyclonedds_dep.artifact("iox-roudi");
        // b.installArtifact(iox_roudi);
    }

    ros_libraries.rmw_cyclonedds_cpp = rmw_cyclonedds.buildWithArgs(b, compile_args, .{
        .upstream = upstream_dependencies.rmw_cyclonedds,
        .rcutils = ros_libraries.rcutils,
        .tracetools = ros_libraries.tracetools,
        .cyclonedds = cyclonedds,
        .rcpputils = ros_libraries.rcpputils,
        .rmw = ros_libraries.rmw,
        .rmw_dds_common = ros_libraries.rmw_dds_common,
        .rmw_dds_common_interface = ros_libraries.rmw_dds_common_interface,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
    });

    const fastrtps_libs = rmw_fastrtps.buildWithArgs(b, compile_args, .{
        .upstream = upstream_dependencies.rmw_fastrtps,
        .rosidl_typesupport_fastrtps_upstream = b.dependency("rosidl_typesupport_fastrtps", .{}),
        .rcutils = ros_libraries.rcutils,
        .tracetools = ros_libraries.tracetools,
        .fastdds = fastdds,
        .fastcdr = fastcdr,
        .rcpputils = ros_libraries.rcpputils,
        .rmw = ros_libraries.rmw,
        .rmw_dds_common = ros_libraries.rmw_dds_common,
        .rmw_dds_common_interface = ros_libraries.rmw_dds_common_interface,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
        .rosidl_dynamic_typesupport_fastrtps = ros_libraries.rosidl_dynamic_typesupport_fastrtps,
        .rosidl_typesupport_fastrtps_c = ros_libraries.rosidl_typesupport_fastrtps_c,
        .rosidl_typesupport_fastrtps_cpp = ros_libraries.rosidl_typesupport_fastrtps_cpp,
    });
    ros_libraries.rmw_fastrtps_cpp = fastrtps_libs.rmw_fastrtps;
    // ros_libraries.rmw_fastrtps_dynamic_cpp = fastrtps_libs.rmw_fastrtps_dynamic;
    ros_libraries.rmw_fastrtps_shared_cpp = fastrtps_libs.rmw_fastrtps_shared;

    const zenoh_artifacts = rmw_zenoh.buildWithArgs(b, compile_args, .{
        .upstream = upstream_dependencies.rmw_zenoh,
        .ament_index_cpp = ros_libraries.ament_index_cpp,
        .fastcdr = fastcdr,
        .rcpputils = ros_libraries.rcpputils,
        .rcutils = ros_libraries.rcutils,
        .rmw = ros_libraries.rmw,
        .tracetools = ros_libraries.tracetools,
        .zenohc_library_path = "/home/jcrabill/.local/lib/x86_64-linux-musl/",
        .zenohc_include_path = "/home/jcrabill/.local/include/x86_64-linux-musl/",
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .rosidl_typesupport_fastrtps_c = ros_libraries.rosidl_typesupport_fastrtps_c,
        .rosidl_typesupport_fastrtps_cpp = ros_libraries.rosidl_typesupport_fastrtps_cpp,
        .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
    });
    ros_libraries.rmw_zenoh_cpp = zenoh_artifacts.rmw_zenoh_cpp;

    // const microcdr = b.dependency("microcdr", compile_args).artifact("microcdr");
    // const uxrce_client = b.dependency("uxrce_client", compile_args).artifact("micro-xrce-dds-client");

    // const uxrce_libs = rmw_uxrce.buildWithArgs(
    //     b,
    //     compile_args,
    //     .{
    //         .upstream = upstream_dependencies.rmw_uxrce,
    //         .microcdr = microcdr,
    //         .uxrce_client = uxrce_client,
    //         .rcutils = ros_libraries.rcutils,
    //         .rmw = ros_libraries.rmw,
    //         .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
    //         .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
    //         .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
    //         .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
    //         .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
    //         .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
    //     },
    //     .udp,
    // );
    // ros_libraries.microcdr = microcdr;
    // ros_libraries.uxrce_client = uxrce_client;
    // ros_libraries.rosidl_typesupport_microxrcedds_c = uxrce_libs.rosidl_typesupport_microxrcedds_c;
    // ros_libraries.rosidl_typesupport_microxrcedds_cpp = uxrce_libs.rosidl_typesupport_microxrcedds_cpp;
    // ros_libraries.rmw_uxrce = uxrce_libs.rmw_uxrce;

    ros_libraries.libstatistics_collector = libstatistics_collector.buildWithArgs(b, compile_args, .{
        .upstream = upstream_dependencies.libstatistics_collector,
        .rcl = ros_libraries.rcl,
        .rcl_yaml_param_parser = ros_libraries.rcl_yaml_param_parser,
        .yaml = ros_libraries.yaml,
        .rcl_logging_interface = ros_libraries.rcl_logging_interface,
        .rcutils = ros_libraries.rcutils,
        .rmw = ros_libraries.rmw,
        .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .tracetools = ros_libraries.tracetools,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
        .service_msgs = ros_libraries.service_msgs,
        .builtin_interfaces = ros_libraries.builtin_interfaces,
        .rcl_interfaces = ros_libraries.rcl_interfaces,
        .rcpputils = ros_libraries.rcpputils,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .statistics_msgs = ros_libraries.statistics_msgs,
    });

    const rclcpp_artifacts = rclcpp.buildWithArgs(b, compile_args, .{
        .upstream = upstream_dependencies.rclcpp,
        .class_loader = ros_libraries.class_loader,
        .rcutils = ros_libraries.rcutils,
        .rcl = ros_libraries.rcl,
        .rcl_action = ros_libraries.rcl_action,
        .rcl_lifecycle = ros_libraries.rcl_lifecycle,
        .rcl_yaml_param_parser = ros_libraries.rcl_yaml_param_parser,
        .rcl_logging_interface = ros_libraries.rcl_logging_interface,
        .yaml = ros_libraries.yaml,
        .rmw = ros_libraries.rmw,
        .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .tracetools = ros_libraries.tracetools,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
        .service_msgs = ros_libraries.service_msgs,
        .action_msgs = ros_libraries.action_msgs,
        .unique_identifier_msgs = ros_libraries.unique_identifier_msgs,
        .builtin_interfaces = ros_libraries.builtin_interfaces,
        .rcl_interfaces = ros_libraries.rcl_interfaces,
        .rcpputils = ros_libraries.rcpputils,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .ament_index_cpp = ros_libraries.ament_index_cpp,
        .libstatistics_collector = ros_libraries.libstatistics_collector,
        .statistics_msgs = ros_libraries.statistics_msgs,
        .composition_interfaces = ros_libraries.composition_interfaces,
        .lifecycle_msgs = ros_libraries.lifecycle_msgs,
        .rosgraph_msgs = ros_libraries.rosgraph_msgs,
    }, .{
        .python = python,
        .empy = python_libraries.empy,
        .rcutils = python_libraries.rcutils,
    });
    ros_libraries.rclcpp = rclcpp_artifacts.rclcpp;
    ros_libraries.rclcpp_action = rclcpp_artifacts.rclcpp_action;
    ros_libraries.rclcpp_components = rclcpp_artifacts.rclcpp_components;
    ros_libraries.rclcpp_lifecycle = rclcpp_artifacts.rclcpp_lifecycle;

    ros_libraries.tf2 = tf2.tf2.buildWithArgs(b, .{
        .rcutils = ros_libraries.rcutils,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .builtin_interfaces = ros_libraries.builtin_interfaces,
        .std_msgs = ros_libraries.std_msgs,
        .geometry_msgs = ros_libraries.geometry_msgs,
    }, compile_args);

    ros_libraries.tf2_msgs = tf2.tf2_msgs.getInterface(b, .{
        .rosidl_generator = rosidl_generator_build_deps,
    }, .{
        .rosidl_generator = rosidl_generator_deps,
        .action_msgs = ros_libraries.action_msgs,
        .builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces,
        .geometry_msgs = ros_libraries.geometry_msgs,
        .service_msgs = rcl_interfaces_artifacts.service_msgs,
        .std_msgs = ros_libraries.std_msgs,
        .unique_identifier_msgs = ros_libraries.unique_identifier_msgs,
    }, compile_args);

    // TODO: Separate out the static_transform_publisher - it should use the higher-level APIs
    // It's a full ROS node, so building it should live elsewhere
    ros_libraries.tf2_ros = tf2.tf2_ros.buildWithArgs(b, .{
        // ---- Libs
        .class_loader = ros_libraries.class_loader,
        .console_bridge = ros_libraries.console_bridge,
        .message_filters_lib = ros_libraries.message_filters,
        .rclcpp = ros_libraries.rclcpp,
        .rclcpp_action = ros_libraries.rclcpp_action,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .tf2_lib = ros_libraries.tf2,
        // ---- Include Paths
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .tracetools = ros_libraries.tracetools,
        // ---- Interfaces
        .action_msgs = ros_libraries.action_msgs,
        .builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces,
        .geometry_msgs = ros_libraries.geometry_msgs,
        .rcl_interfaces = ros_libraries.rcl_interfaces,
        .service_msgs = rcl_interfaces_artifacts.service_msgs,
        .statistics_msgs = rcl_interfaces_artifacts.statistics_msgs,
        .std_msgs = ros_libraries.std_msgs,
        .tf2_msgs = ros_libraries.tf2_msgs,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
        .unique_identifier_msgs = ros_libraries.unique_identifier_msgs,
    }, compile_args);

    ros_libraries.tf2_eigen = tf2.tf2_eigen.buildWithArgs(b, .{
        .eigen = upstream_dependencies.eigen,
        // ---- Libs
        .class_loader = ros_libraries.class_loader,
        .console_bridge = ros_libraries.console_bridge,
        .message_filters_lib = ros_libraries.message_filters,
        .rclcpp = ros_libraries.rclcpp,
        .rclcpp_action = ros_libraries.rclcpp_action,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .tf2 = ros_libraries.tf2,
        .tf2_ros = ros_libraries.tf2_ros,
        // ---- Include Paths
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .tracetools = ros_libraries.tracetools,
        // ---- Interfaces
        .action_msgs = ros_libraries.action_msgs,
        .builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces,
        .geometry_msgs = ros_libraries.geometry_msgs,
        .rcl_interfaces = ros_libraries.rcl_interfaces,
        .service_msgs = rcl_interfaces_artifacts.service_msgs,
        .statistics_msgs = rcl_interfaces_artifacts.statistics_msgs,
        .std_msgs = ros_libraries.std_msgs,
        .tf2_msgs = ros_libraries.tf2_msgs,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
        .unique_identifier_msgs = ros_libraries.unique_identifier_msgs,
    }, compile_args);

    ros_libraries.geographic = geographic.buildWithArgs(b, compile_args);

    // TODO: image_transport needs OpenCV
    // ros_libraries.image_transport = image_transport.buildWithArgs(b, .{
    //     .class_loader_lib = ros_libraries.class_loader,
    //     .message_filters_lib = ros_libraries.message_filters,
    //     .pluginlib_lib = ros_libraries.pluginlib,
    //     .rclcpp = ros_libraries.rclcpp,
    //     .rclcpp_components = ros_libraries.rclcpp_components,
    //     .std_msgs = ros_libraries.std_msgs,
    //     .sensor_msgs = ros_libraries.sensor_msgs,
    // }, compile_args);

    const camera_info_libs = camera_info.buildWithArgs(b, .{
        // ---- Libs
        .class_loader = ros_libraries.class_loader,
        .console_bridge = ros_libraries.console_bridge,
        .message_filters_lib = ros_libraries.message_filters,
        .rclcpp = ros_libraries.rclcpp,
        .rclcpp_action = ros_libraries.rclcpp_action,
        .rclcpp_lifecycle = ros_libraries.rclcpp_lifecycle,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .yaml_cpp_lib = ros_libraries.yaml_cpp,
        // ---- Include Paths
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .tracetools = ros_libraries.tracetools,
        // ---- Interfaces
        .action_msgs = ros_libraries.action_msgs,
        .builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces,
        .geometry_msgs = ros_libraries.geometry_msgs,
        .lifecycle_msgs = ros_libraries.lifecycle_msgs,
        .rcl_interfaces = ros_libraries.rcl_interfaces,
        .sensor_msgs = ros_libraries.sensor_msgs,
        .service_msgs = rcl_interfaces_artifacts.service_msgs,
        .statistics_msgs = rcl_interfaces_artifacts.statistics_msgs,
        .std_msgs = ros_libraries.std_msgs,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
        .unique_identifier_msgs = ros_libraries.unique_identifier_msgs,
    }, compile_args);
    ros_libraries.camera_calibration_parsers = camera_info_libs.camera_calibration_parsers;
    ros_libraries.camera_info_manager = camera_info_libs.camera_info_manager;

    const rmw_implementation = rmw_impl.buildWithArgs(b, compile_args, .{
        .ament_index_cpp = ros_libraries.ament_index_cpp,
        .rcpputils = ros_libraries.rcpputils,
        .rcutils = ros_libraries.rcutils,
        .rmw = ros_libraries.rmw,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_dynamic_typesupport = ros_libraries.rosidl_dynamic_typesupport,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
    });

    _ = zstd.buildWithArgs(b, compile_args);
    const rjson = rapidjson.buildWithArgs(b, compile_args);
    const rosbag_libs = rosbag2.buildWithArgs(b, .{
        .ament_index_cpp = ros_libraries.ament_index_cpp,
        .pluginlib = ros_libraries.pluginlib,
        .rclcpp = ros_libraries.rclcpp,
        .rcpputils = ros_libraries.rcpputils,
        .rcutils = ros_libraries.rcutils,
        .rmw = ros_libraries.rmw,
        .rmw_implementation = rmw_implementation,
        .rosidl_runtime_c = ros_libraries.rosidl_runtime_c,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_c = ros_libraries.rosidl_typesupport_c,
        .rosidl_typesupport_cpp = ros_libraries.rosidl_typesupport_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .rosidl_typesupport_introspection_c = ros_libraries.rosidl_typesupport_introspection_c,
        .rosidl_typesupport_introspection_cpp = ros_libraries.rosidl_typesupport_introspection_cpp,
        .tracetools = ros_libraries.tracetools,
        .yaml_cpp = ros_libraries.yaml_cpp,
        .builtin_interfaces = rcl_interfaces_artifacts.builtin_interfaces,
        .service_msgs = rcl_interfaces_artifacts.service_msgs,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
    }, compile_args);

    _ = rosx_introspection.buildWithArgs(b, .{
        .ament_index_cpp = ros_libraries.ament_index_cpp,
        .rapidjson = rjson,
        .rosbag2_cpp = rosbag_libs.rosbag2_cpp,
        .rclcpp = ros_libraries.rclcpp,
        .fastcdr = ros_libraries.fastcdr,
        .builtin_interfaces = ros_libraries.builtin_interfaces,
        .rcl_interfaces = ros_libraries.rcl_interfaces,
        .service_msgs = rcl_interfaces_artifacts.service_msgs,
        .rosidl_runtime_cpp = ros_libraries.rosidl_runtime_cpp,
        .rosidl_typesupport_interface = ros_libraries.rosidl_typesupport_interface,
        .type_description_interfaces = ros_libraries.type_description_interfaces,
        .tracetools = ros_libraries.tracetools,
        .statistics_msgs = rcl_interfaces_artifacts.statistics_msgs,
    }, compile_args);

    //////////////////////////////////////////////////////////////////////////////////////
    // ROS / Ament Installation Configuration
    //////////////////////////////////////////////////////////////////////////////////////

    // Already have utils.addRosPackage() use above; those setup the files needed for the ROS environment
    // Create a local_setup.sh file that exports AMENT_PREFIX_PATH=<install_dir>
    const local_setup_sh = b.addWriteFiles();
    const local_setup_sh_path = local_setup_sh.add("local_setup.sh",
        \\#!/bin/bash
        \\export ZIGROS_INSTALL_ROOT=$(dirname $(realpath ${BASH_SOURCE[0]}))
        \\export AMENT_PREFIX_PATH=${ZIGROS_INSTALL_ROOT}
        \\export PATH=${PATH}:${ZIGROS_INSTALL_ROOT}/bin/
        \\export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ZIGROS_INSTALL_ROOT}/lib/
        \\
    );
    const install_local_setup_sh = b.addInstallFileWithDir(local_setup_sh_path, .prefix, "local_setup.sh");
    b.getInstallStep().dependOn(&install_local_setup_sh.step);
}
