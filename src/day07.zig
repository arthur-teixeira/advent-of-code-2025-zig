const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;
const Benchmark = @import("common").Benchmark;

const Grid = struct {
    elems: [142 * 141]u8,
    h: usize,
    w: usize,

    fn init(input: *Input) !Grid {
        var self: Grid = undefined;
        var i: usize = 0;
        while (try input.reader.interface.takeDelimiter('\n')) |line| : (i += 1) {
            if (i == 0) self.w = line.len;
            std.debug.assert(self.w == line.len);

            const line_pos = self.w * i;
            @memcpy(self.elems[line_pos .. line_pos + self.w], line);
        }

        self.h = i;
        return self;
    }

    inline fn line_at(self: *Grid, i: usize) []u8 {
        const line_start = i * self.w;
        const line_end = line_start + self.w;
        return self.elems[line_start..line_end];
    }
};

const FreqMap = struct {
    elems: [142 * 141]usize,
    h: usize,
    w: usize,

    inline fn at(self: *FreqMap, i: usize, j: usize) *usize {
        const pos = i * self.w + j;
        return &self.elems[pos];
    }

    inline fn line_at(self: *FreqMap, i: usize) []const usize {
        const line_start = i * self.w;
        const line_end = line_start + self.w;
        return self.elems[line_start..line_end];
    }
};

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var t1 = bench.add("Day 07 - Part 1");
    var t2 = bench.add("Day 07 - Part 2");

    var input: Input = try .init(allocator, "day07.txt", example);
    var grid: Grid = try .init(&input);

    std.debug.print("DAY 07\n", .{});
    t1.start();
    const p1 = part01(&grid);
    t1.finish();
    t2.start();
    const p2 = part02(&grid);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{p2});
}

fn part01(in: *Grid) usize {
    var acc: usize = 0;

    for (0..in.h - 1) |i| {
        const cur_line = in.line_at(i);
        var next_line = in.line_at(i + 1);

        for (cur_line, 0..) |ch, j| {
            if (ch == '.' or ch == '^') continue;

            if (next_line[j] == '^') {
                std.debug.assert(j > 0);
                std.debug.assert(j < next_line.len);

                next_line[j - 1] = '|';
                next_line[j + 1] = '|';
                acc += 1;
                continue;
            }

            next_line[j] = '|';
        }
    }

    return acc;
}

fn part02(in: *Grid) usize {
    var freq: FreqMap = .{
        .elems = @splat(0),
        .h = in.h,
        .w = in.w,
    };

    for (0..in.h - 1) |i| {
        const cur_line = in.line_at(i);
        const next_line = in.line_at(i + 1);

        for (cur_line, 0..) |ch, j| {
            if (ch == '.' or ch == '^') continue;
            if (i == 0) {
                freq.at(i, j).* = 1;
            }

            if (next_line[j] == '^') {
                std.debug.assert(j > 0);
                std.debug.assert(j < next_line.len);

                freq.at(i + 1, j - 1).* += freq.at(i, j).*;
                freq.at(i + 1, j + 1).* += freq.at(i, j).*;
                continue;
            }

            freq.at(i + 1, j).* += freq.at(i, j).*;
        }
    }

    var acc: usize = 0;
    for (freq.line_at(in.h - 1)) |n| {
        acc += n;
    }

    return acc;
}
