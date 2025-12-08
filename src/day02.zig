const std = @import("std");
const Input = @import("common").Input;
const Allocator = std.mem.Allocator;
const Benchmark = @import("common").Benchmark;

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var input: Input = try .init(allocator, "day02.txt", example);
    const ranges = try parse(allocator, &input);
    defer input.deinit();

    var t1 = bench.add("Day 02 - Part 1");
    var t2 = bench.add("Day 02 - Part 2");

    var arena = std.heap.ArenaAllocator.init(allocator);
    const arena_alloc = arena.allocator();

    std.debug.print("DAY 02\n", .{});
    t1.start();
    const p1 = try part01(arena_alloc, ranges);
    t1.finish();
    _ = arena.reset(.free_all);
    t2.start();
    const p2 = try part02(arena_alloc, ranges);
    t2.finish();

    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{p2});
}

const Range = struct {
    usize,
    usize,
};

fn in_range(self: Range, pattern: usize) bool {
    const start, const end = self;
    return start <= pattern and pattern <= end;
}

fn parse(allocator: Allocator, input: *Input) !std.ArrayList(Range) {
    var ranges = try std.ArrayList(Range).initCapacity(allocator, 72);
    while (try input.reader.interface.takeDelimiter('-')) |left| {
        const trimmed_left = std.mem.trimEnd(u8, left, "\n");
        const trimmed_right = std.mem.trimEnd(u8, (try input.reader.interface.takeDelimiter(',')).?, "\n");

        const start = std.fmt.parseInt(usize, trimmed_left, 10) catch unreachable;
        const end = std.fmt.parseInt(usize, trimmed_right, 10) catch unreachable;

        if (trimmed_left.len != trimmed_right.len) {
            split_ranges(trimmed_left, trimmed_right, &ranges);
        } else {
            ranges.appendAssumeCapacity(.{ start, end });
        }
    }

    return ranges;
}

fn parse_int_unchecked(s: []const u8) usize {
    return std.fmt.parseInt(usize, s, 10) catch unreachable;
}

inline fn highest(len: usize) usize {
    return std.math.pow(usize, 10, len) - 1;
}

inline fn lowest(len: usize) usize {
    return std.math.pow(usize, 10, len - 1);
}

fn split_ranges(right: []const u8, left: []const u8, ranges: *std.ArrayList(Range)) void {
    std.debug.assert(left.len > right.len);
    std.debug.assert(left.len - right.len == 1);

    const r1 = Range{ parse_int_unchecked(right), highest(right.len) };
    const r2 = Range{ lowest(left.len), parse_int_unchecked(left) };
    ranges.appendAssumeCapacity(r1);
    ranges.appendAssumeCapacity(r2);
}

fn part01(allocator: Allocator, ranges: std.ArrayList(Range)) !usize {
    var acc: usize = 0;
    for (ranges.items) |range| {
        acc += do_range(allocator, range, true);
    }
    return acc;
}

fn part02(allocator: Allocator, ranges: std.ArrayList(Range)) !usize {
    var acc: usize = 0;
    for (ranges.items) |range| {
        acc += do_range(allocator, range, false);
    }

    return acc;
}

fn divisors(n: usize, divs: []usize, only_pair: bool) usize {
    const nn: usize = @divTrunc(n, 2) + 1;
    var j: usize = 0;

    if (only_pair) {
        if (n & 1 == 1) {
            return 0;
        }

        divs[0] = n / 2;
        return 1;
    }

    for (1..nn) |i| {
        if (n % i == 0) {
            @branchHint(.likely);
            divs[j] = i;
            j += 1;
            std.debug.assert(j <= divs.len);
        }
    }
    return j;
}

fn repeat(src: usize, n: usize) usize {
    var i: usize = 0;
    const nd = num_digits(src);
    for (0..n) |_| {
        i = i * std.math.pow(usize, 10, nd) + src;
    }

    return i;
}

inline fn num_digits(n: usize) usize {
    return std.math.log10_int(n) + 1;
}

inline fn get_n_digits(elem: usize, n: usize) usize {
    const nd = num_digits(elem);
    return elem / std.math.pow(usize, 10, (nd - n));
}

fn test_patterns(seen: *std.AutoArrayHashMap(usize, bool), div: usize, range: Range) usize {
    const start, const end = range;
    const nd = num_digits(start);
    const pattern_start = get_n_digits(start, div);
    const pattern_end = get_n_digits(end, div);

    var acc: usize = 0;
    for (pattern_start..pattern_end + 1) |pattern| {
        const repeated = repeat(pattern, nd / div);

        if (in_range(range, repeated) and !seen.contains(repeated)) {
            seen.put(repeated, true) catch @panic("OOM");
            acc += repeated;
        }
    }
    return acc;
}

fn do_range(allocator: Allocator, range: Range, only_pair: bool) usize {
    var acc: usize = 0;
    const start, _ = range;

    var div_buffer: [10]usize = undefined;
    const nd = num_digits(start);
    const n_divs = divisors(nd, &div_buffer, only_pair);
    const divs = div_buffer[0..n_divs];

    var seen = std.AutoArrayHashMap(usize, bool).init(allocator);
    defer seen.deinit();

    for (divs) |div| {
        if (only_pair and nd % div > 0) {
            continue;
        }

        acc += test_patterns(&seen, div, range);
    }

    return acc;
}

const expectEqual = std.testing.expectEqual;

test "num digits" {
    try expectEqual(6, num_digits(123123));
    try expectEqual(2, num_digits(99));
    try expectEqual(1, num_digits(9));
    try expectEqual(10, num_digits(1234567890));
}

test "get n digits" {
    try expectEqual(123, get_n_digits(123123, 3));
    try expectEqual(5423452682, get_n_digits(5423452682, 10));
    try expectEqual(5423, get_n_digits(5423452682, 4));
}

test "split range into two" {
    const left = "90";
    const right = "110";
    var ranges = try std.ArrayList(Range).initCapacity(std.testing.allocator, 2);
    defer ranges.deinit(std.testing.allocator);
    split_ranges(left, right, &ranges);
    try expectEqual(2, ranges.items.len);

    try expectEqual(Range{ 90, 99 }, ranges.items[0]);
    try expectEqual(Range{ 100, 110 }, ranges.items[1]);
}

test "highest" {
    try expectEqual(highest(1), 9);
    try expectEqual(highest(2), 99);
    try expectEqual(highest(3), 999);
    try expectEqual(highest(10), 9999999999);
}

test "lowest" {
    try expectEqual(lowest(1), 1);
    try expectEqual(lowest(2), 10);
    try expectEqual(lowest(3), 100);
    try expectEqual(lowest(10), 1000000000);
}

test "divisors" {
    var divs: [20]usize = undefined;

    var n = divisors(9, &divs, false);
    try std.testing.expectEqualSlices(usize, &[_]usize{ 1, 3 }, divs[0..n]);

    n = divisors(90, &divs, false);
    try std.testing.expectEqualSlices(usize, &[_]usize{ 1, 2, 3, 5, 6, 9, 10, 15, 18, 30, 45 }, divs[0..n]);

    n = divisors(2, &divs, false);
    try std.testing.expectEqualSlices(usize, &[_]usize{1}, divs[0..n]);
}

test "partOne" {
    var test_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = test_arena.allocator();
    defer _ = test_arena.reset(.free_all);

    var range = Range{ 11, 22 };
    var result = do_range(allocator, range, true);
    try expectEqual(33, result);

    range = Range{ 95, 99 };
    result = do_range(allocator, range, true);
    try expectEqual(99, result);

    range = Range{ 100, 115 };
    result = do_range(allocator, range, true);
    try expectEqual(0, result);

    range = Range{ 998, 999 };
    result = do_range(allocator, range, true);
    try expectEqual(0, result);

    range = Range{ 1000, 1012 };
    result = do_range(allocator, range, true);
    try expectEqual(1010, result);

    range = Range{ 1188511880, 1188511890 };
    result = do_range(allocator, range, true);
    try expectEqual(1188511885, result);

    range = Range{ 222220, 222224 };
    result = do_range(allocator, range, true);
    try expectEqual(222222, result);

    range = Range{ 1698522, 1698528 };
    result = do_range(allocator, range, true);
    try expectEqual(0, result);

    range = Range{ 446443, 446449 };
    result = do_range(allocator, range, true);
    try expectEqual(446446, result);

    range = Range{ 38593856, 38593862 };
    result = do_range(allocator, range, true);
    try expectEqual(38593859, result);

    range = Range{ 565653, 565659 };
    result = do_range(allocator, range, true);
    try expectEqual(0, result);

    range = Range{ 824824821, 824824827 };
    result = do_range(allocator, range, true);
    try expectEqual(0, result);

    range = Range{ 3081, 5416 };
    result = do_range(allocator, range, true);
    try expectEqual(3131 + 3232 + 3333 + 3434 + 3535 + 3636 + 3737 +
        3838 + 3939 + 4040 + 4141 + 4242 + 4343 + 4444 +
        4545 + 4646 + 4747 + 4848 + 4949 + 5050 + 5151 +
        5252 + 5353, result);
}

test "part two" {
    var test_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = test_arena.allocator();
    defer _ = test_arena.reset(.free_all);

    var range = Range{ 11, 22 };
    var result = do_range(allocator, range, false);
    try expectEqual(33, result);

    range = Range{ 95, 99 };
    result = do_range(allocator, range, false);
    try expectEqual(99, result);

    range = Range{ 100, 115 };
    result = do_range(allocator, range, false);
    try expectEqual(111, result);

    range = Range{ 998, 999 };
    result = do_range(allocator, range, false);
    try expectEqual(999, result);

    range = Range{ 1000, 1012 };
    result = do_range(allocator, range, false);
    try expectEqual(1010, result);

    range = Range{ 1188511880, 1188511890 };
    result = do_range(allocator, range, false);
    try expectEqual(1188511885, result);

    range = Range{ 222220, 222224 };
    result = do_range(allocator, range, false);
    try expectEqual(222222, result);

    range = Range{ 1698522, 1698528 };
    result = do_range(allocator, range, false);
    try expectEqual(0, result);

    range = Range{ 446443, 446449 };
    result = do_range(allocator, range, false);
    try expectEqual(446446, result);

    range = Range{ 38593856, 38593862 };
    result = do_range(allocator, range, false);
    try expectEqual(38593859, result);

    range = Range{ 565653, 565659 };
    result = do_range(allocator, range, false);
    try expectEqual(565656, result);

    range = Range{ 824824821, 824824827 };
    result = do_range(allocator, range, false);
    try expectEqual(824824824, result);

    range = Range{ 3081, 5416 };
    result = do_range(allocator, range, false);
    try expectEqual(3131 + 3232 + 3333 + 3434 + 3535 + 3636 + 3737 +
        3838 + 3939 + 4040 + 4141 + 4242 + 4343 + 4444 +
        4545 + 4646 + 4747 + 4848 + 4949 + 5050 + 5151 +
        5252 + 5353, result);
}

test "final" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer _ = arena.reset(.free_all);

    var input: Input = try .init(allocator, "day02.txt", false);
    defer input.deinit();

    const ranges = try parse(allocator, &input);

    try expectEqual(28146997880, part01(allocator, ranges));
    try expectEqual(40028128307, part02(allocator, ranges));
}
