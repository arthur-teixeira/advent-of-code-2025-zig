const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;
const Benchmark = @import("common").Benchmark;

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var input: Input = try .init(allocator, "day05.txt", example);
    defer input.deinit();

    var t1 = bench.add("Day 05 - Part 1");
    var t2 = bench.add("Day 05 - Part 2");
    var inventory = try parse(&input);

    std.debug.print("DAY 05\n", .{});
    t1.start();
    const p1 = part01(&inventory);
    t1.finish();
    t2.start();
    // const p2 = part02(lines);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{2});
}

const Range = struct {
    start: usize,
    end: usize,
};

const Inventory = struct {
    ranges: [177]Range,
    num_ranges: usize,
    ingredients: [1000]usize,
    num_ingredients: usize,
};

fn parse_int_unchecked(s: []const u8) usize {
    return std.fmt.parseInt(usize, s, 10) catch unreachable;
}

fn parse(input: *Input) !Inventory {
    var inventory: Inventory = .{
        .ranges = undefined,
        .ingredients = @splat(0),
        .num_ingredients = 0,
        .num_ranges = 0
    };

    while (try input.reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            break;
        }

        const sep = std.mem.indexOfScalar(u8, line, '-').?;

        const trimmed_left = std.mem.trimEnd(u8, line[0..sep], "\n");
        const trimmed_right = std.mem.trimEnd(u8, line[sep+1..], "\n");

        const start = std.fmt.parseInt(usize, trimmed_left, 10) catch unreachable;
        const end = std.fmt.parseInt(usize, trimmed_right, 10) catch unreachable;

        inventory.ranges[inventory.num_ranges] = Range { .start = start, .end = end };
        inventory.num_ranges += 1;
    } 

    while (try input.reader.interface.takeDelimiter('\n')) |line| {
        inventory.ingredients[inventory.num_ingredients] = parse_int_unchecked(line);
        inventory.num_ingredients += 1;
    } 

    std.mem.sort(usize, &inventory.ingredients, &inventory.ingredients, cmp);

    return inventory;
}

fn cmp(context: *[1000]usize, a: usize, b: usize) bool {
    _ = context;
    return a < b;
}

fn part01(inventory: *Inventory) usize {
    var valid: usize = 0;
    for (inventory.ranges) |range| {
        for (inventory.ingredients, 0..) |ing, i| {
            if (range.start <= ing and ing <= range.end) {
                inventory.ingredients[i] = 0;
                valid += 1;
            }
        }
    }

    return valid;
}
