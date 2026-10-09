open System
open System.Collections.Generic
open System.IO
open System.Text
open System.Text.Json

let parseCsv (text: string) =
    let rows = ResizeArray<string list>()
    let row = ResizeArray<string>()
    let field = StringBuilder()
    let mutable insideQuotes = false
    let mutable index = 0

    let finishField () =
        row.Add(field.ToString())
        field.Clear() |> ignore

    let finishRow () =
        finishField ()
        rows.Add(List.ofSeq row)
        row.Clear()

    while index < text.Length do
        let character = text[index]

        if insideQuotes then
            if character = '"' then
                if index + 1 < text.Length && text[index + 1] = '"' then
                    field.Append('"') |> ignore
                    index <- index + 2
                else
                    insideQuotes <- false
                    index <- index + 1
            else
                field.Append(character) |> ignore
                index <- index + 1
        else
            match character with
            | '"' when field.Length = 0 ->
                insideQuotes <- true
                index <- index + 1
            | '"' ->
                failwith "Unexpected quote inside an unquoted field"
            | ',' ->
                finishField ()
                index <- index + 1
            | '\n' ->
                finishRow ()
                index <- index + 1
            | '\r' ->
                finishRow ()
                if index + 1 < text.Length && text[index + 1] = '\n' then
                    index <- index + 2
                else
                    index <- index + 1
            | _ ->
                field.Append(character) |> ignore
                index <- index + 1

    if insideQuotes then
        failwith "Unclosed quoted field"

    if field.Length > 0 || row.Count > 0 then
        finishRow ()

    List.ofSeq rows

let convertCsvToJson inputPath outputPath =
    let rows = File.ReadAllText(inputPath, Encoding.UTF8) |> parseCsv

    match rows with
    | [] -> failwith "The CSV file is empty"
    | headers :: dataRows ->
        if headers |> List.exists String.IsNullOrWhiteSpace then
            failwith "CSV headers must not be empty"

        if (headers |> Set.ofList |> Set.count) <> headers.Length then
            failwith "CSV headers must be unique"

        let objects =
            dataRows
            |> List.mapi (fun rowIndex values ->
                if values.Length <> headers.Length then
                    failwith $"Row {rowIndex + 2} contains {values.Length} fields instead of {headers.Length}"

                let item = Dictionary<string, string>()
                List.iter2 (fun header value -> item.Add(header, value)) headers values
                item)

        let options = JsonSerializerOptions(WriteIndented = true)
        let json = JsonSerializer.Serialize(objects, options)
        File.WriteAllText(outputPath, json, UTF8Encoding(false))
        printfn "Converted %d records to %s" objects.Length outputPath

let arguments = fsi.CommandLineArgs |> Array.skip 1
let inputPath = if arguments.Length > 0 then arguments[0] else "input.csv"
let outputPath = if arguments.Length > 1 then arguments[1] else "output.json"

try
    convertCsvToJson inputPath outputPath
with error ->
    eprintfn "Error: %s" error.Message
    Environment.ExitCode <- 1
