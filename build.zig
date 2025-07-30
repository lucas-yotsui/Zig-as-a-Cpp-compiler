const std = @import("std");
// const zcc = @import("compile_commands");

const PROJECT_NAME = "your_project";

const SOURCE_FILES: []const []const u8 = &.{
    // Add all the .cpp files you want to compile here
    "src/main.cpp",
};

const FLAGS: []const []const u8 = &.{
    "-std=c++23", // Or any other C++ version you want
    
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    "-Wconversion",
    "-Wdeprecated",
    "-Wcast-align",
    "-Wdouble-promotion",
    "-Wimplicit-fallthrough",
    "-Wmisleading-indentation",
    "-Wnon-virtual-dtor",
    "-Wnull-dereference",
    "-Wold-style-cast",
    "-Woverloaded-virtual",
    "-Wshadow",
    "-Wundef",
    "-Wuninitialized",

    "-Werror", // If there's a warning, it's probably best to solve it. Therefore, it's now mandatory
};

const targets: []const std.Target.Query = &.{
    std.Target.Query{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .msvc },
    std.Target.Query{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });
    // var executables = std.ArrayList(*std.Build.Step.Compile).init(b.allocator);
    // defer executables.deinit();

    for (targets) |target| {
        const exe = b.addExecutable(.{
            .name = PROJECT_NAME,
            .target = b.resolveTargetQuery(target),
            .optimize = optimize,
            .linkage = .static,
            .strip = b.release_mode != .off,
        });
        exe.linkLibCpp();
        exe.addIncludePath(.{ .cwd_relative = "inc" });
        exe.addCSourceFiles(.{
            .files = SOURCE_FILES,
            .flags = FLAGS,
        });

        const output = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = try target.zigTriple(b.allocator),
                },
            },
        });
        b.getInstallStep().dependOn(&output.step);

        // executables.append(exe) catch @panic("OOM!");
    }

    // const create_compile_commands = zcc.createStep(b, "cdb", executables.toOwnedSlice() catch @panic("OOM!"));
    // b.default_step.dependOn(create_compile_commands);
}
