let
  lib = import ../getlib.nix;
  inFile = lib.readFile ./input.txt;
  file_lines = lib.strings.splitString "\n" inFile;
  file_lines_no_empty = builtins.filter (s: (builtins.stringLength s) > 0) file_lines;
  num_list = builtins.map (
    x:
    let
      strs = lib.strings.splitString "   " x;
    in
    [
      (lib.toInt (builtins.elemAt strs 0))
      (lib.toInt (builtins.elemAt strs 1))
    ]
  ) file_lines_no_empty;
  abs = x: if x > 0 then x else x * -1;
  sumList = lst: builtins.foldl' (x: y: x + y) 0 lst;
  firsts =
    let
      unsorted_firsts = builtins.map (x: builtins.elemAt x 0) num_list;
    in
    builtins.sort builtins.lessThan unsorted_firsts;
  seconds =
    let
      unsorted_seconds = builtins.map (x: builtins.elemAt x 1) num_list;
    in
    builtins.sort builtins.lessThan unsorted_seconds;
  distances = lib.zipListsWith (a: b: abs (a - b)) firsts seconds;

  countOcc = l: x: builtins.foldl' (a: b: a + (if b == x then 1 else 0)) 0 l;
in
let
  f = lib.debug.traceSeq firsts firsts;
  s = lib.debug.traceSeq seconds seconds;
  distSum = sumList distances;
  simMap = builtins.map (x: x * (countOcc seconds x)) firsts;
  simSum = sumList simMap;
in
{
  part1 = distSum;
  part2 = simSum;
}
