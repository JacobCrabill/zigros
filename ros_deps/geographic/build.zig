const std = @import("std");

const utils = @import("../../build_utils.zig");
const zigros = @import("../../zigros/zigros.zig");

const native_endian = @import("builtin").target.cpu.arch.endian();

const Compile = std.Build.Step.Compile;

pub fn buildWithArgs(b: *std.Build, opts: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("geographic", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .link_libcpp = true,
    };

    const geographic = b.addLibrary(.{
        .name = "geographic",
        .root_module = b.createModule(std_module_opts),
        .linkage = .static,
    });

    const is_bigendian: u8 = if (native_endian == .big) 1 else 0;
    const is_shared: u8 = if (opts.linkage == .dynamic) 1 else 0;

    const config_h = b.addConfigHeader(
        .{
            .style = .{ .cmake = upstream.path("include/GeographicLib/Config.h.in") },
            .include_path = "GeographicLib/Config.h",
        },
        .{
            .PROJECT_VERSION = "2.5",
            .PROJECT_VERSION_MAJOR = 2,
            .PROJECT_VERSION_MINOR = 5,
            .PROJECT_VERSION_PATCH = 0,
            .GEOGRAPHICLIB_DATA = "/usr/local/share/GeographicLib",
            .GEOGRAPHICLIB_HAVE_LONG_DOUBLE = 0,
            .GEOGRAPHICLIB_WORDS_BIGENDIAN = is_bigendian,
            .GEOGRAPHICLIB_PRECISION = 2, // normal double precision
            .GEOGRAPHICLIB_LIB_TYPE_VAL = is_shared,
        },
    );
    geographic.addConfigHeader(config_h);
    geographic.installConfigHeader(config_h);

    geographic.addIncludePath(upstream.path("include/"));
    geographic.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = geographiclib_sources,
        .flags = &.{
            "--std=c++17",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-DGEOGRAPHICLIB_PRECISION=2",
            b.fmt("-DGEOGRAPHICLIB_WORDS_BIGENDIAN={d}", .{is_bigendian}),
            "-DGEOGRAPHICLIB_HAVE_LONG_DOUBLE=1",
        },
    });

    geographic.installHeadersDirectory(upstream.path("include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });
    b.installArtifact(geographic);

    return geographic;
}

const geographiclib_sources = &.{
    "Accumulator.cpp",
    "AlbersEqualArea.cpp",
    "AuxAngle.cpp",
    "AuxLatitude.cpp",
    "AzimuthalEquidistant.cpp",
    "CassiniSoldner.cpp",
    "CircularEngine.cpp",
    "DAuxLatitude.cpp",
    "DMS.cpp",
    "DST.cpp",
    "Ellipsoid.cpp",
    "EllipticFunction.cpp",
    "GARS.cpp",
    "GeoCoords.cpp",
    "Geocentric.cpp",
    "Geodesic.cpp",
    "GeodesicExact.cpp",
    "GeodesicLine.cpp",
    "GeodesicLineExact.cpp",
    "Geohash.cpp",
    "Geoid.cpp",
    "Georef.cpp",
    "Gnomonic.cpp",
    "GravityCircle.cpp",
    "GravityModel.cpp",
    "Intersect.cpp",
    "LambertConformalConic.cpp",
    "LocalCartesian.cpp",
    "MGRS.cpp",
    "MagneticCircle.cpp",
    "MagneticModel.cpp",
    "Math.cpp",
    "NormalGravity.cpp",
    "OSGB.cpp",
    "PolarStereographic.cpp",
    "PolygonArea.cpp",
    "Rhumb.cpp",
    "SphericalEngine.cpp",
    "TransverseMercator.cpp",
    "TransverseMercatorExact.cpp",
    "UTMUPS.cpp",
    "Utility.cpp",
};
