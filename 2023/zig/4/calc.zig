const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;

const ParseError = error{
    CardSplitError,
    VertSplitError,
};

fn is_whitepace_str(str: []const u8) bool {
    for (str) |s| {
        if (s != ' ') return false;
    }
    return true;
}

const Card = struct {
    card_num: u32,
    winning_numbers: []u32,
    our_numbers: []u32,
};

/// Callers responsiblity to free each Card and the slice
fn parse_input(allocator: mem.Allocator, reader: anytype) ![]*Card {
    var buf: [256]u8 = undefined;

    var cards = std.ArrayList(*Card).init(allocator);
    errdefer cards.deinit();
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const current_card = try allocator.create(Card);
        errdefer allocator.destroy(current_card);
        //std.debug.print("Next line is: {s}\n", .{line});
        var colon_itr = mem.splitScalar(u8, line, ':');
        const card_num_str = colon_itr.next() orelse return ParseError.CardSplitError;
        var card_num_str_itr = mem.tokenizeScalar(u8, card_num_str, ' ');
        _ = card_num_str_itr.next();
        const card_num = try fmt.parseInt(u32, card_num_str_itr.next().?, 10);
        current_card.card_num = card_num;
        const rest = colon_itr.next() orelse return ParseError.CardSplitError;
        var vert_split_itr = mem.splitScalar(u8, rest, '|');
        const winning_numbers = vert_split_itr.next() orelse return ParseError.VertSplitError;
        const our_numbers = vert_split_itr.next() orelse return ParseError.VertSplitError;
        var win_num_itr = mem.tokenizeScalar(u8, winning_numbers, ' ');
        var our_num_itr = mem.tokenizeScalar(u8, our_numbers, ' ');
        var winning_list = std.ArrayList(u32).init(allocator);
        var our_list = std.ArrayList(u32).init(allocator);
        while (win_num_itr.next()) |win_num_str| {
            const win_num_int = try fmt.parseInt(u32, win_num_str, 10);
            try winning_list.append(win_num_int);
        }
        while (our_num_itr.next()) |our_num_str| {
            const our_num_int = try fmt.parseInt(u32, our_num_str, 10);
            try our_list.append(our_num_int);
        }
        current_card.*.winning_numbers = try winning_list.toOwnedSlice();
        current_card.*.our_numbers = try our_list.toOwnedSlice();
        try cards.append(current_card);
    }
    return try cards.toOwnedSlice();
}

// Better way to do this??
fn print_slice(items: []u32) void {
    for (items[0 .. items.len - 2]) |i| {
        std.debug.print("{d} ", .{i});
    }
    std.debug.print("{d}\n", .{items[items.len - 1]});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var argsItr = try std.process.argsWithAllocator(allocator);
    defer argsItr.deinit();
    var fn_name: []const u8 = "input.txt";
    if (argsItr.skip()) {
        if (argsItr.next()) |cmd_fn| {
            fn_name = cmd_fn;
        }
    }

    const in_file = try std.fs.cwd().openFile(fn_name, .{});
    const reader = in_file.reader();
    var total_points: u32 = 0;
    _ = &total_points;
    const cardList = try parse_input(allocator, reader);
    defer {
        for (cardList) |card| {
            allocator.free(card.our_numbers);
            allocator.free(card.winning_numbers);
            allocator.destroy(card);
        }
        allocator.free(cardList);
    }
    for (cardList) |card| {
        var winning_set = std.AutoHashMap(u32, void).init(allocator);
        defer winning_set.deinit();
        var our_set = std.AutoHashMap(u32, void).init(allocator);
        defer our_set.deinit();
        for (card.winning_numbers) |win_num| {
            try winning_set.put(win_num, {});
        }
        for (card.our_numbers) |our_num| {
            try our_set.put(our_num, {});
        }
        var our_key_itr = our_set.keyIterator();
        var won_count: u32 = 0;
        while (our_key_itr.next()) |k| {
            const k_val = k.*;
            if (winning_set.get(k_val)) |_| {
                won_count += 1;
            }
        }
        mem.sort(u32, card.winning_numbers, {}, comptime std.sort.asc(u32));
        mem.sort(u32, card.our_numbers, {}, comptime std.sort.asc(u32));
        std.debug.print("Card: {d}\n", .{card.card_num});
        std.debug.print("Winning numbers: ", .{});
        print_slice(card.winning_numbers);
        std.debug.print("Our numbers: ", .{});
        print_slice(card.our_numbers);
        if (won_count > 0) {
            const points = math.pow(u32, 2, won_count - 1);
            total_points += points;
            std.debug.print("You have {d} matching numbers, {d} points\n", .{ won_count, points });
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("Total points: {d}\n", .{total_points});
}
