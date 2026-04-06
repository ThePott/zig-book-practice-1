const std = @import("std");
const Base64 = @import("base64/index.zig").Base64;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("1. encode\n2. decode\n", .{});
    try stdout.flush();

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;
    const which_function = try stdin.takeDelimiter('\n');
    std.debug.print("which function: {any}\n", .{which_function.?});

    var source_in_buffer: [1024]u8 = undefined;
    var source_in_reader = std.fs.File.stdin().reader(&source_in_buffer);
    const source_stdin = &source_in_reader.interface;
    const source = try source_stdin.takeDelimiter('\n');
    std.debug.print("source: {any}\n", .{source.?});

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    const base64 = Base64.init();
    const result: []u8 = switch (which_function.?[0]) {
        '1' => try base64.encode(allocator, source.?),
        '2' => try base64.decode(allocator, source.?),
        else => {
            std.debug.print("whole input: {any}\n", .{which_function});
            std.debug.print("first input: {any}\n", .{which_function.?[0]});
            @panic("unsupported user input");
        },
    };

    try stdout.print("{s}\n", .{result});
    try stdout.flush();
}

test "testing decoding 4 chars" {
    const base64 = Base64.init();
    const encoded = "YWJj";
    const decoded = base64.decode4Chars(encoded);
    std.debug.print("{s}\n", .{decoded});
}

test "testing decoding unfixed amount chars" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    const base64 = Base64.init();
    const encoded = "YWJjZA==";
    const decoded = try base64.decode(allocator, encoded);
    std.debug.print("{s}\n", .{decoded});
}
