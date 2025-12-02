const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod_day_01 = b.addModule("day01", .{
        .root_source_file = b.path("src/day01.zig"),
        .target = target,
    });

    const mod_common = b.addModule("common", .{
        .root_source_file = b.path("src/common.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "advent_of_code_2025_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "day01", .module = mod_day_01 },
                .{ .name = "common", .module = mod_common },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
