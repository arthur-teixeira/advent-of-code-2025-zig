const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;
const Benchmark = @import("common").Benchmark;

const Box = struct {
    x: u32,
    y: u32,
    z: u32,
    circuit: u16,

    const empty: Box = .{ .x = 0, .y = 0, .z = 0, .circuit = 0 };

    inline fn init(line: []const u8, circuit_idx: u16) Box {
        var it = std.mem.splitScalar(u8, line, ',');
        return .{
            .circuit = circuit_idx,
            .x = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
            .z = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
        };
    }

    fn print(self: Box) void {
        std.debug.print("[{d}, {d}, {d} at {d}]", .{ self.x, self.y, self.z, self.circuit });
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
        world: *const World,
        box_indices: [1000]u16,
        num_boxes: u16,

        const empty: Circuit = .{
            .world = undefined,
            .box_indices = @splat(0),
            .num_boxes = 0,
        };

        fn init(world: *const World, initial_box: u16) Circuit {
            var indices: [1000]u16 = @splat(0);
            indices[0] = initial_box;
            return .{
                .world = world,
                .box_indices = indices,
                .num_boxes = 1,
            };
        }

        fn print(self: Circuit) void {
            std.debug.print("Circuit{{ .num_boxes = {d} .boxes = [", .{self.num_boxes});
            for (self.box_indices[0..self.num_boxes]) |box| {
                self.world.boxes[box].print();
                std.debug.print(", ", .{});
            }
            std.debug.print("] }}", .{});
        }

        fn join(self: *Circuit, other: *Circuit) void {
            std.debug.assert(self.num_boxes + other.num_boxes < 1000);
            @memcpy(self.box_indices[self.num_boxes .. self.num_boxes + other.num_boxes], other.box_indices[0..other.num_boxes]);
            self.num_boxes += other.num_boxes;
        }
    };

    boxes: [1000]Box,
    circuits: [1000]Circuit,
    num_boxes: u16,

    fn init(self: *World, input: *Input) !void {
        while (try input.reader.interface.takeDelimiter('\n')) |line| : (self.num_boxes += 1) {
            self.boxes[self.num_boxes] = .init(line, self.num_boxes);
            self.circuits[self.num_boxes] = .init(self, self.num_boxes);
        }
    }

    const Pair = struct {
        a: u16,
        b: u16,
        dist: f32,
    };

    fn compute_distances(self: *const World, allocator: Allocator) ![]Pair {
        var q = std.PriorityQueue(Pair, *const World, cmp_pair).init(allocator, self);
        errdefer q.deinit();

        for (self.boxes[0 .. self.num_boxes - 1], 0..) |a, i| {
            for (self.boxes[i + 1 .. self.num_boxes], i + 1..) |b, j| {
                if (q.count() < 1000) {
                    const dist = self.boxes[@intCast(i)].distance(self.boxes[@intCast(j)]);
                    const pair: Pair = .{ .a = @intCast(i), .b = @intCast(j), .dist = dist };

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
        std.mem.sort(Pair, q.items, self, cmp_pair_bool);
        return q.items;
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

    fn join_pair(self: *World, pair: Pair) void {
        const a = self.boxes[pair.a];
        const b = self.boxes[pair.b];

        if (a.circuit == b.circuit) return;

        var a_circuit = &self.circuits[a.circuit];
        const b_circuit = &self.circuits[b.circuit];

        for (0..b_circuit.num_boxes) |i| {
            const bbox_i = b_circuit.box_indices[i];

            var bbox = &self.boxes[@intCast(bbox_i)];
            bbox.circuit = a.circuit;
        }

        a_circuit.join(b_circuit);
        b_circuit.* = .empty;
    }


    fn sort_circuits(self: *World) void {
        std.mem.sort(Circuit, &self.circuits, {}, cmp_circuit);
    }

    fn cmp_circuit(_: void, a: Circuit, b: Circuit) bool {
        return a.num_boxes > b.num_boxes;
    }
};

pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var t1 = bench.add("Day 08 - Part 1");
    var t2 = bench.add("Day 08 - Part 2");

    var input: Input = try .init(allocator, "day08.txt", example);
    var w: World = .{
        .boxes = @splat(.empty),
        .circuits = @splat(.empty),
        .num_boxes = 0,
    };
    try w.init(&input);

    std.debug.print("DAY 08\n", .{});
    t1.start();
    const p1 = part01(allocator, &w);
    t1.finish();
    t2.start();
    // const p2 = part02(&grid);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{2});
}

pub fn part01(allocator: Allocator, world: *World) usize {
    const pairs = world.compute_distances(allocator) catch @panic("OOM");

    for (pairs) |pair| {
        world.join_pair(pair);
    }

    world.sort_circuits();
    var acc: usize = 1;
    for (world.circuits[0..3]) |c| {
        acc *= c.num_boxes;
    }

    return acc;
}
