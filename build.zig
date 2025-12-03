const std = @import("std");

pub fn dayModule(b: *std.Build, target: std.Build.ResolvedTarget, common: *std.Build.Module, day: usize) *std.Build.Module {
    const dayname = b.fmt("day{d:0>2}", .{day});
    const path = b.fmt("src/day{d:0>2}.zig", .{day});

    return b.addModule(dayname, .{
        .root_source_file = b.path(path),
        .target = target,
        .imports = &.{
            .{ .name = "common", .module = common },
        }
    });
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod_common = b.addModule("common", .{
        .root_source_file = b.path("src/common.zig"),
        .target = target,
    });

    const days = 3;

    var imports: [days+1]std.Build.Module.Import = undefined;
    imports[0] = .{ .name = "common", .module = mod_common };
    const test_step = b.step("test", "Run tests");

    for (1..days+1) |day| {
        const dayname = b.fmt("day{d:0>2}", .{day});
        const module = dayModule(b, target, mod_common, day);
        imports[day] = .{ .name = dayname, .module = module };

        const day_tests = b.addTest(.{
            .root_module = module,
        });

        const run_tests = b.addRunArtifact(day_tests);
        test_step.dependOn(&run_tests.step);
    }

    const exe = b.addExecutable(.{
        .name = "advent_of_code_2025_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &imports,
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
