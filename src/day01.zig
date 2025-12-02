const std = @import("std");
const Input = @import("common").Input;
const Allocator = std.mem.Allocator; 


fn parse_line(line: []const u8) !i16 {
    const mul: i16 = if (line[0] == 'L') -1 else 1;
    const val = try std.fmt.parseInt(i16, line[1..], 10);

    return mul * val;
}

fn move(acc: i16, val: i16) i16 {
    return @mod(acc + val, 100);
}

pub fn solve(allocator: Allocator, example: bool) !void {
    var example_input: Input = try .init(allocator, "day01.txt", example);
    defer example_input.deinit();

    var pos: i16 = 50;
    var count: isize = 0;
    while (example_input.reader.interface.takeDelimiter('\n')) |line| {
        if (line == null) {
            break;
        }
        const line_move = try parse_line(line.?);
        pos = move(pos, line_move);
        if (pos == 0) {
            count += 1;
        }
    } else |err| return err;

    std.debug.print("Part 1 - {d}\n", .{count});
}
