const std = @import("std");
const zigros = @import("../../../zigros/zigros.zig");
const utils = @import("../../../build_utils.zig");

const Dependency = std.Build.Dependency;
const Module = std.Build.Module;
const Run = std.Build.Step.Run;
const Compile = std.Build.Step.Compile;
const WriteFile = std.Build.Step.WriteFile;
const LazyPath = std.Build.LazyPath;
const CompileArgs = zigros.CompileArgs;
const PythonDep = zigros.PythonDep;

const RosidlGenerator = @This();
const RosidlTypeDescription = @import("RosidlTypeDescription.zig");
const CodeGenerator = @import("RosidlGeneratorTemplate.zig").CodeGenerator;
const RosidlAdapter = @import("RosidlAdapter.zig");

const RosidlGeneratorC = CodeGenerator(
    .c,
    .h,
    &.{
        "{s}/{s}/detail/{s}__description.c",
        "{s}/{s}/detail/{s}__functions.c",
        "{s}/{s}/detail/{s}__type_support.c",
    },
);

const RosidlGeneratorCpp = CodeGenerator(
    .header_only,
    .hpp,
    &.{},
);

const RosidlTypesupportC = CodeGenerator(
    .cpp,
    null,
    &.{"{s}/{s}/{s}__type_support.cpp"},
);

const RosidlTypesupportCpp = CodeGenerator(
    .cpp,
    null,
    &.{"{s}/{s}/{s}__type_support.cpp"},
);

const RosidlTypesupportIntrospectionC = CodeGenerator(
    .c,
    .h,
    &.{"{s}/{s}/detail/{s}__type_support.c"},
);

const RosidlTypesupportIntrospectionCpp = CodeGenerator(
    .cpp,
    null,
    &.{"{s}/{s}/detail/{s}__type_support.cpp"},
);

const RosidlTypesupportFastrtpsC = CodeGenerator(
    .c,
    .h,
    // &.{"{s}/{s}/detail/dds_fastrtps/{s}__type_support.c"},
    &.{"{s}/{s}/detail/{s}__type_support_c.cpp"},
);

const RosidlTypesupportFastrtpsCpp = CodeGenerator(
    .cpp,
    .h,
    &.{"{s}/{s}/detail/dds_fastrtps/{s}__type_support.cpp"},
);

pub const Interface = struct {
    package_name: []const u8,
    write_files: *WriteFile,
    share: LazyPath,
    /// Some interfaces also have C/C++ headers associated with them that might be needed downstream
    include_dir: ?LazyPath = null,
    interface_c: *Compile,
    interface_cpp: LazyPath,
    typesupport_c: *Compile,
    typesupport_cpp: *Compile,
    typesupport_introspection_c: *Compile,
    typesupport_introspection_cpp: *Compile,
    // TODO: Have a list of C and CPP typesupport libs for RMW's that can be
    // registered by the RMW's builder rather than hard-coded here?
    typesupport_fastrtps_c: *Compile,
    typesupport_fastrtps_cpp: *Compile,

    pub fn stepLink(self: Interface, target: *Compile) void {
        self.linkC(target.root_module);
        self.linkCpp(target.root_module);
    }

    pub fn stepLinkC(self: Interface, target: *Compile) void {
        self.linkC(target.root_module);
    }

    pub fn stepLinkCpp(self: Interface, target: *Compile) void {
        self.linkCpp(target.root_module);
    }

    /// Link the 'target' to this interface's libraries
    pub fn link(self: Interface, target: *Module) void {
        self.linkC(target);
        self.linkCpp(target);
    }

    /// Link 'target' against only the c libraries. In theory useful for rcl only builds.
    /// though all rmw implementations require c++ so in practice not that useful
    pub fn linkC(self: Interface, target: *Module) void {
        target.linkLibrary(self.interface_c);
        target.linkLibrary(self.typesupport_c);
        target.linkLibrary(self.typesupport_introspection_c);
        // TODO: might not want to direclty link this, since RMW will call dlopen()?
        target.linkLibrary(self.typesupport_fastrtps_c);

        if (self.include_dir) |dir| {
            target.addIncludePath(dir);
        }
    }

    // Note this function should only be used if linkC has been called previously
    // on the same module, otherwise the standard link function should be used.
    // Use the normal public link function for general c++ linking
    pub fn linkCpp(self: Interface, target: *Module) void {
        target.linkLibrary(self.typesupport_cpp);
        target.linkLibrary(self.typesupport_introspection_cpp);
        // TODO: might not want to direclty link this, since RMW will call dlopen()?
        target.linkLibrary(self.typesupport_fastrtps_cpp);

        // --------------------------------------------------------------------
        // TODO: I can't win either way - either we get undefined symbols, or we get the
        // 'foo.so is neither ET_REL nor LLVM bitcode' error
        // UPDATE: This is actually a minor Zig bug: https://github.com/ziglang/zig/issues/19341
        // The lld warnings are just that - warnings - and can safely be ignored for now, as annoying as they are.
        // --------------------------------------------------------------------
        // if (target.kind == .exe or (target.linkage != null and target.linkage.? == .dynamic)) {
        //     target.linkLibrary(foo);
        // } else {
        //     target.addIncludePath(foo.getEmittedIncludeTree());
        // }

        target.addIncludePath(self.interface_cpp);
        if (self.include_dir) |dir| {
            target.addIncludePath(dir);
        }
    }

    /// Install all libraries from this Interface to the given Builder
    pub fn installArtifacts(self: *const Interface, b: *std.Build) void {
        b.installArtifact(self.interface_c);
        b.installArtifact(self.typesupport_c);
        b.installArtifact(self.typesupport_cpp);
        b.installArtifact(self.typesupport_introspection_c);
        b.installArtifact(self.typesupport_introspection_cpp);
        b.installArtifact(self.typesupport_fastrtps_c);
        b.installArtifact(self.typesupport_fastrtps_cpp);

        // Install the .msg and .idl files to <install prefix>/share/<package_name>
        b.installDirectory(.{
            .source_dir = self.write_files.getDirectory(),
            .install_dir = .{ .custom = "share" },
            .install_subdir = self.package_name,
            .include_extensions = &.{ ".msg", ".srv", ".action", ".idl" },
        });

        // Also write package.xml and ament_index files for the package
        utils.writeAmentPackageIndexFile(b, self.package_name);
        utils.writeAmentPackageXml(b, self.package_name);

        // The resource index must also list all .msg and .idl files from the package
        var files = std.ArrayList([]const u8).initCapacity(b.allocator, self.write_files.files.items.len) catch @panic("OOM");
        var idl_files = std.ArrayList([]const u8).initCapacity(b.allocator, self.write_files.files.items.len) catch @panic("OOM");
        defer files.deinit(b.allocator);
        defer {
            for (idl_files.items) |file| {
                b.allocator.free(file);
            }
            idl_files.deinit(b.allocator);
        }

        for (self.write_files.files.items) |file| {
            const file_name = file.sub_path;
            // add the .msg/.srv file
            files.appendAssumeCapacity(file.sub_path);

            // add the .idl file
            const idx = std.mem.lastIndexOfScalar(u8, file_name, '.') orelse @panic("rosmsg file name doesn't end in .msg, .srv, or .action?");
            const file_minus_ext = file_name[0..idx];
            const idl_name = b.fmt("{s}.idl", .{file_minus_ext});
            idl_files.appendAssumeCapacity(idl_name);
        }
        const resource_content_msg: []const u8 = std.mem.join(b.allocator, "\n", files.items) catch @panic("OOM");
        defer b.allocator.free(resource_content_msg);
        const resource_content_idl: []const u8 = std.mem.join(b.allocator, "\n", idl_files.items) catch @panic("OOM");
        defer b.allocator.free(resource_content_idl);
        const resource_content = b.fmt("{s}\n{s}\n", .{ resource_content_msg, resource_content_idl });
        defer b.allocator.free(resource_content);

        utils.writeAmentResourceIndexFile(b, "rosidl_interfaces", self.package_name, resource_content);
    }
};

pub const BuildDeps = struct {
    python: PythonDep,
    empy: ?LazyPath, // Required when non system python is used
    lark: ?LazyPath, // Required when non system python is used
    rosidl_cli: LazyPath,
    rosidl_adapter: LazyPath,
    rosidl_parser: LazyPath,
    rosidl_pycommon: LazyPath,
    rosidl_generator_type_description: LazyPath,
    rosidl_generator_c: LazyPath,
    rosidl_generator_cpp: LazyPath,
    rosidl_typesupport_c: LazyPath,
    rosidl_typesupport_cpp: LazyPath,
    rosidl_typesupport_introspection_c: LazyPath,
    rosidl_typesupport_introspection_cpp: LazyPath,
    rosidl_typesupport_fastrtps_c: LazyPath,
    rosidl_typesupport_fastrtps_cpp: LazyPath,
    type_description_generator: *Compile,
    adapter_generator: *Compile,
    code_generator: *Compile,
};

pub const Deps = struct {
    rosidl_runtime_c: *Compile,
    rosidl_runtime_cpp: LazyPath,
    rosidl_typesupport_interface: LazyPath,
    rosidl_typesupport_c: *Compile,
    rosidl_typesupport_cpp: *Compile,
    rosidl_typesupport_introspection_c: *Compile,
    rosidl_typesupport_introspection_cpp: *Compile,
    rcutils: *Compile,
    // TODO: Add a way to add RMW-specific extras
    rosidl_typesupport_fastrtps_c: *Compile,
    rosidl_typesupport_fastrtps_cpp: *Compile,
    fastcdr: *Compile,
};

owner: *std.Build,
package_name: []const u8,
deps: Deps,
build_deps: BuildDeps,
artifacts: Interface,
share_dir: *WriteFile,
adapter: *RosidlAdapter,
type_description: *RosidlTypeDescription,
generator_c: *RosidlGeneratorC,
generator_cpp: *RosidlGeneratorCpp,
typesupport_c: *RosidlTypesupportC,
typesupport_cpp: *RosidlTypesupportCpp,
typesupport_introspection_c: *RosidlTypesupportIntrospectionC,
typesupport_introspection_cpp: *RosidlTypesupportIntrospectionCpp,
typesupport_fastrtps_c: *RosidlTypesupportFastrtpsC,
typesupport_fastrtps_cpp: *RosidlTypesupportFastrtpsCpp,
dependency: Dependency,

pub fn create(
    b: *std.Build,
    package_name: []const u8,
    deps: Deps,
    build_deps: BuildDeps,
    compile_args: CompileArgs,
) *RosidlGenerator {
    const to_return = b.allocator.create(RosidlGenerator) catch @panic("OOM");
    to_return.* = .{
        .owner = b,
        .package_name = b.dupe(package_name),
        .deps = deps,
        .build_deps = build_deps,
        .artifacts = undefined,
        .share_dir = b.addNamedWriteFiles(package_name),
        .adapter = undefined,
        .type_description = undefined,
        .generator_c = undefined,
        .generator_cpp = undefined,
        .typesupport_c = undefined,
        .typesupport_cpp = undefined,
        .typesupport_introspection_c = undefined,
        .typesupport_introspection_cpp = undefined,
        .typesupport_fastrtps_c = undefined,
        .typesupport_fastrtps_cpp = undefined,
        .dependency = .{ .builder = b },
    };

    const static_args = CompileArgs{
        .target = compile_args.target,
        .optimize = compile_args.optimize,
        .linkage = compile_args.linkage, //.static,
        .strip = compile_args.strip,
    };

    const dynamic_args = CompileArgs{
        .target = compile_args.target,
        .optimize = compile_args.optimize,
        .strip = compile_args.strip,
        .linkage = .dynamic,
    };

    to_return.adapter = RosidlAdapter.create(b, build_deps, package_name);
    _ = to_return.share_dir.addCopyDirectory(
        to_return.adapter.output,
        "",
        .{ .include_extensions = &.{".idl"} },
    );

    to_return.type_description = RosidlTypeDescription.create(b, build_deps, package_name);
    _ = to_return.share_dir.addCopyDirectory(
        to_return.type_description.output,
        "",
        .{ .include_extensions = &.{".json"} },
    );

    to_return.generator_c = RosidlGeneratorC.create(
        b,
        package_name,
        static_args,
        "rosidl_generator_c",
        build_deps.rosidl_generator_c,
        deps,
        build_deps,
        &.{.{ .lib = deps.rosidl_runtime_c }},
        null,
    );
    to_return.generator_cpp = RosidlGeneratorCpp.create(
        b,
        package_name,
        static_args,
        "rosidl_generator_cpp",
        build_deps.rosidl_generator_cpp,
        deps,
        build_deps,
        null,
        &.{build_deps.rosidl_generator_c},
    );

    to_return.typesupport_introspection_c = RosidlTypesupportIntrospectionC.create(
        b,
        package_name,
        dynamic_args,
        "rosidl_typesupport_introspection_c",
        build_deps.rosidl_typesupport_introspection_c,
        deps,
        build_deps,
        &.{
            .{ .lib = deps.rosidl_runtime_c },
            .{ .lib = deps.rosidl_typesupport_introspection_c },
            .{ .lib = to_return.generator_c.artifact },
        },
        &.{build_deps.rosidl_generator_c},
    );

    to_return.typesupport_introspection_cpp = RosidlTypesupportIntrospectionCpp.create(
        b,
        package_name,
        dynamic_args,
        "rosidl_typesupport_introspection_cpp",
        build_deps.rosidl_typesupport_introspection_cpp,
        deps,
        build_deps,
        &.{
            .{ .lib = deps.rosidl_runtime_c },
            .{ .header_only = deps.rosidl_runtime_cpp },
            .{ .lib = deps.rosidl_typesupport_introspection_cpp },
            .{ .lib = deps.rosidl_typesupport_cpp },
            .{ .lib = to_return.generator_c.artifact },
            .{ .header_only = to_return.generator_cpp.artifact.getDirectory() },
            .{ .lib = deps.rosidl_typesupport_introspection_c },
        },
        &.{
            build_deps.rosidl_generator_c,
            build_deps.rosidl_generator_cpp,
        },
    );

    to_return.typesupport_fastrtps_c = RosidlTypesupportFastrtpsC.create(
        b,
        package_name,
        dynamic_args,
        "rosidl_typesupport_fastrtps_c",
        build_deps.rosidl_typesupport_fastrtps_c,
        deps,
        build_deps,
        &.{
            .{ .lib = deps.rosidl_runtime_c },
            .{ .header_only = deps.rosidl_runtime_cpp },
            .{ .lib = deps.fastcdr },
            .{ .lib = deps.rosidl_typesupport_cpp },
            .{ .lib = deps.rosidl_typesupport_fastrtps_c },
            .{ .lib = deps.rosidl_typesupport_fastrtps_cpp },
            .{ .lib = to_return.generator_c.artifact },
        },
        &.{
            build_deps.rosidl_generator_c,
            build_deps.rosidl_generator_cpp,
        },
    );

    to_return.typesupport_fastrtps_cpp = RosidlTypesupportFastrtpsCpp.create(
        b,
        package_name,
        dynamic_args,
        "rosidl_typesupport_fastrtps_cpp",
        build_deps.rosidl_typesupport_fastrtps_cpp,
        deps,
        build_deps,
        &.{
            .{ .header_only = deps.rosidl_runtime_cpp },
            .{ .header_only = to_return.generator_cpp.artifact.getDirectory() },
            .{ .lib = to_return.generator_c.artifact },
            .{ .lib = deps.rosidl_runtime_c },
            .{ .lib = deps.rosidl_typesupport_cpp },
            .{ .lib = deps.fastcdr },
            .{ .lib = deps.rosidl_typesupport_fastrtps_c },
            .{ .lib = deps.rosidl_typesupport_fastrtps_cpp },
        },
        &.{
            build_deps.rosidl_generator_c,
            build_deps.rosidl_generator_cpp,
        },
    );

    to_return.typesupport_c = RosidlTypesupportC.create(
        b,
        package_name,
        dynamic_args,
        "rosidl_typesupport_c",
        build_deps.rosidl_typesupport_c,
        deps,
        build_deps,
        &.{
            .{ .lib = deps.rosidl_runtime_c },
            .{ .lib = to_return.generator_c.artifact },
            .{ .lib = deps.rosidl_typesupport_c },
            // Note that when building single type support, you must link the type support package
            // directly against that single type support.
            .{ .lib = to_return.typesupport_introspection_c.artifact },
        },
        &.{build_deps.rosidl_generator_c},
    );

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
    // TODO: Enable individual typesupports to be added (or not) based on the chosen RMW.
    // This includes linking the required typesupport libraries, and _only_ the required
    // typesupport libraries.
    // Will likely need to create a somewhat generic TypeSupport wrapper that contains one
    // or more RosidlGenerator's to generate its library(s), that then gets added to each
    // high-level "Interface" like 'std_msgs'.
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1

    // The type supports normally come from the ament index. Search for
    // `ament_index_register_resource("rosidl_typesupport_c`) on github in ros to get a list
    // For now we only support the standard dynamic typesupport_introspection versions
    to_return.typesupport_c.generator.addArg(
        "-A--typesupports rosidl_typesupport_introspection_c rosidl_typesupport_fastrtps_c",
    );

    to_return.typesupport_cpp = RosidlTypesupportCpp.create(
        b,
        package_name,
        dynamic_args,
        "rosidl_typesupport_cpp",
        build_deps.rosidl_typesupport_cpp,
        deps,
        build_deps,
        &.{
            .{ .lib = deps.rosidl_runtime_c },
            .{ .lib = to_return.generator_c.artifact },
            .{ .header_only = to_return.generator_cpp.artifact.getDirectory() },
            .{ .header_only = deps.rosidl_runtime_cpp },
            .{ .lib = deps.rosidl_typesupport_cpp },
            // Note that when building single type support, you must link the type support package
            // directly against that single type support.
            .{ .lib = to_return.typesupport_introspection_cpp.artifact },
            .{ .lib = deps.rosidl_typesupport_introspection_cpp },
        },
        &.{build_deps.rosidl_generator_c},
    );

    // The type supports normally come from the ament index. Search for
    // `ament_index_register_resource("rosidl_typesupport_c`) on github in ros to get a list
    // For now we only support the standard dynamic typesupport_introspection versions
    to_return.typesupport_cpp.generator.addArg(
        "-A--typesupports rosidl_typesupport_introspection_cpp rosidl_typesupport_fastrtps_cpp",
    );

    to_return.artifacts = Interface{
        .package_name = package_name,
        .write_files = to_return.share_dir,
        .share = to_return.share_dir.getDirectory(),
        .interface_c = to_return.generator_c.artifact,
        .interface_cpp = to_return.generator_cpp.artifact.getDirectory(),
        .typesupport_c = to_return.typesupport_c.artifact,
        .typesupport_cpp = to_return.typesupport_cpp.artifact,
        .typesupport_introspection_c = to_return.typesupport_introspection_c.artifact,
        .typesupport_introspection_cpp = to_return.typesupport_introspection_cpp.artifact,
        .typesupport_fastrtps_c = to_return.typesupport_fastrtps_c.artifact,
        .typesupport_fastrtps_cpp = to_return.typesupport_fastrtps_cpp.artifact,
    };

    return to_return;
}

pub fn addInterfaces(
    self: *RosidlGenerator,
    base_path: std.Build.LazyPath,
    files: []const []const u8,
) void {
    for (files) |file| {
        self.adapter.addInterface(base_path, file);

        const ext_idx = std.mem.lastIndexOfScalar(u8, file, '.') orelse @panic("Invalid interface file name!");
        const file_minus_ext = file[0 .. ext_idx + 1];

        const b: *std.Build = self.owner;

        const idl = b.fmt("{s}idl", .{file_minus_ext});

        self.type_description.addIdlTuple(idl, self.adapter.output);

        const type_description = b.fmt("{s}json", .{file_minus_ext});

        self.generator_c.addInterface(base_path, file);
        self.generator_c.addIdlTuple(idl, self.adapter.output);
        self.generator_c.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.generator_cpp.addInterface(base_path, file);
        self.generator_cpp.addIdlTuple(idl, self.adapter.output);
        self.generator_cpp.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.typesupport_introspection_c.addInterface(base_path, file);
        self.typesupport_introspection_c.addIdlTuple(idl, self.adapter.output);
        self.typesupport_introspection_c.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.typesupport_introspection_cpp.addInterface(base_path, file);
        self.typesupport_introspection_cpp.addIdlTuple(idl, self.adapter.output);
        self.typesupport_introspection_cpp.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.typesupport_c.addInterface(base_path, file);
        self.typesupport_c.addIdlTuple(idl, self.adapter.output);
        self.typesupport_c.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.typesupport_cpp.addInterface(base_path, file);
        self.typesupport_cpp.addIdlTuple(idl, self.adapter.output);
        self.typesupport_cpp.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.typesupport_fastrtps_c.addInterface(base_path, file);
        self.typesupport_fastrtps_c.addIdlTuple(idl, self.adapter.output);
        self.typesupport_fastrtps_c.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        self.typesupport_fastrtps_cpp.addInterface(base_path, file);
        self.typesupport_fastrtps_cpp.addIdlTuple(idl, self.adapter.output);
        self.typesupport_fastrtps_cpp.addTypeDescription(
            idl,
            self.type_description.output.path(self.owner, type_description),
        );

        const path = base_path.path(self.owner, file);
        _ = self.share_dir.addCopyFile(path, file);
    }
}

/// Add an Interface as a dependency for this RosidlGenerator
pub fn addDependency(self: *RosidlGenerator, name: []const u8, dependency: Interface) void {
    self.type_description.addIncludePath(name, dependency.share);

    dependency.stepLinkC(self.generator_c.artifact);
    dependency.stepLinkC(self.typesupport_c.artifact);
    dependency.stepLinkC(self.typesupport_introspection_c.artifact);
    dependency.stepLinkC(self.typesupport_fastrtps_c.artifact);

    dependency.stepLink(self.typesupport_cpp.artifact);
    dependency.stepLink(self.typesupport_introspection_cpp.artifact);
    dependency.stepLink(self.typesupport_fastrtps_cpp.artifact);
}

const PythonArguments = union(enum) {
    string: []const u8,
    lazy_path: std.Build.LazyPath,
};

pub fn installArtifacts(self: *RosidlGenerator) void {
    var b = self.owner;

    b.installArtifact(self.generator_c.artifact);

    b.installDirectory(.{
        .source_dir = self.generator_cpp.artifact.getDirectory(),
        .install_dir = .header,
        .install_subdir = "",
    });

    b.installArtifact(self.typesupport_c.artifact);
    b.installArtifact(self.typesupport_cpp.artifact);
    b.installArtifact(self.typesupport_introspection_c.artifact);
    b.installArtifact(self.typesupport_introspection_cpp.artifact);
    b.installArtifact(self.typesupport_fastrtps_c.artifact);
    b.installArtifact(self.typesupport_fastrtps_cpp.artifact);
}
