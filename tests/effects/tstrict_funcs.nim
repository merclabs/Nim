discard """
  cmd: "nim c --experimental:strictFuncs --experimental:views $file"
"""

import tables, streams, parsecsv
# We import the below modules to check that they compile with `strictFuncs`.
# They are otherwise unused in this file.
import
  httpcore,
  math,
  nre,
  strutils,
  uri

type
  Contig2Reads = TableRef[string, seq[string]]

proc get_Contig2Reads(sin: Stream, fn: string, contig2len: TableRef[string, int]): Contig2Reads =
  result = newTable[string, seq[string]]()
  var parser: CsvParser
  open(parser, sin, filename = fn, separator = ' ', skipInitialSpace = true)
  while readRow(parser, 2):
    if contig2len.haskey(parser.row[1]):
      mgetOrPut(result, parser.row[1], @[]).add(parser.row[0])



block:
  # issue #15756
  func `&&&`[T](x: var seq[T], y: sink T): seq[T] =
    newSeq(result, x.len + 1)
    for i in 0..x.len-1:
      result[i] = move(x[i])
    result[x.len] = move(y)

  var x = @[0, 1]
  let z = x &&& 2
