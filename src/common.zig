const std = @import("std");
const Allocator = std.mem.Allocator;

const ex = "examples";
const in = "inputs";

pub const Input = struct {
    allocator: Allocator,
    f: std.fs.File,
    reader: std.fs.File.Reader,
    buf: []u8,

    fn path(allocator: Allocator, day: []const u8, example: bool) ![]const u8 {
        const dir = if (example) ex else in;
        return std.fs.path.joinZ(allocator, &[_][]const u8{ dir, day });
    }

    pub fn init(allocator: Allocator, day: []const u8, example: bool) !Input {
        const cwd = std.fs.cwd();
        const p = try path(allocator, day, example);
        defer allocator.free(p);
        const f = try cwd.openFile(p, .{ .mode = .read_only });
        const buf = try allocator.alloc(u8, 512);
        const rdr = f.reader(buf);

        return Input{
            .allocator = allocator,
            .reader = rdr,
            .buf = buf,
            .f = f,
        };
    }

    pub fn deinit(self: *Input) void {
        self.f.close();
        self.allocator.free(self.buf);
    }
};

pub const Timer = struct {
    t: std.time.Timer,
    ended_at: u64,
    name: []const u8,

    pub fn init(name: []const u8) Timer {
        return Timer {
            .name = name,
            .t = undefined,
            .ended_at = 0,
        };
    }

    pub fn start(self: *Timer) void {
        self.t = std.time.Timer.start() catch unreachable;
    }

    pub fn finish(self: *Timer) void {
        self.ended_at = self.t.lap();
        self.t.reset();
    }
};

pub const Benchmark = struct {
    timers: []Timer,
    allocator: Allocator,
    n: usize,

    pub fn init(allocator: Allocator, size: usize) Benchmark {
        return .{
            .allocator = allocator,
            .timers = allocator.alloc(Timer, size) catch unreachable,
            .n = 0,
        };
    }

    pub fn deinit(self: *Benchmark) void {
        self.allocator.free(self.timers);
    }

    pub fn add(self: *Benchmark, name: []const u8) *Timer {
        if (self.n >= self.timers.len) {
            @panic("No more room for timers");
        }

        self.timers[self.n] = .init(name);
        self.n += 1;

        return &self.timers[self.n-1];
    }

    pub fn report(self: *Benchmark) void {
        std.debug.print("Summary ------------------------------------\n", .{});
        for (self.timers) |timer| {
            std.debug.print("{s} - Took {d}μs\n", .{timer.name, timer.ended_at/1000});
        }
        std.debug.print("--------------------------------------------\n", .{});
    }
};
