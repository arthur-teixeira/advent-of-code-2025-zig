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

fn acc_moves(allocator: Allocator, input: *Input) !std.ArrayList(i16) {
    var moves = try std.ArrayList(i16).initCapacity(allocator, 4532); // pre allocate known number of lines for main input 
    while (input.reader.interface.takeDelimiter('\n')) |line| {
        if (line == null) {
            break;
        }
        const line_move = try parse_line(line.?);
        moves.appendAssumeCapacity(line_move);
    } else |err| return err;

    return moves;
}

pub fn solve(allocator: Allocator, example: bool) !void {
    var input: Input = try .init(allocator, "day01.txt", example);
    defer input.deinit();

    const moves = try acc_moves(allocator, &input);

    std.debug.print("Part 1 - {d}\n", .{part01(moves)});
    std.debug.print("Part 2 - {d}\n", .{part02(moves)});
}

fn part01(moves: std.ArrayList(i16)) i16 {
    var pos: i16 = 50;
    var count: i16 = 0;
    for (moves.items) |move_value| {
        pos = move(pos, move_value);
        if (pos == 0) {
            count += 1;
        }
    }

    return count;
}

const Round = struct { i16, i16 };

fn do_round(acc: i16, val: i16) Round {
    const round_result = acc + val;
    const new_acc = @mod(round_result, 100);


    const num_zeroes: i16 = if (round_result <= 0 and acc != 0)
        @divTrunc(-round_result, 100) + 1
    else if (round_result >= 100)
        @divTrunc(round_result, 100)
    else if (new_acc == 0) 
        1
    else 
        0;

    return .{ new_acc, num_zeroes };
}

fn part02(moves: std.ArrayList(i16)) i16 {
    var pos: i16 = 50;
    var count: i16 = 0;

    for (moves.items) |move_value| {
        const new_pos, const num_zeroes = do_round(pos, move_value);
        std.debug.print("Moving from {d} by {d}, got to {d} passing 0 {d} times\n", .{pos, move_value, new_pos, num_zeroes});
        pos = new_pos;
        count += num_zeroes;
    }

    return count;
}

test "example test" {
    const expect = std.testing.expect;

    // L68
    var round = do_round(50, -68);
    try expect(round[0] == 82);
    try expect(round[1] == 1);

    // L30
    round = do_round(82, -30);
    try expect(round[0] == 52);
    try expect(round[1] == 0);
    // R48
    round = do_round(52, 48);
    try expect(round[0] == 0);
    try expect(round[1] == 1);
    // L5
    round = do_round(0, -5);
    try expect(round[0] == 95);
    try expect(round[1] == 0);
    // R60
    round = do_round(95, 60);
    try expect(round[0] == 55);
    try expect(round[1] == 1);
    // L55
    round = do_round(55, -55);
    try expect(round[0] == 0);
    try expect(round[1] == 1);
    // L1
    round = do_round(0, -1);
    try expect(round[0] == 99);
    try expect(round[1] == 0);
    // L99
    round = do_round(99, -99);
    try expect(round[0] == 0);
    try expect(round[1] == 1);
    // R14
    round = do_round(0, 14);
    try expect(round[0] == 14);
    try expect(round[1] == 0);
    // L82
    round = do_round(14, -82);
    try expect(round[0] == 32);
    try expect(round[1] == 1);

    round = do_round(50, 1000);
    try expect(round[0] == 50);
    try expect(round[1] == 10);
}
