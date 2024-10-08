const std = @import("std");
const clap = @import("clap");
const search = @import("search.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 30 }){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();
    const params = comptime clap.parseParamsComptime(
        \\-h, --help               Help is given to those who ask for it.
        \\-s, --search <str>       Search the AUR
    );
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        // Report useful error and exit
        return err;
    };
    defer res.deinit();

    // std.debug.print("{any}", .{res.args});
    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    if (res.args.search) |x| {
        try search.search(allocator, x);
    }
}
