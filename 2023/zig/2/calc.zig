const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const fmt = std.fmt;
const expect = std.testing.expect;

const ParseError = error{
    GameDivNotFound,
    InvalidColor,
};

fn read_line(reader: anytype, buffer: []u8) !?[]const u8 {
    return try reader.readUntilDelimiterOrEof(buffer, '\n');
}

const GameSet = struct {
    red_cubes: u32 = 0,
    green_cubes: u32 = 0,
    blue_cubes: u32 = 0,
};

fn get_subgame(subgame_str: []const u8, game_set: *GameSet) !void {
    const dice_trim = std.mem.trim(u8, subgame_str, " ");
    var dice_str_itr = std.mem.splitScalar(u8, dice_trim, ' ');
    const num_dice_str = dice_str_itr.next().?;
    const color = dice_str_itr.next().?;
    const num_dice = try fmt.parseInt(u32, num_dice_str, 10);
    if (mem.eql(u8, color, "red")) {
        game_set.*.red_cubes = num_dice;
    } else if (mem.eql(u8, color, "green")) {
        game_set.*.green_cubes = num_dice;
    } else if (mem.eql(u8, color, "blue")) {
        game_set.*.blue_cubes = num_dice;
    } else {
        return ParseError.InvalidColor;
    }
}

fn dice_required(game_str: []const u8, game_set: *GameSet) !void {
    var game_itr = std.mem.splitScalar(u8, game_str, ';');
    var max_set: GameSet = .{};
    while (game_itr.next()) |game| {
        var dice_itr = std.mem.splitScalar(u8, game, ',');
        while (dice_itr.next()) |dice| {
            var current_game_set: GameSet = .{};
            try get_subgame(dice, &current_game_set);
            // Can we use meta programming here to do this for every field in the Gameset
            if (current_game_set.red_cubes > max_set.red_cubes) {
                max_set.red_cubes = current_game_set.red_cubes;
            }
            if (current_game_set.green_cubes > max_set.green_cubes) {
                max_set.green_cubes = current_game_set.green_cubes;
            }
            if (current_game_set.blue_cubes > max_set.blue_cubes) {
                max_set.blue_cubes = current_game_set.blue_cubes;
            }
        }
    }
    game_set.* = max_set;
}

/// Takes a string with sub games seperated by ;
/// Checks that each subgame does not violate the restrictions
/// and returns true if so else false
fn is_game_valid(game_str: []const u8) !bool {
    const max_red: u32 = 12;
    const max_green: u32 = 13;
    const max_blue: u32 = 14;
    var game_itr = std.mem.splitScalar(u8, game_str, ';');
    var game_valid = true;
    while (game_itr.next()) |game| {
        std.debug.print("Next sub game is: {s}\n", .{game});
        var dice_itr = std.mem.splitScalar(u8, game, ',');
        while (dice_itr.next()) |dice| {
            var game_set: GameSet = .{};
            try get_subgame(dice, &game_set);

            // Does this game violate the restrictions?
            if (game_set.red_cubes > max_red or game_set.green_cubes > max_green or game_set.blue_cubes > max_blue) {
                game_valid = false;
                break;
            }
        }
    }
    return game_valid;
}

fn dice_power(game_set: GameSet) u32 {
    return game_set.red_cubes * game_set.green_cubes * game_set.blue_cubes;
}

pub fn main() !void {
    const in_file = try fs.cwd().openFile("input.txt", .{});
    defer in_file.close();
    var buff: [256]u8 = undefined;
    var sum_of_games: u32 = 0;
    var sum_of_powers: u32 = 0;
    while (try read_line(in_file.reader(), &buff)) |line| {
        std.debug.print("Next line is {s}\n", .{line});
        const game_div = mem.indexOf(u8, line, ":");
        if (game_div == null) {
            return ParseError.GameDivNotFound;
        }
        const game_str = line[0..game_div.?];
        const rem_str = line[game_div.? + 1 ..];
        const game_str_prefix = game_str["Game ".len..];
        const game_num = try fmt.parseInt(u32, game_str_prefix, 10);
        const game_valid = try is_game_valid(rem_str);
        var max_dice: GameSet = .{};
        try dice_required(rem_str, &max_dice);
        if (!game_valid) {
            std.debug.print("Game number {d} is not valid\n", .{game_num});
        }
        if (game_valid) {
            sum_of_games += game_num;
            std.debug.print("Adding valid game number {d}. Total is now: {d}\n", .{ game_num, sum_of_games });
        }
        std.debug.print("Dice required for game: Red {d}, Green {d} Blue {d}\n", .{ max_dice.red_cubes, max_dice.green_cubes, max_dice.blue_cubes });
        const game_power = dice_power(max_dice);
        std.debug.print("Game power: {d}\n", .{game_power});
        sum_of_powers += game_power;
        std.debug.print("\n", .{});
    }
    std.debug.print("The final sum of games is {d}\n", .{sum_of_games});
    std.debug.print("Sume of game powers is {d}\n", .{sum_of_powers});
}

test "Get max game test" {
    var game_set: GameSet = .{};
    const game_test = "3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    try dice_required(game_test, &game_set);
    try expect(game_set.red_cubes == 4);
    try expect(game_set.green_cubes == 2);
    try expect(game_set.blue_cubes == 6);
}

test "Power func" {
    const game_set: GameSet = GameSet{ .red_cubes = 4, .green_cubes = 2, .blue_cubes = 6 };
    try expect(dice_power(game_set) == 48);
}
