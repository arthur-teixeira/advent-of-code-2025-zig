const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;

pub fn solve(allocator: Allocator, example: bool) !void {
    var input: Input = try .init(allocator, "day03.txt", example);
    defer input.deinit();

    const lines = try parse(allocator, &input);
    std.debug.print("DAY 02\n", .{});
    std.debug.print("\tPart 1: {d}\n", .{part01(lines)});
    std.debug.print("\tPart 2: {d}\n", .{part02(lines)});
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

fn solve_line(line: []u8, num_digits: usize) usize {
    std.debug.assert(line.len >= num_digits);

    var acc: usize = 0;
    var last_digit_pos: usize = 0;
    for (0..num_digits) |current_digit| {
        const start = if (current_digit == 0) 0 else last_digit_pos + 1;
        var max: usize = 0;
        var max_pos: usize = 0;

        const cur = line[start..(line.len - (num_digits-current_digit - 1))];
        for (cur, start..) |digit, digit_pos| {
            if (digit > max) {
                max = digit;
                max_pos = digit_pos;
                if (digit == 9) break;
            }
        }

        last_digit_pos = max_pos; 
        acc = (acc * 10) + max;
    }

    return acc;
}

fn part01(lines: std.ArrayList([]u8)) usize {
    var acc: usize = 0;
    for (lines.items) |line| {
        acc += solve_line(line, 2);
    }

    return acc;
}

fn part02(lines: std.ArrayList([]u8)) usize {
    var acc: usize = 0;
    for (lines.items) |line| {
        acc += solve_line(line, 12);
    }

    return acc;
}

const expectEqual = std.testing.expectEqual;
test "day 03 part 1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer _ = arena.reset(.free_all);
    const allocator = arena.allocator();

    try expectEqual(96, solve_line(try chars_to_vals(allocator, "1231591231241513456234"), 2));
    try expectEqual(13, solve_line(try chars_to_vals(allocator, "111111111111113"), 2));
    try expectEqual(31, solve_line(try chars_to_vals(allocator, "111111111111131"), 2));
    try expectEqual(31, solve_line(try chars_to_vals(allocator, "111111111111231"), 2));
    try expectEqual(23, solve_line(try chars_to_vals(allocator, "211111111111113"), 2));
    try expectEqual(99, solve_line(try chars_to_vals(allocator, "911111111111119"), 2));
}

test "day 03 part 2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer _ = arena.reset(.free_all);
    const allocator = arena.allocator();

    try expectEqual(987654321111, solve_line(try chars_to_vals(allocator, "987654321111111"), 12));
    try expectEqual(811111111119, solve_line(try chars_to_vals(allocator, "811111111111119"), 12));
    try expectEqual(434234234278, solve_line(try chars_to_vals(allocator, "234234234234278"), 12));
    try expectEqual(888911112111, solve_line(try chars_to_vals(allocator, "818181911112111"), 12));
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
