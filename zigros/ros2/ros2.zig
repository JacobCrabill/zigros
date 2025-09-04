const std = @import("std");
const flags = @import("flags");

const c = @cImport({
    @cInclude("cli.h");
});

pub const std_options: std.Options = .{
    // Set the log level to info; options are debug, info, warn, err
    .log_level = .info,
};

const logger = std.log.scoped(.planner);

const default_port: usize = 8000;

/// Command-line arguments definition for the Flags module
const Flags = struct {
    pub const description = "ROS2 Command-Line Interface";

    command: union(enum) {
        // Interactions on ROS nodes
        node: struct {
            command: union(enum) {
                list: struct {},

                pub const descriptions = .{
                    .list = "List all active nodes",
                };
            },
        },

        // Interactions on ROS topics
        topic: struct {
            command: union(enum) {
                list: struct {},
                echo: struct {
                    count: usize = 1,
                    positional: struct {
                        topic: []const u8,
                        pub const descriptions = .{
                            .topic = "Topic name to echo",
                        };
                    },
                    pub const switches = .{
                        .count = 'n',
                    };
                },
                @"pub": struct {
                    topic: []const u8,
                    package: []const u8,
                    typename: []const u8,
                    message: []const u8,
                    count: usize = 10,
                    pub const descriptions = .{
                        .topic = "Topic name to publish on",
                        .package = "Package (namespace) containing the type, e.g. sensor_msgs",
                        .typename = "Name of the message type, e.g. image",
                        .message = "YAML message value to publish",
                        .count = "Number of times to publish the message (default: 10)",
                    };
                    pub const switches = .{
                        .topic = 't',
                        .package = 'p',
                        .typename = 'T',
                        .message = 'm',
                        .count = 'n',
                    };
                },

                pub const descriptions = .{
                    .list = "List all active topics (subscriptions & publications)",
                    .echo = "Print out one publication on the chosen topic",
                    .@"pub" = "Publish a message on a given topic",
                };
            },
        },

        // Interactions on ROS services
        service: struct { command: union(enum) {
            list: struct {},

            pub const descriptions = .{
                .list = "List all active services",
            };
        } },

        launch: struct {
            package: []const u8,
            script: []const u8 = "launch.sh",
            pub const descriptions = .{
                .package = "Package to run a launch script from",
                .script = "Launch script to run (defaults to launch.sh)",
            };
            pub const switches = .{
                .package = 'p',
                .script = 's',
            };
        },

        run: struct {
            ros_args: ?[]const u8 = null,
            positional: struct {
                node: []const u8,
                pub const descriptions = .{
                    .node = "ROS node (executable) to run",
                };
            },
            pub const descriptions = .{
                .ros_args = "Optional ROS2 command-line arguments, e.g. '-p my-param:=value'",
            };
        },

        pub const descriptions = .{
            .node = "Interact with nodes in the current ROS domain",
            .topic = "Interact with topics in the current ROS domain",
            .service = "Interact with services in the current ROS domain",
            .launch = "Launch a ROS package",
            .run = "Run a ROS node with default arguments",
        };
    },
};

pub fn main() !void {
    // Use the GeneralPurposeAllocator for debug (performs leak checking and such); otherwise use page_allocator for speed
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 15, .thread_safe = true }){};
    defer _ = gpa.deinit();
    const alloc: std.mem.Allocator = if (@import("builtin").mode == .Debug) gpa.allocator() else std.heap.page_allocator;

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    // Diagnostics store the name and help info about the command being parsed.
    // You can use this to display help / usage if there is a parsing error.
    const colorscheme = flags.ColorScheme{
        .error_label = &.{ .red, .bold },
        .header = &.{ .bright_green, .bold },
        .command_name = &.{.bright_blue},
        .option_name = &.{.bright_magenta},
    };

    const params = flags.parse(args, "ros2", Flags, .{ .colors = &colorscheme });

    switch (params.command) {
        .node => |node_cmd| {
            switch (node_cmd.command) {
                .list => c.list_nodes(),
            }
        },
        .topic => |topic_cmd| {
            switch (topic_cmd.command) {
                .list => c.list_topics(),
                .echo => |e| {
                    c.echo_topic(@ptrCast(e.positional.topic), e.count);
                },
                .@"pub" => |p| {
                    c.publish_topic(@ptrCast(p.topic), @ptrCast(p.package), @ptrCast(p.typename), @ptrCast(p.message), p.count);
                },
            }
        },
        .service => |service_cmd| {
            switch (service_cmd.command) {
                .list => c.list_services(),
            }
        },
        .launch => |launch_cmd| {
            const package = launch_cmd.package;
            const script = launch_cmd.script;

            const ament_path = try std.process.getEnvVarOwned(alloc, "AMENT_PREFIX_PATH");
            defer alloc.free(ament_path);

            if (!std.fs.path.isAbsolute(ament_path)) {
                std.debug.print("Error: Invalid AMENT_PREFIX_PATH [{s}]: Not an absolute path\n", .{ament_path});
                return;
            }

            const launch_file = try std.fs.path.join(alloc, &.{ ament_path, "launch", package, script });
            defer alloc.free(launch_file);

            var child = std.process.Child.init(&.{ "/usr/bin/env", "bash", launch_file }, alloc);
            try child.spawn();
            switch (try child.wait()) { // can do something with the exit code if desired
                .Exited => {},
                .Signal => {},
                .Stopped => {},
                .Unknown => {},
            }
        },
        .run => |run_cmd| {
            // ---- Find the binary (ROS node) to run --------------------------

            const node = run_cmd.positional.node;

            const ament_path = try std.process.getEnvVarOwned(alloc, "AMENT_PREFIX_PATH");
            defer alloc.free(ament_path);

            if (!std.fs.path.isAbsolute(ament_path)) {
                logger.err("Invalid AMENT_PREFIX_PATH [{s}]: Not an absolute path", .{ament_path});
                return;
            }

            const binary = try std.fs.path.join(alloc, &.{ ament_path, "bin", node });
            defer alloc.free(binary);

            // ---- Setup the environment for the node -------------------------

            var env_map = try std.process.getEnvMap(alloc);
            defer env_map.deinit();

            // Prepend to the current PATH and LD_LIBRARY_PATH vars
            const PATH = env_map.get("PATH") orelse "/bin";
            const new_path = try std.fmt.allocPrint(alloc, "{s}/bin:{s}", .{ ament_path, PATH });
            defer alloc.free(new_path);
            try env_map.put("PATH", new_path);

            const LD_LIBRARY_PATH = env_map.get("LD_LIBRARY_PATH") orelse "/lib";
            const new_ld_path = try std.fmt.allocPrint(alloc, "{s}/lib:{s}", .{ ament_path, LD_LIBRARY_PATH });
            defer alloc.free(new_ld_path);
            try env_map.put("LD_LIBRARY_PATH", new_ld_path);

            // ---- Configure the command-line arguments for the node ----------

            var argv: std.array_list.Managed([]const u8) = .init(alloc);
            defer argv.deinit();

            try argv.append(node);
            try argv.append("--ros-args");

            const platform = env_map.get("PLATFORM") orelse "default";
            const data_dir = env_map.get("DATA_DIR") orelse "/data";

            const p_platform = try std.fmt.allocPrint(alloc, "platform:={s}", .{platform});
            defer alloc.free(p_platform);

            const p_data_dir = try std.fmt.allocPrint(alloc, "data_dir:={s}", .{data_dir});
            defer alloc.free(p_data_dir);

            const p_default_params_dir = try std.fmt.allocPrint(alloc, "default_params_dir:={s}/params", .{ament_path});
            defer alloc.free(p_default_params_dir);

            const p_override_params_dir = try std.fmt.allocPrint(alloc, "override_params_dir:={s}/params/overrides", .{data_dir});
            defer alloc.free(p_override_params_dir);

            const p_calibration_dir = try std.fmt.allocPrint(alloc, "calibration_dir:={s}/calibration", .{data_dir});
            defer alloc.free(p_calibration_dir);

            // Add all parameter arguments to our argv array
            const param_list: []const []const u8 = &.{ p_platform, p_data_dir, p_default_params_dir, p_override_params_dir, p_calibration_dir };
            for (param_list) |param| {
                try argv.append("-p");
                try argv.append(param);
            }

            // Add the optional user-specified ROS args, if supplied
            // Be sure to split by whitespace!
            if (run_cmd.ros_args) |ros_args| {
                var iter = std.mem.tokenizeScalar(u8, ros_args, ' ');
                while (iter.next()) |arg| {
                    try argv.append(arg);
                }
            }

            const cmd: []const u8 = try std.mem.join(alloc, " ", argv.items);
            defer alloc.free(cmd);
            logger.info("Spawning ROS node with cmd: {s}", .{cmd});

            // Spawn the process
            var child = std.process.Child.init(argv.items, alloc);
            child.env_map = &env_map;
            try child.spawn();

            // Wait for the process to finish; can do something with the exit code if desired
            switch (try child.wait()) {
                .Exited => {},
                .Signal => {},
                .Stopped => {},
                .Unknown => {},
            }
        },
    }
}
