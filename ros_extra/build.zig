const std = @import("std");
const zr = @import("zigros");
const utils = @import("../build_utils.zig");

pub const cv_bridge = @import("cv_bridge/build.zig");
pub const dynmsg = @import("dynmsg/build.zig");
pub const mavlink = @import("mavlink/build.zig");
pub const gtest = @import("gtest/build.zig");
pub const image_transport = @import("image_transport/build.zig");
pub const camera_info = @import("camera_info_manager/build.zig");
pub const class_loader = @import("class_loader/build.zig");
pub const tinyxml2 = @import("tinyxml2/build.zig");
pub const console_bridge = @import("console_bridge/build.zig");
pub const pluginlib = @import("pluginlib/build.zig");
pub const message_filters = @import("message_filters/build.zig");
pub const tf2 = @import("tf2/build.zig");
pub const geographic = @import("geographic/build.zig");

pub const BuildOpts = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode,
    strip: bool,
};
