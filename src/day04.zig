const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common");
const Benchmark = common.Benchmark;
const Input = common.Input;

const Dir = struct { isize, isize };

const Up = Dir { 1, 0 };
const UpLeft = Dir { 1, -1 };
const UpRight = Dir { 1, 1 };
const Down = Dir { -1, 0 };
const DownLeft = Dir { -1, -1 };
const DownRight = Dir { -1, 1 };
const Left = Dir { 0, -1 };
const Right = Dir { 0, 1 };

const directions = [_]Dir {
    Up,
    UpLeft,
    UpRight,
    Down,
    DownLeft,
    DownRight,
    Left,
    Right,
};

const Grid = struct {
    h: usize,
    w: usize,
    elems: std.bit_set.ArrayBitSet(usize, 139 * 139),

    inline fn i(self: Grid, w: usize, h: usize) usize {
        return w * self.w + h;
    }

    inline fn at(self: Grid, w: usize, h: usize) bool {
        return self.elems.isSet(self.i(w, h));
    }

    fn parse(input: *Input) !Grid {
        var self: Grid = .{
            .h = 0,
            .w = 0,
            .elems = .initEmpty(),
        };

        while (try input.reader.interface.takeDelimiter('\n')) |line| {
            if (self.w == 0) self.w = line.len;
            for (line, 0..) |c, idx| {
                const m = self.i(idx, self.h);
                if (c == '@') {
                    self.elems.set(m);
                }
            }
            self.h += 1;
        } 

        return self;
    }

    inline fn in_bounds(self: Grid, w: usize, h: usize) bool {
        return w < self.w and h < self.h;
    }

    fn accessible(self: Grid, w: usize, h: usize) usize {
        if (!self.elems.isSet(self.i(w, h))) {
            @branchHint(.likely);
            return 0;
        }

        var acc: u8 = 0;
        for (directions) |dir| {
            const dw, const dh = dir;

            const cw: usize = @bitCast(@as(isize, @bitCast(w)) + dw);
            const ch: usize = @bitCast(@as(isize, @bitCast(h)) + dh);

            if (self.in_bounds(cw, ch) and self.elems.isSet(self.i(cw, ch))) {
                @branchHint(.likely);
                acc += 1;
            }
        }

        return if (acc < 4) 1 else 0;
    }
};

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var input: Input = try .init(allocator, "day04.txt", example);
    defer input.deinit();

    var grid = Grid.parse(&input) catch unreachable;

    var t1 = bench.add("Day 04 - Part 1");
    var t2 = bench.add("Day 04 - Part 2");

    std.debug.print("DAY 04\n", .{});
    t1.start();
    const p1 = part01(grid);
    t1.finish();
    t2.start();
    const p2 = part02(&grid);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{p2});
}

fn part01(grid: Grid) usize {
    var acc: usize = 0;
    for (0..grid.w) |w| {
        for (0..grid.h) |h| {
            acc += grid.accessible(w, h);
        }
    }

    return acc;
}

fn part02(grid: *Grid) usize {
    var acc: usize = 0;
    var remove_set: std.bit_set.ArrayBitSet(usize, 139 * 139) = .initFull();

    while(true) {
        var should_remove = false;
        for (0..grid.w) |w| {
            for (0..grid.h) |h| {
                const accessible = grid.accessible(w, h);
                const remove = (accessible == 1);
                acc += accessible;
                if (remove) {
                    should_remove = true;
                    remove_set.unset(grid.i(w, h));
                }
            }
        }

        grid.elems.setIntersection(remove_set);
        remove_set.setRangeValue(.{ .start = 0, .end = 139 * 139 }, true);
        if (!should_remove) break;
    }

    return acc;
}
