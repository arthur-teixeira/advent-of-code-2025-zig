const std = @import("std");
const day01 = @import("day01");
const day02 = @import("day02");

var mem_pool: [20*1024]u8 = undefined;

pub fn main() !void {
    var fba = std.heap.FixedBufferAllocator.init(&mem_pool);
    const fba_allocator = fba.allocator();

    var args = std.process.ArgIterator.init();
    _ = args.skip();
    const example_flag = args.next();
    const run_example = example_flag != null and std.mem.eql(u8, example_flag.?, "-e");


    var arena = std.heap.ArenaAllocator.init(fba_allocator);
    const allocator = arena.allocator();
    try day01.solve(allocator, run_example);
    _ = arena.reset(.free_all);
    try day02.solve(allocator, run_example);
}
