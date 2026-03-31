const std = @import("std");

pub fn countBase64EncodedChars(source: []const u8) !usize {
    if (source.len < 3) {
        return 4;
    }

    const ceil = try std.math.divCeil(usize, source.len, 3);
    return ceil * 4;
}

pub fn countBase64DecodedBytes(source: []const u8) usize {
    const ceil = std.math.ceil(source / 4);
    var valid_length = ceil * 3;

    while (true) {
        const last_char = source[valid_length - 1];
        if (last_char != '=') {
            break;
        }
        valid_length -= 1;
    }

    return valid_length;
}

const Base64 = struct {
    table: *const [64]u8,

    pub fn init() Base64 {
        const uppers = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lowers = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symbols = "0123456789+/";
        return Base64{ .table = uppers ++ lowers ++ numbers_symbols };
    }

    pub fn charAt(self: Base64, index: u8) u8 {
        return self.table[index];
    }

    pub fn indexOf(self: Base64, char: u8) u8 {
        const index: usize = 0;
        if (char == '=') {
            return 64;
        }
        while (true) {
            if (self.table[index] == char) {
                return index;
            }
            index += 1;

            if (index >= 64) {
                @panic("could not find index from base64 table");
            }
        }
        return index;
    }

    // NOTE: need to take heap pointer
    // NOTE: need to return heap pointer
    // TODO: how can I force length of 3 ???? <<<<<
    fn encode3Byptes(self: Base64, source: []const u8) [4]u8 {
        switch (source.len) {
            1 => {
                // NOTE: 굳이 마스킹을 해야 하나?
                // TODO: 마스킹 하는 게 더 속 편하긴 할 것 같다. 이게 작동하는지 확인한 다음 적용해보자
                const first = source[0] >> 2;
                const second = (source[0] & 0b00000011) << 4;
                std.debug.print("first: {any}\n", .{first});
                std.debug.print("second: {any}\n", .{second});

                const first_char = self.charAt(first);
                const second_char = self.charAt(second);
                const third_char = '=';
                const fourth_char = '=';
                return [4]u8{ first_char, second_char, third_char, fourth_char };
            },
            2 => {
                const first = source[0] >> 2;
                const second = ((source[0] & 0b00000011) << 4) + (source[1] >> 4);
                const third = (source[1] & 0b00001111) << 2;

                const first_char = self.charAt(first);
                const second_char = self.charAt(second);
                const third_char = self.charAt(third);
                const fourth_char = '=';
                return [4]u8{ first_char, second_char, third_char, fourth_char };
            },
            3 => {
                const first = source[0] >> 2;
                const second = ((source[0] & 0b00000011) << 4) + (source[1] >> 4);
                const third = ((source[1] & 0b00001111) << 2) + (source[2] >> 6);
                const fourth = (source[2] & 0b00111111);

                const first_char = self.charAt(first);
                const second_char = self.charAt(second);
                const third_char = self.charAt(third);
                const fourth_char = self.charAt(fourth);
                return [4]u8{ first_char, second_char, third_char, fourth_char };
            },
            else => @panic("only length 1 ~ 3 is supported"),
        }
    }

    // NOTE: main에서 바로 받을 거니까 compile time known
    // TODO: user input 받아서 변환하는 걸 만들어보자
    pub fn encode(self: Base64, allocator: std.mem.Allocator, source: []const u8) ![]u8 {
        const group_length = try std.math.divCeil(usize, source.len, 3);
        const encoded_char_count = try countBase64EncodedChars(source);
        var encoded = try allocator.alloc(u8, encoded_char_count);
        @memset(encoded, 0);
        std.debug.print("group_length: {any}\n", .{group_length});
        std.debug.print("encoded_char_count: {any}\n", .{encoded_char_count});
        std.debug.print("encoded initialized: {any}\n", .{encoded});

        var group_index: usize = 0;
        while (group_index < group_length) {
            std.debug.print("inside encode while loop, encoded: {any}\n", .{encoded});
            // TODO: how can I fix it to length 3 array
            const group_slice = if ((group_index * 3 + 3) > source.len) source[group_index * 3 ..] else source[group_index * 3 .. group_index * 3 + 3];
            const group_encoded = self.encode3Byptes(group_slice);
            std.debug.print("inside encode while loop, group_slice: {any}\n", .{group_slice});
            std.debug.print("inside encode while loop, group_encoded_any: {any}\n", .{group_encoded});
            std.debug.print("inside encode while loop, group_encoded_string: {s}\n", .{group_encoded});
            std.debug.print("inside encode while loop, group_encoded length: {any}\n", .{group_encoded.len});

            // NOTE: 3 바이트 당 네 글자가 된다
            @memcpy(encoded[group_index * 4 .. group_index * 4 + group_encoded.len], group_encoded[0..]);
            std.debug.print("end of while loop cycle, encoded: {any}\n", .{encoded});
            group_index += 1;
        }

        std.debug.print("end of while loop, encoded: {any}\n", .{encoded});
        return encoded;
    }

    // TODO: how can I force length of 3 ???? <<<<<
    fn decode4Chars(_: Base64, source: []const u8) [3]u8 {
        var valid_source_length = source.len;
        while (valid_source_length > 0) {
            if (source[valid_source_length - 1] != '=') {
                break;
            }
            valid_source_length -= 1;
        }

        // NOTE: 빠뜨린 것
        // A -> index -> binary -> switch

        switch (valid_source_length) {
            2 => {
                const first = (source[0] << 2) + (source[1] >> 4);
                return [3]u8{first};
            },
            3 => {
                const first = (source[0] << 2) + (source[1] >> 4);
                const second = ((source[1] & 0b00001111) << 4) + (source[2] >> 2);
                return [3]u8{ first, second };
            },
            4 => {
                const first = (source[0] << 2) + (source[1] >> 4);
                const second = ((source[1] & 0b00001111) << 4) + (source[2] >> 2);
                const third = ((source[2] & 0b00000011) << 6) + source[3];
                return [3]u8{ first, second, third };
            },
            else => @panic("not supported valid source length"),
        }

        // const first_index = self.table.
    }

    pub fn decode(self: Base64, allocator: std.mem.Allocator, source: []const u8) ![]u8 {
        const group_length = try std.math.divCeil(usize, source.len, 4);
        // const decoded_char_count = self.encode
    }
};

pub fn main() !void {
    const base64 = Base64.init();
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    const some_string = "ab";
    const encoded = try base64.encode(allocator, some_string);
    defer allocator.free(encoded);
    std.debug.print("encoded_any: {any}\n", .{encoded});
    std.debug.print("encoded_string: {s}\n", .{encoded});
}
