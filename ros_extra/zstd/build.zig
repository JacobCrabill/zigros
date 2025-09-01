const std = @import("std");
const zigros = @import("../../zigros/zigros.zig");

const Compile = std.Build.Step.Compile;

pub fn buildWithArgs(b: *std.Build, opts: zigros.CompileArgs) *Compile {
    const upstream = b.dependency("zstd", opts);

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
        .pic = true,
    };

    const zstd = b.addLibrary(.{
        .name = "zstd",
        .root_module = b.createModule(std_module_opts),
        .linkage = opts.linkage,
    });

    zstd.addIncludePath(upstream.path("lib/common"));
    zstd.addIncludePath(upstream.path("lib/compress"));
    zstd.addIncludePath(upstream.path("lib/decompress"));
    zstd.addIncludePath(upstream.path("lib/deprecated"));
    zstd.addIncludePath(upstream.path("lib/dictBuilder"));
    zstd.addIncludePath(upstream.path("lib/legacy"));
    zstd.addCSourceFiles(.{
        .root = upstream.path("lib"),
        .files = zstd_common_files ++ zstd_compress_files ++ zstd_decompress_files ++ zstd_deprecated_files ++ zstd_dictBuilder_files ++ zstd_legacy_files,
        .flags = &.{
            "-Oz",
            "-Wall",
            "-Wextra",
            "-Wcast-qual",
            "-Wcast-align",
            "-Wshadow",
            "-Wstrict-aliasing=1",
            "-Wswitch-enum",
            "-Wdeclaration-after-statement",
            "-Wstrict-prototypes",
            "-Wundef",
            "-Wpointer-arith",
            "-Wvla",
            "-Wformat=2",
            "-Winit-self",
            "-Wfloat-equal",
            "-Wwrite-strings",
            "-Wredundant-decls",
            "-Wmissing-prototypes",
            "-Wc++-compat",
            "-DZSTD_DISABLE_ASM=1",
            "-DZSTD_LEGACY_SUPPORT=5",
            "-DZSTD_STRIP_ERROR_STRINGS=1",
            "-fvisibility=default", // HACK
        },
    });
    zstd.installHeadersDirectory(upstream.path("lib"), "", .{ .include_extensions = &.{".h"} });
    b.installArtifact(zstd);

    return zstd;
}

const zstd_common_files: []const []const u8 = &.{
    "common/debug.c",
    "common/entropy_common.c",
    "common/error_private.c",
    "common/fse_decompress.c",
    "common/pool.c",
    "common/threading.c",
    "common/xxhash.c",
    "common/zstd_common.c",
};

const zstd_compress_files: []const []const u8 = &.{
    "compress/fse_compress.c",
    "compress/hist.c",
    "compress/huf_compress.c",
    "compress/zstd_compress.c",
    "compress/zstd_compress_literals.c",
    "compress/zstd_compress_sequences.c",
    "compress/zstd_compress_superblock.c",
    "compress/zstd_double_fast.c",
    "compress/zstd_fast.c",
    "compress/zstd_lazy.c",
    "compress/zstd_ldm.c",
    "compress/zstd_opt.c",
    "compress/zstd_preSplit.c",
    "compress/zstdmt_compress.c",
};

const zstd_decompress_files: []const []const u8 = &.{
    "decompress/huf_decompress.c",
    "decompress/zstd_ddict.c",
    "decompress/zstd_decompress.c",
    "decompress/zstd_decompress_block.c",
    // todo: enable for amd64 targets
    // "decompress/huf_decompress_amd64.S",
};

const zstd_deprecated_files: []const []const u8 = &.{
    "deprecated/zbuff_common.c",
    "deprecated/zbuff_compress.c",
    "deprecated/zbuff_decompress.c",
};

const zstd_dictBuilder_files: []const []const u8 = &.{
    "dictBuilder/cover.c",
    "dictBuilder/divsufsort.c",
    "dictBuilder/fastcover.c",
    "dictBuilder/zdict.c",
};

const zstd_legacy_files: []const []const u8 = &.{
    // "legacy/zstd_v01.c",
    // "legacy/zstd_v02.c",
    // "legacy/zstd_v03.c",
    // "legacy/zstd_v04.c",
    "legacy/zstd_v05.c",
    "legacy/zstd_v06.c",
    "legacy/zstd_v07.c",
};
