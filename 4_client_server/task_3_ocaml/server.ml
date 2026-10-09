open Unix

let port = 4043

let is_prime number =
  if number < 2 then false
  else
    let rec check divisor =
      if divisor > number / divisor then true
      else if number mod divisor = 0 then false
      else check (divisor + 1)
    in
    check 2

let describe_number number =
  let parity = if number mod 2 = 0 then "even" else "odd" in
  let primality =
    if number < 2 then "not prime (numbers below 2 are not prime)"
    else if is_prime number then "prime"
    else "not prime"
  in
  Printf.sprintf "%d: %s, %s" number primality parity

let process_request request =
  let text = String.trim request in
  if String.uppercase_ascii text = "QUIT" then ("BYE", true)
  else
    try (describe_number (int_of_string text), false)
    with Failure _ -> ("ERROR expected an integer", false)

let handle_client descriptor =
  let input = in_channel_of_descr descriptor in
  let output = out_channel_of_descr descriptor in
  let rec loop () =
    match input_line input with
    | request ->
        let response, should_close = process_request request in
        output_string output (response ^ "\n");
        flush output;
        if not should_close then loop ()
    | exception End_of_file -> ()
  in
  (try loop () with Sys_error _ -> ());
  close_in_noerr input;
  close_out_noerr output

let () =
  let server = socket PF_INET SOCK_STREAM 0 in
  setsockopt server SO_REUSEADDR true;
  bind server (ADDR_INET (inet_addr_any, port));
  listen server 10;
  Printf.printf "Number server is listening on port %d\n%!" port;
  while true do
    let client, _ = accept server in
    handle_client client
  done
