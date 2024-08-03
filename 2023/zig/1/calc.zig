const std = @import("std");
const fs = std.fs;
const ascii = std.ascii;
const assert = std.debug.assert;

fn readline(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return line;
}

fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn min(comptime T: type, a: T, b: T) T {
    return if (a < b) a else b;
}

/// Returns in index into the spelled_digits list or null if nothing is found
fn search_word(line: []const u8, idx: usize) ?u8 {
    const spelled_digits = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    for (spelled_digits, 0..) |s, si| {
        const rem_len = min(usize, idx + s.len, line.len);
        const remaining = line[idx..rem_len];
        if (std.mem.eql(u8, s, remaining)) {
            // std.debug.print("Found a {s}\n", .{s});
            return @as(u8, @intCast(si));
        }
    }
    return null;
}

fn find_number(line: []const u8, result_buf: []u8, search_words: bool) void {
    var found: bool = false;

    // Forward search
    assert(result_buf.len >= 2);
    for (line[0..], 0..) |f, i| {
        if (ascii.isDigit(f)) {
            result_buf[0] = f;
            found = true;
            break;
        } else if (search_words) {
            const found_word = search_word(line, i);
            if (found_word) |word| {
                result_buf[0] = '1' + word;
                found = true;
                break;
            }
        }
    }
    assert(found);

    // Backward search
    found = false;
    var i: usize = line.len - 1;
    // std.debug.print("Line len: {}\n", .{line.len});
    while (i >= 0) {
        const f = line[i];
        if (ascii.isDigit(f)) {
            result_buf[1] = f;
            found = true;
            break;
        } else if (search_words) {
            const found_word = search_word(line, i);
            if (found_word) |word| {
                result_buf[1] = '1' + word;
                found = true;
                break;
            }
        }
        i -= 1;
    }
    assert(found);
}

pub fn main() !void {
    var sum: u32 = 0;
    var buf: [100]u8 = undefined;
    var num_buf: [2]u8 = undefined;
    var file = try fs.cwd().openFile("input.txt", .{});
    defer file.close();

    while (try readline(file.reader(), &buf)) |ln| {
        std.debug.print("Next line is  {s}", .{ln});
        find_number(ln, &num_buf, true);
        const num = try std.fmt.parseInt(u32, &num_buf, 10);
        sum += num;
        std.debug.print("   Num: {}  sum: {}\n", .{ num, sum });
    }
    std.debug.print("Sum is {}\n", .{sum});
}
