const std = @import("std");
const Allocator = std.mem.Allocator;
const Input = @import("common").Input;
const Benchmark = @import("common").Benchmark;

const Operator = enum {
    Mul,
    Add,

    inline fn do(self: Operator, operands: []const usize) usize {
        switch (self) {
            .Mul => return do_mul(operands),
            .Add => return do_add(operands),
        }
    }

    inline fn do_mul(operands: []const usize) usize {
        var acc: usize = 1;
        for (operands) |operand| {
            acc *= operand;
        }

        return acc;
    }

    inline fn do_add(operands: []const usize) usize {
        var acc: usize = 0;
        for (operands) |operand| {
            acc += operand;
        }

        return acc;
    }
};

const Line = struct {
    buf: []const u8,
    pos: usize,

    fn init(allocator: Allocator, buf: []const u8) Line {
        return .{
            .buf = allocator.dupe(u8, buf) catch unreachable,
            .pos = 0,
        };
    }

    inline fn skip_whitespaces(self: *Line) void {
        while (self.pos < self.buf.len and self.buf[self.pos] == ' ') : (self.pos += 1) {}
    }

    inline fn eol(self: Line) bool {
        return self.pos >= self.buf.len;
    }

    fn next_number(self: *Line) ?usize {
        self.skip_whitespaces();
        if (self.eol()) return null;

        var acc: usize = 0;
        while (!self.eol() and std.ascii.isDigit(self.buf[self.pos])) : (self.pos += 1) {
            acc = acc * 10 + (self.buf[self.pos] - '0');
        }

        if (acc == 0) return null;
        return acc;
    }

    fn next_operator(self: *Line) ?Operator {
        self.skip_whitespaces();
        if (self.eol()) return null;

        self.pos += 1;
        const op: Operator = switch (self.buf[self.pos - 1]) {
            '*' => .Mul,
            '+' => .Add,
            else => unreachable,
        };
        self.skip_whitespaces();
        if (self.eol()) {
            self.pos += 1;
        }
        return op;
    }
};

const Homework = struct {
    lines: [5]Line,
    num_lines: usize,

    fn init(allocator: Allocator, input: *Input) Homework {
        var hw: Homework = .{
            .lines = undefined,
            .num_lines = 0,
        };

        while (input.reader.interface.takeDelimiter('\n')) |line| {
            if (line == null) break;
            hw.lines[hw.num_lines] = .init(allocator, line.?);
            hw.num_lines += 1;
        } else |_| unreachable;

        return hw;
    }

    fn next_operation(self: *Homework) ?usize {
        var operands: [4]usize = undefined;
        for (0..self.num_lines - 1) |i| {
            var line = &self.lines[i];
            operands[i] = line.next_number() orelse return null;
        }
        const op = self.lines[self.num_lines - 1].next_operator() orelse unreachable;
        return op.do(operands[0..self.num_lines - 1]);
    }

    fn reset(self: *Homework) void {
        for (0..self.num_lines) |i| {
            self.lines[i].pos = 0;
        }
    }

    fn vertical(self: *Homework) ?usize {
        const op_line = &self.lines[self.num_lines - 1];
        const start = op_line.pos;
        const op = op_line.next_operator() orelse return null;
        const end = op_line.pos - 1;

        var operands: [4]usize = undefined;
        std.debug.assert(end - start <= 4);

        for (start..end, 0..) |i, ii| {
            var acc: usize = 0;
            for (0..self.num_lines - 1) |j| {
                const char = self.lines[j].buf[i];
                if (char == ' ') continue;
                const cur_digit = self.lines[j].buf[i] - '0';
                acc = acc * 10 + cur_digit;
            }
            operands[ii] = acc;
        }

        return op.do(operands[0..end - start]);
    }
};


pub fn solve(allocator: Allocator, bench: *Benchmark, example: bool) !void {
    var input: Input = try .init(allocator, "day06.txt", example);

    var t1 = bench.add("Day 06 - Part 1");
    var t2 = bench.add("Day 06 - Part 2");
    var homework: Homework = .init(allocator, &input);
    input.deinit();

    std.debug.print("DAY 06\n", .{});
    t1.start();
    const p1 = part01(&homework);
    t1.finish();
    homework.reset();
    t2.start();
    const p2 = part02(&homework);
    t2.finish();
    std.debug.print("\tPart 1: {d}\n", .{p1});
    std.debug.print("\tPart 2: {d}\n", .{p2});
}

fn part01(homework: *Homework) usize {
    var acc: usize = 0;
    while (homework.next_operation()) |op| {
        acc += op;
    }
    return acc;
}

fn part02(homework: *Homework) usize {
    var acc: usize = 0;
    while (homework.vertical()) |op| {
        acc += op;
    }
    return acc;
}
