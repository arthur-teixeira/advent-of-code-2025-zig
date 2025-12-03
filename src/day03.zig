const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;

pub fn solve(allocator: Allocator, example: bool) !void {
    var input: Input = try .init(allocator, "day03.txt", example);
    defer input.deinit();

    const lines = try parse(allocator, &input);
    std.debug.print("DAY 02\n", .{});
    std.debug.print("\tPart 1: {d}\n", .{part01(lines)});
}

fn parse(allocator: Allocator, input: *Input) !std.ArrayList([]u8) {
    var result = try std.ArrayList([]u8).initCapacity(allocator, 200);

    while (try input.reader.interface.takeDelimiter('\n')) |line| {
        result.appendAssumeCapacity(try chars_to_vals(allocator, line));
    } 

    return result;
}

fn chars_to_vals(allocator: Allocator, chars: []const u8) ![]u8 {
    var vals = try allocator.dupe(u8, chars);
    for (0..vals.len) |i| {
        vals[i] = vals[i] - '0';
    }

    return vals;
}

fn solve_line(line: []u8) usize {
    var a: u8 = 0;
    var a_pos: usize = 0;
    for (line[0..line.len - 1], 0..) |v, i| {
        if (v > a) {
            a = v;
            a_pos = i;
        }
    }

    var b: u8 = 0;
    for (line[a_pos+1..]) |v| {
        if (v > b) {
            b = v;
        }
    }

    return 10 * a + b;
}

fn part01(lines: std.ArrayList([]u8)) usize {
    var acc: usize = 0;
    for (lines.items) |line| {
        acc += solve_line(line);
    }

    return acc;
}

const expectEqual = std.testing.expectEqual;
test "day 03" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer _ = arena.reset(.free_all);
    const allocator = arena.allocator();

    try expectEqual(96, solve_line(try chars_to_vals(allocator, "1231591231241513456234")));
    try expectEqual(13, solve_line(try chars_to_vals(allocator, "11111111111113")));
    try expectEqual(31, solve_line(try chars_to_vals(allocator, "111111111111131")));
    try expectEqual(31, solve_line(try chars_to_vals(allocator, "1111111111111231")));
    try expectEqual(23, solve_line(try chars_to_vals(allocator, "211111111111113")));
    try expectEqual(99, solve_line(try chars_to_vals(allocator, "911111111111119")));

}

test "final answer" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer _ = arena.reset(.free_all);
    const allocator = arena.allocator();

    var input: Input = try .init(allocator, "day03.txt", false);
    defer input.deinit();

    const lines = try parse(allocator, &input);
    try expectEqual(17359, part01(lines));
}
