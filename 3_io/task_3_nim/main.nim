import os
import strutils

proc main() =
  let inputPath = if paramCount() >= 1: paramStr(1) else: "numbers.txt"
  let evenPath = if paramCount() >= 2: paramStr(2) else: "even.txt"
  let oddPath = if paramCount() >= 3: paramStr(3) else: "odd.txt"

  var inputFile: File
  if not open(inputFile, inputPath, fmRead):
    quit("Cannot open input file: " & inputPath, QuitFailure)
  defer: inputFile.close()

  var evenFile: File
  if not open(evenFile, evenPath, fmWrite):
    quit("Cannot create output file: " & evenPath, QuitFailure)
  defer: evenFile.close()

  var oddFile: File
  if not open(oddFile, oddPath, fmWrite):
    quit("Cannot create output file: " & oddPath, QuitFailure)
  defer: oddFile.close()

  var evenCount = 0
  var oddCount = 0
  var lineNumber = 0

  for line in inputFile.lines:
    inc lineNumber
    let valueText = line.strip()
    if valueText.len == 0:
      continue

    try:
      let value = parseInt(valueText)
      if value mod 2 == 0:
        evenFile.writeLine(value)
        inc evenCount
      else:
        oddFile.writeLine(value)
        inc oddCount
    except ValueError:
      stderr.writeLine("Skipped invalid value on line " & $lineNumber & ": " & line)

  echo "Even numbers: ", evenCount
  echo "Odd numbers: ", oddCount

main()
