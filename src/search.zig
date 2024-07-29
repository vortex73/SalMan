const std = @import("std");
const json = std.json;
const http = std.http;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 30 }){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    var aList = std.ArrayListAligned(u8, null).init(allocator);
    defer aList.deinit();
    const packageName: []const u8 = "chrome";
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
            Description: []const u8,
            FirstSubmitted: u64,
            ID: u32,
            LastModified: u64,
            Maintainer: []const u8,
            Name: []const u8,
            NumVotes: u32,
            OutOfDate: u64,
            PackageBase: []const u8,
            PackageBaseID: u32,
            Popularity: u32,
            URL: []const u8,
            URLPath: []const u8,
            Version: []const u8,
        };
    };
    const jsonData = aList.items;
    std.debug.print("{s}", .{jsonData});
    const parsed = try json.parseFromSlice(JsonSchema, allocator, jsonData, .{});
    defer parsed.deinit();
    std.debug.print("{!}", .{parsed.value});
}
