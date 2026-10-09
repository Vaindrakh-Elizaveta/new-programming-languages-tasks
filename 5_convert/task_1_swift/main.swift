import Foundation

enum CSVError: Error, CustomStringConvertible {
    case unexpectedQuote
    case unclosedQuotedField

    var description: String {
        switch self {
        case .unexpectedQuote:
            return "Unexpected quote inside an unquoted field"
        case .unclosedQuotedField:
            return "Unclosed quoted field"
        }
    }
}

func parseCSV(_ text: String) throws -> [[String]] {
    var rows: [[String]] = []
    var row: [String] = []
    var field = ""
    var insideQuotes = false
    var index = text.startIndex

    func nextIndex(after position: String.Index) -> String.Index {
        text.index(after: position)
    }

    while index < text.endIndex {
        let character = text[index]

        if insideQuotes {
            if character == "\"" {
                let next = nextIndex(after: index)
                if next < text.endIndex && text[next] == "\"" {
                    field.append("\"")
                    index = nextIndex(after: next)
                } else {
                    insideQuotes = false
                    index = next
                }
            } else {
                field.append(character)
                index = nextIndex(after: index)
            }
            continue
        }

        if character == "\"" {
            if !field.isEmpty {
                throw CSVError.unexpectedQuote
            }
            insideQuotes = true
            index = nextIndex(after: index)
        } else if character == "," {
            row.append(field)
            field = ""
            index = nextIndex(after: index)
        } else if character == "\n" || character == "\r" {
            row.append(field)
            rows.append(row)
            row = []
            field = ""

            if character == "\r" {
                let next = nextIndex(after: index)
                if next < text.endIndex && text[next] == "\n" {
                    index = nextIndex(after: next)
                } else {
                    index = next
                }
            } else {
                index = nextIndex(after: index)
            }
        } else {
            field.append(character)
            index = nextIndex(after: index)
        }
    }

    if insideQuotes {
        throw CSVError.unclosedQuotedField
    }

    if !field.isEmpty || !row.isEmpty {
        row.append(field)
        rows.append(row)
    }

    return rows
}

func escapeTSVField(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\t", with: "\\t")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\n", with: "\\n")
}

let arguments = CommandLine.arguments
let inputPath = arguments.count > 1 ? arguments[1] : "input.csv"
let outputPath = arguments.count > 2 ? arguments[2] : "output.tsv"

do {
    let input = try String(contentsOfFile: inputPath, encoding: .utf8)
    let rows = try parseCSV(input)
    let output = rows
        .map { $0.map(escapeTSVField).joined(separator: "\t") }
        .joined(separator: "\n")
    let finalOutput = output.isEmpty ? "" : output + "\n"
    try finalOutput.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("Converted \(rows.count) rows to \(outputPath)")
} catch {
    FileHandle.standardError.write(Data("Error: \(error)\n".utf8))
    exit(1)
}
