#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Alex Mitchell
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Alex Mitchell
##
## This module implements operations for the built-in `seq`:idx: type which
## were inspired by functional programming languages. If you are looking for
## the typical `map` function which applies a function to every element in a
## sequence, it already exists in the `system <system.html>`_ module in both
## mutable and immutable styles.
##
## Also, for functional style programming you may want to pass `anonymous procs
## <manual.html#anonymous-procs>`_ to procs like ``filter`` to reduce typing.
## Anonymous procs can use `the special do notation <manual.html#do-notation>`_
## which is more convenient in certain situations.
##
## **Note**: This interface will change as soon as the compiler supports
## closures and proper coroutines.

when not defined(nimhygiene):
  {.pragma: dirty.}

proc concat*[T](seqs: varargs[seq[T]]): seq[T] =
  ## Takes several sequences' items and returns them inside a new sequence.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     s1 = @[1, 2, 3]
  ##     s2 = @[4, 5]
  ##     s3 = @[6, 7]
  ##     total = concat(s1, s2, s3)
  ##   assert total == @[1, 2, 3, 4, 5, 6, 7]
  var L = 0
  for seqitm in items(seqs): inc(L, len(seqitm))
  newSeq(result, L)
  var i = 0
  for s in items(seqs):
    for itm in items(s):
      result[i] = itm
      inc(i)

proc distnct*[T](seq1: seq[T]): seq[T] =
  ## Returns a new sequence without duplicates.
  ##
  ## This proc is `misspelled` on purpose to avoid a clash with the keyword
  ## ``distinct`` used to `define a derived type incompatible with its base
  ## type <manual.html#distinct-type>`_. Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
  ##     dup2 = @["a", "a", "c", "d", "d"]
  ##     unique1 = distnct(dup1)
  ##     unique2 = distnct(dup2)
  ##   assert unique1 == @[1, 3, 4, 2, 8]
  ##   assert unique2 == @["a", "c", "d"]
  result = @[]
  for itm in items(seq1):
    if not result.contains(itm): result.add(itm)
    
proc zip*[S, T](seq1: seq[S], seq2: seq[T]): seq[tuple[a: S, b: T]] =
  ## Returns a new sequence with a combination of the two input sequences.
  ##
  ## For convenience you can access the returned tuples through the named
  ## fields `a` and `b`. If one sequence is shorter, the remaining items in the
  ## longer sequence are discarded. Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     short = @[1, 2, 3]
  ##     long = @[6, 5, 4, 3, 2, 1]
  ##     words = @["one", "two", "three"]
  ##     zip1 = zip(short, long)
  ##     zip2 = zip(short, words)
  ##   assert zip1 == @[(1, 6), (2, 5), (3, 4)]
  ##   assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
  ##   assert zip1[2].b == 4
  ##   assert zip2[2].b == "three"
  var m = min(seq1.len, seq2.len)
  newSeq(result, m)
  for i in 0 .. m-1: result[i] = (seq1[i], seq2[i])

iterator filter*[T](seq1: seq[T], pred: proc(item: T): bool {.closure.}): T =
  ## Iterates through a sequence and yields every item that fulfills the
  ## predicate.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let numbers = @[1, 4, 5, 8, 9, 7, 4]
  ##   for n in filter(numbers, proc (x: int): bool = x mod 2 == 0):
  ##     echo($n)
  ##   # echoes 4, 8, 4 in separate lines
  for i in countup(0, len(seq1) -1):
    var item = seq1[i]
    if pred(item): yield seq1[i]

proc filter*[T](seq1: seq[T], pred: proc(item: T): bool {.closure.}): seq[T] =
  ## Returns a new sequence with all the items that fulfilled the predicate.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     colors = @["red", "yellow", "black"]
  ##     f1 = filter(colors, proc(x: string): bool = x.len < 6)
  ##     f2 = filter(colors) do (x: string) -> bool : x.len > 5
  ##   assert f1 == @["red", "black"]
  ##   assert f2 == @["yellow"]
  accumulateResult(filter(seq1, pred))

template filterIt*(seq1, pred: expr): expr {.immediate, dirty.} =
  ## Returns a new sequence with all the items that fulfilled the predicate.
  ##
  ## Unlike the `proc` version, the predicate needs to be an expression using
  ## the ``it`` variable for testing, like: ``filterIt("abcxyz", it == 'x')``.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##    let
  ##      temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
  ##      acceptable = filterIt(temperatures, it < 50 and it > -10)
  ##    assert acceptable == @[-2.0, 24.5, 44.31]
  var result {.gensym.}: type(seq1) = @[]
  for it in items(seq1):
    if pred: result.add(it)
  result

template toSeq*(iter: expr): expr {.immediate.} =
  ## Transforms any iterator into a sequence.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
  ##     odd_numbers = toSeq(filter(numeric) do (x: int) -> bool:
  ##       if x mod 2 == 1:
  ##         result = true)
  ##   assert odd_numbers == @[1, 3, 5, 7, 9]
  ##
  var result {.gensym.}: seq[type(iter)] = @[]
  for x in iter: add(result, x)
  result

when isMainModule:
  import strutils
  proc toStr(x: int): string {.procvar.} = $x
  # concat test
  let
    s1 = @[1, 2, 3]
    s2 = @[4, 5]
    s3 = @[6, 7]
    total = concat(s1, s2, s3)
  assert total == @[1, 2, 3, 4, 5, 6, 7]

  # duplicates test
  let
    dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
    dup2 = @["a", "a", "c", "d", "d"]
    unique1 = distnct(dup1)
    unique2 = distnct(dup2)
  assert unique1 == @[1, 3, 4, 2, 8]
  assert unique2 == @["a", "c", "d"]

  # zip test
  let
    short = @[1, 2, 3]
    long = @[6, 5, 4, 3, 2, 1]
    words = @["one", "two", "three"]
    zip1 = zip(short, long)
    zip2 = zip(short, words)
  assert zip1 == @[(1, 6), (2, 5), (3, 4)]
  assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
  assert zip1[2].b == 4
  assert zip2[2].b == "three"

  # filter proc test
  let
    colors = @["red", "yellow", "black"]
    f1 = filter(colors, proc(x: string): bool = x.len < 6)
    f2 = filter(colors) do (x: string) -> bool : x.len > 5
  assert f1 == @["red", "black"]
  assert f2 == @["yellow"]

  # filter iterator test
  let numbers = @[1, 4, 5, 8, 9, 7, 4]
  for n in filter(numbers, proc (x: int): bool = x mod 2 == 0):
    echo($n)
  # echoes 4, 8, 4 in separate lines

  # filterIt test
  let
    temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
    acceptable = filterIt(temperatures, it < 50 and it > -10)
  assert acceptable == @[-2.0, 24.5, 44.31]

  # toSeq test
  let
    numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
    odd_numbers = toSeq(filter(numeric) do (x: int) -> bool:
      if x mod 2 == 1:
        result = true)
  assert odd_numbers == @[1, 3, 5, 7, 9]

  echo "Finished doc tests"
