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
