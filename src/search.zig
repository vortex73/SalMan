const std = @import("std");
const json = std.json;
const http = std.http;
const clap = @import("clap");

pub fn search(allocator: std.mem.Allocator, searchQuery: []const u8) !void {
    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    var aList = std.ArrayListAligned(u8, null).init(allocator);
    defer aList.deinit();
    const packageName: []const u8 = searchQuery;
    var urlBuf: [256]u8 = undefined;
    const query = try std.fmt.bufPrint(&urlBuf, "https://aur.archlinux.org/rpc/v5/search/{s}", .{packageName});

    const fetops = http.Client.FetchOptions{ .location = http.Client.FetchOptions.Location{
        .url = query,
    }, .response_storage = http.Client.FetchOptions.ResponseStorage{ .dynamic = &aList } };
    const res = try client.fetch(fetops);
    _ = res;
    const JsonSchema = struct {
        resultcount: u32,
        results: []Result,
        type: []const u8,
        version: u32,
        const Result = struct {
            Description: ?[]const u8,
            FirstSubmitted: ?u64,
            ID: ?u32,
            LastModified: ?u64,
            Maintainer: ?[]const u8,
            Name: ?[]const u8,
            NumVotes: ?u32,
            OutOfDate: ?u64,
            PackageBase: ?[]const u8,
            PackageBaseID: ?u32,
            Popularity: ?f32,
            URL: ?[]const u8,
            URLPath: ?[]const u8,
            Version: ?[]const u8,
        };
    };
    const jsonData = aList.items;
    const parsed = try json.parseFromSlice(JsonSchema, allocator, jsonData, .{});
    defer parsed.deinit();
    const response = parsed.value;
    std.debug.print("{any} results returned from the AUR\n", .{response.resultcount});

    for (response.results) |result| {
        std.debug.print("{s} {s}\n\t{s}\n", .{ result.Name orelse "Invalid!", result.Version orelse "Invalid", result.Description orelse "Dev provided no description" });
    }
}
