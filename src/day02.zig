const std = @import("std");
const Input = @import("common").Input;
const Allocator = std.mem.Allocator;

pub fn solve(allocator: Allocator, example: bool) !void {
    var input: Input = try .init(allocator, "day02.txt", example);
    defer input.deinit();

    const ranges = try parse(allocator, &input);

    var arena = std.heap.ArenaAllocator.init(allocator);
    const arena_alloc = arena.allocator();

    std.debug.print("DAY 02\n", .{});
    std.debug.print("\tPart 1: {d}\n", .{try part01(arena_alloc, ranges)});
    _ = arena.reset(.free_all);
    std.debug.print("\tPart 2: {d}\n", .{try part02(arena_alloc, ranges)});
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
    while(try input.reader.interface.takeDelimiter('-')) |left| {
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

fn highest(len: usize) usize {
    std.debug.assert(len <= 10);
    var buf: [10]u8 = undefined;
    @memset(buf[0..len], '9');
    return parse_int_unchecked(buf[0..len]);
}

fn lowest(len: usize) usize {
    std.debug.assert(len <= 10);
    var buf: [10]u8 = undefined;
    buf[0] = '1';
    @memset(buf[1..len], '0');
    return parse_int_unchecked(buf[0..len]);
}

fn split_ranges(right: []const u8, left: []const u8, ranges: *std.ArrayList(Range)) void {
    std.debug.assert(left.len > right.len);
    std.debug.assert(left.len - right.len == 1);

    const r1 = Range { parse_int_unchecked(right), highest(right.len) };
    const r2 =  Range { lowest(left.len), parse_int_unchecked(left) };
    ranges.appendAssumeCapacity(r1);
    ranges.appendAssumeCapacity(r2);
}

fn part01(allocator: Allocator, ranges: std.ArrayList(Range)) !usize {
    var results = try allocator.alloc(usize, ranges.items.len);

    var tp: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&tp, .{
        .allocator = allocator,
        .n_jobs = std.Thread.getCpuCount() catch unreachable,
    });

    var wg = std.Thread.WaitGroup{};
    for (ranges.items, 0..) |range, i| {
        tp.spawnWg(&wg, do_part1_range, .{range, &results[i]});
    }
    wg.wait();

    var acc: usize = 0;
    for (results) |i| acc += i;
    return acc;
}

fn do_part1_range(range: Range, result: *usize) void {
    var acc: usize = 0;
    const start, const end = range;

    for (start..end+1) |v| {
        var buf: [50]u8 = undefined;
        const str = std.fmt.bufPrint(&buf, "{d}", .{v}) catch unreachable;
        if (str.len & 1 == 1) {
            continue;
        }

        const middle = str.len / 2;

        if (std.mem.eql(u8, str[0..middle], str[middle..])) {
            acc += v;
        }
    }

    result.* = acc;
}

fn part02(allocator: Allocator, ranges: std.ArrayList(Range)) !usize {
    var results = try allocator.alloc(usize, ranges.items.len);

    // var tp: std.Thread.Pool = undefined;
    // try std.Thread.Pool.init(&tp, .{
    //     .allocator = allocator,
    //     .n_jobs = std.Thread.getCpuCount() catch unreachable,
    // });

    // var wg = std.Thread.WaitGroup{};
    for (ranges.items, 0..) |range, i| {
        // TODO: Benchmark implementation with/without threads, probably paralelization overhead is too large
        do_part2_range(allocator, range, &results[i]);
        // tp.spawnWg(&wg, do_part2_range, .{range, &results[i]});
    }
    // wg.wait();

    var acc: usize = 0;
    for (results) |i| acc += i;
    return acc;
}

fn divisors(n: usize, divs: []usize) usize {
    const nn: usize = @divTrunc(n, 2) + 1;
    var j: usize = 0;

    for (1..nn) |i| {
        if (n % i == 0) {
            divs[j] = i;
            j += 1;
            std.debug.assert(j <= divs.len);
        }
    }
    return j;
}

fn repeat(dest: []u8, src: usize, n: usize) usize {
    var src_buf: [10]u8 = undefined;
    const src_str = std.fmt.bufPrint(&src_buf, "{d}", .{src}) catch @panic("Buffer too small");

    if (dest.len < src_str.len * n) {
        std.debug.panic("Pattern buffer should be at least {d} bytes long.\n", .{src_str.len * n});
    }

    var i: usize = 0;
    for (0..n) |_| {
        @memcpy(dest[i..i+src_str.len], src_str);
        i += src_str.len;
    }

    std.debug.assert(i == src_str.len * n);
    return i;
}

// TODO: Replace AutoArrayHashMap with a bitmap that has MAX(ranges.right) bits to reduce memory usage
fn test_patterns(seen: *std.AutoArrayHashMap(usize, bool), div: usize, start_str: []const u8, end_str: []const u8, range: Range) usize {
    const pattern_start_str = start_str[0..div];
    const pattern_end_str = end_str[0..div];

    const pattern_start = parse_int_unchecked(pattern_start_str);
    const pattern_end = parse_int_unchecked(pattern_end_str);

    var acc: usize = 0;
    for (pattern_start..pattern_end + 1) |pattern| {
        var pattern_buf: [10]u8 = undefined;
        const n = repeat(&pattern_buf, pattern, start_str.len / div);
        const repeated = parse_int_unchecked(pattern_buf[0..n]);

        if (in_range(range, repeated) and !seen.contains(repeated)) {
            seen.put(repeated, true) catch @panic("OOM");
            acc += repeated;
        }
    }
    return acc;
}

fn do_part2_range(allocator: Allocator, range: Range, result: *usize) void {
    var acc: usize = 0;
    const start, const end = range;

    var start_buf: [10]u8 = undefined;
    const start_str = std.fmt.bufPrint(&start_buf, "{d}", .{start}) catch @panic("Buffer too small");

    var end_buf: [10]u8 = undefined;
    const end_str = std.fmt.bufPrint(&end_buf, "{d}", .{end}) catch @panic("Buffer too small");

    var div_buffer: [10]usize = undefined;
    const n_divs = divisors(start_str.len, &div_buffer);
    const divs = div_buffer[0..n_divs];

    var seen = std.AutoArrayHashMap(usize, bool).init(allocator);

    for (divs) |div| {
        acc += test_patterns(&seen, div, start_str, end_str, range);
    }

    result.* = acc;
}

const expectEqual = std.testing.expectEqual;

test "split range into two" {
    const left = "90";
    const right = "110";
    var ranges = try std.ArrayList(Range).initCapacity(std.testing.allocator, 2);
    defer ranges.deinit(std.testing.allocator);
    split_ranges(left, right, &ranges);
    try expectEqual(2, ranges.items.len);

    try expectEqual(Range { 90, 99 }, ranges.items[0]);
    try expectEqual(Range { 100, 110 }, ranges.items[1]);
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

    var n = divisors(9, &divs);
    try std.testing.expectEqualSlices(usize, &[_]usize{1, 3}, divs[0..n]);

    n = divisors(90, &divs);
    try std.testing.expectEqualSlices(usize, &[_]usize{1, 2, 3, 5, 6, 9, 10, 15, 18, 30, 45 }, divs[0..n]);

    n = divisors(2, &divs);
    try std.testing.expectEqualSlices(usize, &[_]usize{1}, divs[0..n]);
}

test "part two examples" {
    var range = Range { 11, 22 };
    var result: usize = 0;

    var test_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = test_arena.allocator();
    defer _ = test_arena.reset(.free_all);

    do_part2_range(allocator, range, &result);
    try expectEqual(33, result);

    range = Range { 95, 99 };
    do_part2_range(allocator, range, &result);
    try expectEqual(99, result);

    range = Range { 100, 115 };
    do_part2_range(allocator, range, &result);
    try expectEqual(111, result);

    range = Range { 998, 999 };
    do_part2_range(allocator, range, &result);
    try expectEqual(999, result);

    range = Range { 1000, 1012 };
    do_part2_range(allocator, range, &result);
    try expectEqual(1010, result);

    range = Range { 1188511880, 1188511890 };
    do_part2_range(allocator, range, &result);
    try expectEqual(1188511885, result);

    range = Range { 222220, 222224 };
    do_part2_range(allocator, range, &result);
    try expectEqual(222222, result);

    range = Range { 1698522, 1698528 };
    do_part2_range(allocator, range, &result);
    try expectEqual(0, result);

    range = Range { 446443, 446449 };
    do_part2_range(allocator, range, &result);
    try expectEqual(446446, result);

    range = Range { 38593856, 38593862 };
    do_part2_range(allocator, range, &result);
    try expectEqual(38593859, result);

    range = Range { 565653, 565659 };
    do_part2_range(allocator, range, &result);
    try expectEqual(565656, result);

    range = Range { 824824821, 824824827 };
    do_part2_range(allocator, range, &result);
    try expectEqual(824824824, result);

    range = Range { 3081, 5416 };
    do_part2_range(allocator, range, &result);
    try expectEqual(
        3131 + 3232 + 3333 + 3434 + 3535 + 3636 + 3737 + 
        3838 + 3939 + 4040 + 4141 + 4242 + 4343 + 4444 +
        4545 + 4646 + 4747 + 4848 + 4949 + 5050 + 5151 +
        5252 + 5353,
    result);
}
