const std = @import("std");
const Input = @import("common").Input;
const Allocator = std.mem.Allocator;

pub fn solve(allocator: Allocator, example: bool) !void {
    var input: Input = try .init(allocator, "day02.txt", example);
    defer input.deinit();

    const ranges = try parse(allocator, &input);

    std.debug.print("DAY 02\n", .{});
    std.debug.print("\tPart 1: {d}\n", .{try part01(allocator, ranges)});
}

const Range = struct { usize, usize };

fn parse(allocator: Allocator, input: *Input) !std.ArrayList(Range) {
    var ranges = try std.ArrayList(Range).initCapacity(allocator, 36);
    while(try input.reader.interface.takeDelimiter('-')) |left| {
        const right = (try input.reader.interface.takeDelimiter(',')).?;

        const start = std.fmt.parseInt(usize, left, 10) catch unreachable;
        const end = std.fmt.parseInt(usize, std.mem.trimEnd(u8, right, "\n"), 10) catch unreachable;
        ranges.appendAssumeCapacity(.{ start, end });
    }

    return ranges;
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
