const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;
const Benchmark = @import("common").Benchmark;

const Box = struct {
    x: u32,
    y: u32,
    z: u32,

    const empty: Box = .{ .x = 0, .y = 0, .z = 0 };

    fn init(line: []const u8) Box {
        var it = std.mem.splitScalar(u8, line, ',');
        return .{
            .x = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
            .z = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
        };
    }

    fn print(self: Box) void {
        std.debug.print("[{d}, {d}, {d}]", .{ self.x, self.y, self.z });
    }

    inline fn distance(self: Box, other: Box) f32 {
        const dx: f32 = @floatFromInt(@as(i64, @intCast(self.x)) - @as(i64, @intCast(other.x)));
        const dy: f32 = @floatFromInt(@as(i64, @intCast(self.y)) - @as(i64, @intCast(other.y)));
        const dz: f32 = @floatFromInt(@as(i64, @intCast(self.z)) - @as(i64, @intCast(other.z)));

        return @sqrt(dx * dx + dy * dy + dz * dz);
    }
};

const World = struct {
    const Circuit = struct {
        boxes: []const Box,
        box_indices: [1000]u16,
        num_boxes: u16,

        const empty: Circuit = .{
            .boxes = undefined,
            .box_indices = @splat(0),
            .num_boxes = 0,
        };

        fn init(boxes: []const Box, initial_box: u16) Circuit {
            var indices: [1000]u16 = @splat(0);
            indices[0] = initial_box;
            return .{
                .boxes = boxes,
                .box_indices = indices,
                .num_boxes = 1,
            };
        }

        pub fn print(self: Circuit) void {
            std.debug.print("Circuit{{ .num_boxes = {d} .boxes = [", .{self.num_boxes});
            for (self.box_indices[0..self.num_boxes]) |box| {
                self.boxes[box].print();
                std.debug.print(", ", .{});
            }
            std.debug.print("] }}", .{});
        }
    };

    boxes: [1000]Box,
    circuits: [1000]Circuit,
    num_boxes: u16,

    fn init(input: *Input) !World {
        var w: World = .{
            .boxes = @splat(.empty),
            .circuits = @splat(.empty),
            .num_boxes = 0,
        };

        var i: u16 = 0;
        while (try input.reader.interface.takeDelimiter('\n')) |line| : (i += 1) {
            w.boxes[i] = .init(line);
            w.circuits[i] = .init(&w.boxes, i);
            w.num_boxes += 1;
        }

        return w;
    }

    const Pair = struct {
        a: u16,
        b: u16,
        dist: f32,
    };

    fn compute_distances(self: *const World, allocator: Allocator, bench: *Benchmark) !void {
        var t = bench.add("distances");
        t.start();
        var q = std.PriorityQueue(Pair, *const World, cmp_pair).init(allocator, self);
        defer q.deinit();

        for (self.boxes[0 .. self.num_boxes - 1], 0..) |a, i| {
            for (self.boxes[i + 1 .. self.num_boxes], i + 1..) |b, j| {
                if (q.count() < 1000) {
                    const dist = self.boxes[@intCast(i)].distance(self.boxes[@intCast(j)]);
                    const pair: Pair =.{ .a = @intCast(i), .b = @intCast(j), .dist = dist };

                    try q.add(pair);
                    continue;
                }

                if (q.peek()) |highest| {
                    const dist = a.distance(b);
                    if (highest.dist > dist) {
                        _ = q.remove();
                        try q.add(.{ .a = @intCast(i), .b = @intCast(j), .dist = dist });
                    }
                } else unreachable;
            }
        }
        t.finish();

        std.mem.sort(Pair, q.items, self, cmp_pair_bool);
    }

    fn cmp_pair(_: *const World, a: Pair, b: Pair) std.math.Order {
        const a_dist = a.dist;
        const b_dist = b.dist;

        if (a_dist < b_dist) return .gt;
        if (a_dist > b_dist) return .lt;
        return .eq;
    }

    fn cmp_pair_bool(world: *const World, a: Pair, b: Pair) bool {
        switch (cmp_pair(world, a, b)) {
            .lt => return false,
            else => return true,
        }
    }
};

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var t1 = bench.add("Day 08 - Part 1");
    var t2 = bench.add("Day 08 - Part 2");

    var input: Input = try .init(allocator, "day08.txt", example);
    const world: World = try .init(&input);

    std.debug.print("CIRCUITS\n", .{});
    for (world.circuits[0..world.num_boxes]) |c| {
        c.print();
        std.debug.print("\n", .{});
    }

    world.compute_distances(allocator, bench) catch @panic("OOM");

    std.debug.print("DAY 08\n", .{});
    t1.start();
    // const p1 = part01(&grid);
    t1.finish();
    t2.start();
    // const p2 = part02(&grid);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{1});
    std.debug.print("\tPart 2: {d}\n", .{2});
}
