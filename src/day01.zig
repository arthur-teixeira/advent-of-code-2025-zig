const std = @import("std");

fn read_input(file_path: []const u8) !std.fs.File {
    const cwd = std.fs.cwd();
    const f = try cwd.openFile(file_path, .{ .mode = .read_only });
    return f;
}

pub fn day01() {
    const input_file = read_input("./examples/day01.txt");
}
