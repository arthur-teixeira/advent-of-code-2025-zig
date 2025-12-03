const std = @import("std");
const Input = @import("common").Input;
const Allocator = std.mem.Allocator; 
const Benchmark = @import("common").Benchmark;

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

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var input: Input = try .init(allocator, "day01.txt", example);
    const moves = try acc_moves(allocator, &input);
    input.deinit();

    var t1 = bench.add("Day 01 - Part 1");
    var t2 = bench.add("Day 01 - Part 2");

    std.debug.print("DAY 01\n", .{});
    t1.start();
    const p1 = part01(moves);
    t1.finish();
    t2.start();
    const p2 = part02(moves);
    t2.finish();
    std.debug.print("\tPart 1 - {d}\n", .{p1});
    std.debug.print("\tPart 2 - {d}\n", .{p2});
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

    const num_zeroes: i16 = if (round_result <= 0 and acc == 0)
        @divTrunc(-round_result, 100)
    else if (round_result <= 0) 
        @divTrunc(-round_result, 100) + 1
    else 
        @divTrunc(round_result, 100);

    return .{ new_acc, num_zeroes };
}

fn part02(moves: std.ArrayList(i16)) i16 {
    var pos: i16 = 50;
    var count: i16 = 0;

    for (moves.items) |move_value| {
        const new_pos, const num_zeroes = do_round(pos, move_value);
        pos = new_pos;
        count += num_zeroes;
    }

    return count;
}

test "example test" {
    const expectEqual = std.testing.expectEqual;

    // L68
    var round = do_round(50, -68);
    try expectEqual(round[0], 82);
    try expectEqual(round[1], 1);

    // L30
    round = do_round(82, -30);
    try expectEqual(round[0], 52);
    try expectEqual(round[1], 0);
    // R48
    round = do_round(52, 48);
    try expectEqual(round[0], 0);
    try expectEqual(round[1], 1);
    // L5
    round = do_round(0, -5);
    try expectEqual(round[0], 95);
    try expectEqual(round[1], 0);
    // R60
    round = do_round(95, 60);
    try expectEqual(round[0], 55);
    try expectEqual(round[1], 1);
    // L55
    round = do_round(55, -55);
    try expectEqual(round[0], 0);
    try expectEqual(round[1], 1);
    // L1
    round = do_round(0, -1);
    try expectEqual(round[0], 99);
    try expectEqual(round[1], 0);
    // L99
    round = do_round(99, -99);
    try expectEqual(round[0], 0);
    try expectEqual(round[1], 1);
    // R14
    round = do_round(0, 14);
    try expectEqual(round[0], 14);
    try expectEqual(round[1], 0);
    // L82
    round = do_round(14, -82);
    try expectEqual(round[0], 32);
    try expectEqual(round[1], 1);

    round = do_round(50, 1000);
    try expectEqual(round[0], 50);
    try expectEqual(round[1], 10);
}

test "final" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer _ = arena.reset(.free_all);
    const allocator = arena.allocator();
    var input: Input = try .init(allocator, "day01.txt", false);
    defer input.deinit();

    const moves = try acc_moves(allocator, &input);

    try std.testing.expectEqual(1141, part01(moves));
    try std.testing.expectEqual(6634, part02(moves));
}
