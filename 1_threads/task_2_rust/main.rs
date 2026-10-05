use std::io::{self, Read};
use std::thread;

fn main() {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input).unwrap();
    let mut tokens = input.split_whitespace();

    let n: usize = match tokens.next() {
        Some(value) => value.parse().expect("N must be an integer"),
        None => return,
    };
    assert!(n > 0, "N must be positive");

    let values: Vec<i64> = (0..n)
        .map(|_| tokens.next().expect("Not enough values").parse().expect("Values must be integers"))
        .collect();

    let available = thread::available_parallelism()
        .map(|count| count.get())
        .unwrap_or(1);
    let worker_count = available.min(n);
    let chunk_size = (n + worker_count - 1) / worker_count;

    let (minimum, maximum) = thread::scope(|scope| {
        let handles: Vec<_> = values
            .chunks(chunk_size)
            .map(|chunk| {
                scope.spawn(move || {
                    chunk.iter().copied().fold(
                        (i64::MAX, i64::MIN),
                        |(local_min, local_max), value| {
                            (local_min.min(value), local_max.max(value))
                        },
                    )
                })
            })
            .collect();

        handles.into_iter().map(|handle| handle.join().unwrap()).fold(
            (i64::MAX, i64::MIN),
            |(global_min, global_max), (local_min, local_max)| {
                (global_min.min(local_min), global_max.max(local_max))
            },
        )
    });

    println!("min: {minimum}");
    println!("max: {maximum}");
}
