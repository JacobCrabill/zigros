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
    pub const description = "Plan paths while avoiding NFZs";

    command: union(enum) {
        node: struct {
            command: union(enum) {
                list: struct {},

                pub const descriptions = .{
                    .list = "List all active nodes",
                };
            },
        },

        topic: struct {
            command: union(enum) {
                list: struct {},
                echo: struct {
                    positional: struct {
                        topic: []const u8,
                        pub const descriptions = .{
                            .topic = "Topic name to echo",
                        };
                    },
                },

                pub const descriptions = .{
                    .list = "List all active topics (subscriptions & publications)",
                    .echo = "Print out all publications on the chosen topic",
                };
            },
        },

        service: struct { command: union(enum) {
            list: struct {},

            pub const descriptions = .{
                .list = "List all active services",
            };
        } },

        pub const descriptions = .{
            .node = "Interact with nodes in the current ROS domain",
            .topic = "Interact with topics in the current ROS domain",
            .service = "Interact with services in the current ROS domain",
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
                    std.debug.print("Echoing topic: {s}\n", .{e.positional.topic});
                    c.echo_topic(@ptrCast(e.positional.topic));
                },
            }
        },
        .service => |service_cmd| {
            switch (service_cmd.command) {
                .list => c.list_services(),
            }
        },
    }
}
