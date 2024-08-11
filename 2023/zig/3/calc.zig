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

/// Return a slice of strings owned by the caller
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

fn inSlice(char: u8, symbol_chars: []const u8) ?u8 {
    for (symbol_chars) |s| {
        if (char == s) {
            return s;
        }
    }
    return null;
}

const SymbolPos = struct {
    symbol: u8,
    line: usize,
    offset: usize,
};

/// Checks whether the string specified is adjacent to a symbol character
/// Adjacent can be diagonal as well
fn findPartNum(
    strings: []const []const u8,
    lineNo: usize,
    offsetStart: usize,
    offsetEnd: usize,
    symbols: []const u8,
) ?SymbolPos {
    for (offsetStart..offsetEnd + 1) |offset| {
        // Special casing for start and end since we have to check diagonals and
        // an extra column
        if (offset == offsetStart) {
            // Could be improved, too much repitition
            if (offset > 0) {
                if (inSlice(strings[lineNo][offset - 1], symbols)) |s| {
                    return .{ .symbol = s, .line = lineNo, .offset = offset - 1 };
                }
                // left upper diag
                if (lineNo > 0) {
                    if (inSlice(strings[lineNo - 1][offset - 1], symbols)) |s| {
                        return .{ .symbol = s, .line = lineNo - 1, .offset = offset - 1 };
                    }
                }
                // left lower diag
                if (lineNo + 1 < strings.len) {
                    if (inSlice(strings[lineNo + 1][offset - 1], symbols)) |s| {
                        return .{ .symbol = s, .line = lineNo + 1, .offset = offset - 1 };
                    }
                }
            }
        }
        if (offset == offsetEnd) {
            if (offset + 1 < strings[lineNo].len) {
                if (inSlice(strings[lineNo][offset + 1], symbols)) |s| {
                    return .{ .symbol = s, .line = lineNo, .offset = offset + 1 };
                }
                if (lineNo > 0) {
                    if (inSlice(strings[lineNo - 1][offset + 1], symbols)) |s| {
                        return .{ .symbol = s, .line = lineNo - 1, .offset = offset + 1 };
                    }
                }
                if (lineNo + 1 < strings.len) {
                    if (inSlice(strings[lineNo + 1][offset + 1], symbols)) |s| {
                        return .{ .symbol = s, .line = lineNo + 1, .offset = offset + 1 };
                    }
                }
            }
        }

        // Above and below cases
        if (lineNo > 0) {
            if (inSlice(strings[lineNo - 1][offset], symbols)) |s| {
                return .{ .symbol = s, .line = lineNo - 1, .offset = offset };
            }
        }
        if (lineNo + 1 < strings.len) {
            if (inSlice(strings[lineNo + 1][offset], symbols)) |s| {
                return .{ .symbol = s, .line = lineNo + 1, .offset = offset };
            }
        }
    }
    return null;
}

const GearPart = std.meta.Tuple(&.{ []const u8, SymbolPos });
const GearPair = struct {
    symbol: SymbolPos,
    part1: []const u8,
    part2: []const u8,
};

// Takes a list of potential gears and returns a list of gears that have
// 2 part numbers connected to it
fn findGears(allocator: Allocator, potential_gears: std.ArrayList(GearPart)) ![]GearPair {
    var foundGears = std.ArrayList(GearPair).init(allocator);
    for (potential_gears.items, 0..) |g, i| {
        const gear_pos = g[1];
        // Search the rest of the list for a matching gear
        for (i + 1..potential_gears.items.len) |j| {
            const m = potential_gears.items[j];
            const other_pos = m[1];
            if (std.meta.eql(gear_pos, other_pos)) {
                try foundGears.append(.{ .symbol = gear_pos, .part1 = g[0], .part2 = m[0] });
            }
        }
    }
    return try foundGears.toOwnedSlice();
}

pub fn main() !void {
    //const in_fn = "i2.txt";
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
    var sum_of_gear_ratios: u32 = 0;
    var potential_gears = std.ArrayList(GearPart).init(allocator);
    defer potential_gears.deinit();
    for (strings, 0..) |line, ln| {
        var digitsItr = findNextDigitStr(line);
        while (digitsItr.next()) |di| {
            const symbol_found = findPartNum(strings, ln, di.start, di.end, SymbolChars);
            const gear_found = findPartNum(strings, ln, di.start, di.end, "*");
            const part_num_str = strings[ln][di.start .. di.end + 1];
            const part_num = try std.fmt.parseInt(u32, part_num_str, 10);
            if (gear_found) |g| {
                std.debug.print("Gear symbol found at Ln {d} , offset: {d}\n", .{ g.line, g.offset });
                try potential_gears.append(.{ part_num_str, g });
            }
            if (symbol_found) |_| {
                //std.debug.print("{d}: {d} Start index: {d}, end index {d}\n", .{ ln, part_num, di.start, di.end });
                //std.debug.print("Is a part number\n", .{});
                sum_of_parts += part_num;
            } else {
                //std.debug.print("Is not a part number\n", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("Sum of all parts is: {d}\n", .{sum_of_parts});
    const gear_pairs = try findGears(allocator, potential_gears);
    defer allocator.free(gear_pairs);
    for (gear_pairs) |g| {
        std.debug.print(
            "Found a gear pair at ln {d}, offset: {d} Part 1: {s}, Part 2: {s}\n",
            .{ g.symbol.line, g.symbol.offset, g.part1, g.part2 },
        );
        const ratio1: u32 = try std.fmt.parseInt(u32, g.part1, 10);
        const ratio2: u32 = try std.fmt.parseInt(u32, g.part2, 10);
        const gear_ratio = ratio1 * ratio2;
        sum_of_gear_ratios += gear_ratio;
    }
    std.debug.print("Sum of gear ratios is {d}\n", .{sum_of_gear_ratios});
}
