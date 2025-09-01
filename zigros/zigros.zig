// Common functions and structs used throughout the zigros build.
const std = @import("std");
const Interface = @import("../ros_core/rosidl/src/RosidlGenerator.zig").Interface;

const LazyPath = std.Build.LazyPath;
const Dependency = std.Build.Dependency;
const Compile = std.Build.Step.Compile;
const Module = std.Build.Module;
const WriteFile = std.Build.Step.WriteFile;

pub const Language = enum {
    c,
    cpp,
};

// This links all relevant fields in a struct of dependencies to the provided module.
// This will link any *Compile field, add all lazy paths as include files, and use the link helper
// with any provided Interface types. the lang arg is only used for interfaces for now. If .c is
// provided, linkC is called. If .cpp is provided it calls link.
pub fn linkDependencyStruct(step: *std.Build.Step.Compile, dependencies: anytype, lang: Language) void {
    comptime switch (@typeInfo(@TypeOf(dependencies))) {
        .@"struct" => {},
        else => @compileError("dependency type must be a struct"),
    };
    const deps_info = @typeInfo(@TypeOf(dependencies)).@"struct";
    inline for (deps_info.fields) |field| {
        if (field.type == *std.Build.Step.Compile) {
            step.linkLibrary(@field(dependencies, field.name));
            // step.installLibraryHeaders(@field(dependencies, field.name));
        } else if (field.type == std.Build.LazyPath) {
            step.addIncludePath(@field(dependencies, field.name));
        } else if (field.type == Interface) {
            switch (lang) {
                .c => @field(dependencies, field.name).linkC(step.root_module),
                .cpp => @field(dependencies, field.name).link(step.root_module),
            }
        }
    }
}

pub const PythonDep = union(enum) {
    system: []const u8, // Path to system python executable
    build: *std.Build.Step.Compile,
};

pub const CompileArgs = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode = .static,
    strip: bool,
};

/// Description of a system library
pub const SystemLib = struct {
    name: []const u8,
    include_dir: ?[]const u8 = null,
    library_dir: ?[]const u8 = null,
};

/// Available ROS MiddleWare options
pub const RmwKind = enum(u8) {
    cyclonedds,
    fastrtps,
    zenoh,
};

/// Wrapper for RMW-specific libraries
pub const Rmw = union(RmwKind) {
    cyclonedds: struct {
        rmw_cyclonedds_cpp: *Compile,
        cyclonedds: *Compile,
    },
    fastrtps: struct {
        rmw_fastrtps_cpp: *Compile,
        rosidl_dynamic_typesupport_fastrtps: *Compile,
        rosidl_typesupport_fastrtps_c: *Compile,
        rosidl_typesupport_fastrtps_cpp: *Compile,
        rmw_fastrtps_shared_cpp: *Compile,
        fastdds: *Compile,
        fastcdr: *Compile,
    },
    zenoh: struct {
        rmw_zenoh_cpp: *Compile,
        rosidl_typesupport_fastrtps_c: *Compile,
        rosidl_typesupport_fastrtps_cpp: *Compile,
        fastcdr: *Compile,
        fastdds: *Compile,
        zenohc: SystemLib,
    },
    // TODO: uxrce_dds

    /// Link a Module to a specific ROS Middleware
    pub fn link(self: Rmw, mod: *Module) void {
        switch (self) {
            inline else => |r| {
                const tinfo = @typeInfo(@TypeOf(r)).@"struct";
                inline for (tinfo.fields) |field| {
                    if (field.type == *std.Build.Step.Compile) {
                        mod.linkLibrary(@field(r, field.name));
                    } else if (field.type == std.Build.LazyPath) {
                        mod.addIncludePath(@field(r, field.name));
                    } else if (field.type == SystemLib) {
                        const lib: SystemLib = @field(r, field.name);
                        mod.linkSystemLibrary(lib.name, .{
                            .search_strategy = .paths_first,
                            .preferred_link_mode = .static,
                        });
                        if (lib.library_dir) |dir| mod.addLibraryPath(.{ .cwd_relative = dir });
                        if (lib.include_dir) |dir| mod.addIncludePath(.{ .cwd_relative = dir });
                    }
                }
            },
        }
    }
};

pub const Rcl = struct {
    // Includes
    rosidl_typesupport_interface: LazyPath,

    // Libraries
    rcutils: *Compile,
    rcl: *Compile,
    rcl_action: *Compile,
    rcl_lifecycle: *Compile,
    rmw: *Compile,
    rcl_yaml_param_parser: *Compile,
    yaml: *Compile,
    rosidl_runtime_c: *Compile,
    rosidl_dynamic_typesupport: *Compile,

    // Interfaces
    rcl_interfaces: Interface,
    type_description_interfaces: Interface,
    service_msgs: Interface,
    builtin_interfaces: Interface,

    pub fn link(self: Rcl, mod: *Module) void {
        mod.addIncludePath(self.rosidl_typesupport_interface);

        mod.linkLibrary(self.rcl);
        mod.linkLibrary(self.rcl_action);
        mod.linkLibrary(self.rcl_lifecycle);
        mod.linkLibrary(self.rcl_yaml_param_parser);
        mod.linkLibrary(self.rcutils);
        mod.linkLibrary(self.rmw);
        mod.linkLibrary(self.rosidl_dynamic_typesupport);
        mod.linkLibrary(self.rosidl_runtime_c);
        mod.linkLibrary(self.yaml);

        self.builtin_interfaces.linkC(mod);
        self.rcl_interfaces.linkC(mod);
        self.service_msgs.linkC(mod);
        self.type_description_interfaces.linkC(mod);
    }
};

/// Container for rclcpp libraries
pub const Rclcpp = struct {
    // rcl: *const Rcl,

    tracetools: LazyPath,
    rosidl_runtime_cpp: LazyPath,
    rosidl_typesupport_introspection_cpp: *Compile,
    libstatistics_collector: *Compile,
    ament_index_cpp: *Compile,
    rclcpp: *Compile,
    rclcpp_action: *Compile,
    rclcpp_components: *Compile,
    rclcpp_lifecycle: *Compile,
    rcpputils: *Compile,

    rcl_interfaces: Interface,
    type_description_interfaces: Interface,
    service_msgs: Interface,
    builtin_interfaces: Interface,
    statistics_msgs: Interface,
    rosgraph_msgs: Interface,
    composition_interfaces: Interface,
    lifecycle_msgs: Interface,

    /// Link the module to all rclcpp libraries
    pub fn link(self: Rclcpp, mod: *Module) void {
        // self.rcl.link(mod);

        mod.addIncludePath(self.rosidl_runtime_cpp);
        mod.addIncludePath(self.tracetools);

        self.builtin_interfaces.linkCpp(mod);
        self.composition_interfaces.link(mod);
        self.lifecycle_msgs.link(mod);
        self.rcl_interfaces.linkCpp(mod);
        self.rosgraph_msgs.link(mod);
        self.service_msgs.linkCpp(mod);
        self.statistics_msgs.link(mod);
        self.type_description_interfaces.linkCpp(mod);

        mod.linkLibrary(self.ament_index_cpp);
        mod.linkLibrary(self.libstatistics_collector);
        mod.linkLibrary(self.rclcpp);
        mod.linkLibrary(self.rclcpp_action);
        mod.linkLibrary(self.rclcpp_components);
        mod.linkLibrary(self.rclcpp_lifecycle);
        mod.linkLibrary(self.rcpputils);
        mod.linkLibrary(self.rosidl_typesupport_introspection_cpp);
    }
};
