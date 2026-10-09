open Unix

let host = if Array.length Sys.argv > 1 then Sys.argv.(1) else "127.0.0.1"
let port = if Array.length Sys.argv > 2 then int_of_string Sys.argv.(2) else 4043

let () =
  let address = (gethostbyname host).h_addr_list.(0) in
  let socket_descriptor = socket PF_INET SOCK_STREAM 0 in
  connect socket_descriptor (ADDR_INET (address, port));
  let input = in_channel_of_descr socket_descriptor in
  let output = out_channel_of_descr socket_descriptor in
  Printf.printf "Connected to %s:%d\n%!" host port;
  let rec loop () =
    print_string "> ";
    flush stdout;
    match read_line () with
    | request ->
        output_string output (request ^ "\n");
        flush output;
        let response = input_line input in
        Printf.printf "Server: %s\n%!" response;
        if String.uppercase_ascii (String.trim request) <> "QUIT" then loop ()
    | exception End_of_file -> ()
  in
  (try loop () with End_of_file -> ());
  close_in_noerr input;
  close_out_noerr output
