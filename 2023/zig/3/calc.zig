const std = @import("std");
const expect = std.testing.expect;

const Allocator = std.mem.Allocator;

const DigitStrItem = struct { start: usize, end: usize };
const NumberChars = "0123456789";
const SymbolChars = "#$%&*+-/=@";

const DigitStrIterator = struct {
    line: []const u8,
    index: ?usize,
    fn next(self: *DigitStrIterator) ?DigitStrItem {
        const index = self.index orelse return null;
        const first = std.mem.indexOfAnyPos(u8, self.line, index, NumberChars) orelse return null;
        var last = first;
        for (self.line[first + 1 ..], first + 1..) |c, i| {
            var found: bool = false;
            for (NumberChars) |n| {
                if (c == n) {
                    last = i;
                    found = true;
                    break;
                }
            }
            if (!found) break;
        }
        if (last == self.line.len - 1) {
            self.index = null;
        } else {
            self.index = last + 1;
        }
        return .{
            .start = first,
            .end = last,
        };
    }
};

/// Return a slice of strings
fn readInput(in_file: std.fs.File, allocator: Allocator) ![][]u8 {
    const reader = in_file.reader();
    var list = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (list.items) |s| {
            allocator.free(s);
        }
        list.deinit();
    }
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 256)) |line| {
        try list.append(line);
    }
    return try list.toOwnedSlice();
}

fn findNextDigitStr(line: []const u8) DigitStrIterator {
    return .{ .index = 0, .line = line };
}

fn isSymbol(char: u8) bool {
    for (SymbolChars) |s| {
        if (char == s) {
            return true;
        }
    }
    return false;
}

/// Checks whether the string specified is adjacent to a symbol character
/// Adjacent can be diagonal as well
fn isPartNum(strings: []const []const u8, lineNo: usize, offsetStart: usize, offsetEnd: usize) bool {
    for (offsetStart..offsetEnd + 1) |offset| {
        // Special casing for start and end since we have to check diagonals and
        // an extra column
        if (offset == offsetStart) {
            // Could be improved, too much repitition
            // left upper diag
            if (offset > 0) {
                if (isSymbol(strings[lineNo][offset - 1])) {
                    return true;
                }
                if (lineNo > 0) {
                    if (isSymbol(strings[lineNo - 1][offset - 1])) {
                        return true;
                    }
                }
                if (lineNo + 1 < strings.len) {
                    if (isSymbol(strings[lineNo + 1][offset - 1])) {
                        return true;
                    }
                }
            }
        }
        if (offset == offsetEnd) {
            if (offset + 1 < strings[lineNo].len) {
                if (isSymbol(strings[lineNo][offset + 1])) {
                    return true;
                }
                if (lineNo > 0) {
                    if (isSymbol(strings[lineNo - 1][offset + 1])) {
                        return true;
                    }
                }
                if (lineNo + 1 < strings.len) {
                    if (isSymbol(strings[lineNo + 1][offset + 1])) {
                        return true;
                    }
                }
            }
        }

        // Above and below cases
        if (lineNo > 0) {
            if (isSymbol(strings[lineNo - 1][offset])) {
                return true;
            }
        }
        if (lineNo + 1 < strings.len) {
            if (isSymbol(strings[lineNo + 1][offset])) {
                return true;
            }
        }
    }
    return false;
}

pub fn main() !void {
    const in_fn = "input.txt";
    const in_file = try std.fs.cwd().openFile(in_fn, .{});
    defer in_file.close();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const strings = try readInput(in_file, allocator);
    defer {
        for (strings) |s| {
            allocator.free(s);
        }
        allocator.free(strings);
    }
    var sum_of_parts: u32 = 0;
    for (strings, 0..) |line, ln| {
        var digitsItr = findNextDigitStr(line);
        while (digitsItr.next()) |di| {
            const is_part = isPartNum(strings, ln, di.start, di.end);
            const part_num_str = strings[ln][di.start .. di.end + 1];
            const part_num = try std.fmt.parseInt(u32, part_num_str, 10);
            if (is_part) {
                //std.debug.print("Is a part number\n", .{});
                sum_of_parts += part_num;
            } else {
                std.debug.print("{d}: {d} Start index: {d}, end index {d}\n", .{ ln, part_num, di.start, di.end });
                std.debug.print("Is not a part number\n", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("Sum of all parts is: {d}\n", .{sum_of_parts});
}
