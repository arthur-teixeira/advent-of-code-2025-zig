const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;
const Benchmark = @import("common").Benchmark;

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var input: Input = try .init(allocator, "day05.txt", example);
    defer input.deinit();

    var t1 = bench.add("Day 05 - Part 1");
    var t2 = bench.add("Day 05 - Part 2");
    var inventory = try parse(&input, bench);

    std.debug.print("DAY 05\n", .{});
    t1.start();
    const p1 = part01(&inventory);
    t1.finish();
    t2.start();
    const p2 = part02(inventory);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{p2});
}

const Range = struct {
    start: usize,
    end: usize,

    const empty: Range = .{
        .start = 0,
        .end = 0,
    };

    inline fn intersects(self: Range, other: Range) bool {
        return other.start >= self.start and other.start <= self.end;
    }

    inline fn intersection(self: Range, other: Range) Range {
        return .{
            .start = self.start,
            .end = @max(self.end, other.end),
        };
    }
};

const expectEqual = std.testing.expectEqual;
test "range intersection" {
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 15, .end = 25 }), Range{ .start = 1, .end = 25 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 5, .end = 10 }), Range{ .start = 1, .end = 20 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 10, .end = 20 }), Range{ .start = 1, .end = 20 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 20, .end = 30 }), Range{ .start = 1, .end = 30 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 2, .end = 30 }), Range{ .start = 1, .end = 30 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 1, .end = 5 }), Range{ .start = 1, .end = 20 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 5, .end = 21 }), Range{ .start = 1, .end = 21 });
    try expectEqual((Range{ .start = 1, .end = 20 }).intersection(Range{ .start = 20, .end = 20 }), Range{ .start = 1, .end = 20 });
}

const Inventory = struct {
    ranges: [177]Range,
    num_ranges: usize,
    ingredients: [1000]usize,
    num_ingredients: usize,
};

fn parse_int_unchecked(s: []const u8) usize {
    return std.fmt.parseInt(usize, s, 10) catch unreachable;
}

fn parse(input: *Input, bench: *Benchmark) !Inventory {
    var inventory: Inventory = .{ .num_ranges = 0, .ranges = @splat(.empty), .ingredients = @splat(0), .num_ingredients = 0 };

    while (try input.reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            break;
        }

        const sep = std.mem.indexOfScalar(u8, line, '-').?;

        const start = std.fmt.parseInt(usize, line[0..sep], 10) catch unreachable;
        const end = std.fmt.parseInt(usize, line[sep + 1 ..], 10) catch unreachable;

        inventory.ranges[inventory.num_ranges] = Range{ .start = start, .end = end };
        inventory.num_ranges += 1;
    }

    while (try input.reader.interface.takeDelimiter('\n')) |line| {
        inventory.ingredients[inventory.num_ingredients] = parse_int_unchecked(line);
        inventory.num_ingredients += 1;
    }
    var t = bench.add("DAY 05 - MERGING RANGES");

    std.mem.sort(usize, &inventory.ingredients, {}, std.sort.asc(usize));
    t.start();
    std.mem.sort(Range, inventory.ranges[0..inventory.num_ranges], &inventory.ranges, range_cmp);
    merge_ranges(&inventory);
    t.finish();

    return inventory;
}

fn merge_ranges(inventory: *Inventory) void {
    var i: usize = 1;
    var write_index: usize = 0;
    while (i < inventory.num_ranges) {
        const curr = inventory.ranges[i];
        const a = inventory.ranges[write_index];
        if (a.intersects(curr)) {
            inventory.ranges[write_index] = inventory.ranges[write_index].intersection(curr);
        } else {
            write_index += 1;
            inventory.ranges[write_index] = curr;
        }
        i += 1;
    }

    inventory.num_ranges = write_index + 1;
}

fn range_cmp(context: *[177]Range, a: Range, b: Range) bool {
    _ = context;
    return a.start < b.start;
}

fn part01(inventory: *Inventory) usize {
    var valid: usize = 0;
    var next_ingredient_start: usize = 0;
    for (inventory.ranges[0..inventory.num_ranges]) |range| {
        for (inventory.ingredients[next_ingredient_start..], 0..) |ing, i| {
            if (range.start >= ing) {
                next_ingredient_start += 1;
            } else if (range.start <= ing and ing <= range.end) {
                next_ingredient_start += 1;
                inventory.ingredients[i] = 0;
                valid += 1;
            }
        }
    }

    return valid;
}

fn part02(inventory: Inventory) usize {
    var acc: usize = 0;
    for (inventory.ranges[0..inventory.num_ranges]) |range| {
        acc += range.end - range.start + 1;
    }

    return acc;
}
