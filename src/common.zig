const std = @import("std");
const Allocator = std.mem.Allocator;

const ex = "examples";
const in = "inputs";

pub const Input = struct {
    allocator: Allocator,
    f: std.fs.File,
    reader: std.fs.File.Reader,
    read_buf: []const u8,

    fn path(allocator: Allocator, day: []const u8, example: bool) ![]const u8 {
        const dir = if (example) ex else in;
        return std.fs.path.joinZ(allocator, &[_][]const u8{ dir, day });
    }

    pub fn init(allocator: Allocator, day: []const u8, example: bool) !Input {
        const cwd = std.fs.cwd();
        const p = try path(allocator, day, example);
        const f = try cwd.openFile(p, .{ .mode = .read_only });
        const stat = try f.stat();

        const buf = try allocator.alloc(u8, stat.size);

        var rdr = f.reader(buf);
        try rdr.interface.fill(stat.size);

        return Input{
            .allocator = allocator,
            .reader = rdr,
            .read_buf = buf,
            .f = f,
        };
    }

    pub fn deinit(self: *Input) void {
        self.f.close();
    }
};
