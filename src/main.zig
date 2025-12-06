const std = @import("std");
const day01 = @import("day01");
const day02 = @import("day02");
const day03 = @import("day03");
const day04 = @import("day04");
const day05 = @import("day05");
const Benchmark = @import("common").Benchmark;

var mem_pool: [24*1024]u8 = undefined;

pub fn main() !void {
    var fba = std.heap.FixedBufferAllocator.init(&mem_pool);
    const fba_allocator = fba.allocator();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();

    var bench = Benchmark.init(gpa_allocator, 50);
    defer bench.deinit();
    var overall = bench.add("Overall");

    var args = std.process.ArgIterator.init();
    _ = args.skip();
    const example_flag = args.next();
    const run_example = example_flag != null and std.mem.eql(u8, example_flag.?, "-e");

    overall.start();
    try day01.solve(fba_allocator, &bench, run_example);
    fba.reset();
    try day02.solve(fba_allocator, &bench, run_example);
    fba.reset();
    try day03.solve(fba_allocator, &bench, run_example);
    fba.reset();
    try day04.solve(fba_allocator, &bench, run_example);
    fba.reset();
    try day05.solve(fba_allocator, &bench, run_example);

    overall.finish();
    bench.report();
}
