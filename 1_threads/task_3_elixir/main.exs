defmodule FrequencyCounter do
  # Input format: N followed by N integer values.
  # Each chunk is counted by a separate Elixir task.
  # Run: elixir main.exs
  # Elixir tasks are lightweight BEAM processes scheduled on OS threads.
  def run do
    tokens = IO.read(:all) |> String.split()

    case tokens do
      [] -> :ok
      [n_token | value_tokens] ->
        n = String.to_integer(n_token)
        if n <= 0, do: raise(ArgumentError, "N must be positive")
        values = value_tokens |> Enum.take(n) |> Enum.map(&String.to_integer/1)

        if n <= 0 or length(values) != n do
          raise ArgumentError, "N must be positive and the input must contain N values"
        end

        workers = min(System.schedulers_online(), n)
        chunk_size = div(n + workers - 1, workers)

        frequencies =
          values
          |> Enum.chunk_every(chunk_size)
          |> Task.async_stream(&count_chunk/1,
            max_concurrency: workers,
            ordered: false,
            timeout: :infinity
          )
          |> Enum.reduce(%{}, fn {:ok, local_counts}, global_counts ->
            Map.merge(global_counts, local_counts, fn _key, left, right -> left + right end)
          end)

        frequencies
        |> Enum.sort_by(fn {value, _count} -> value end)
        |> Enum.each(fn {value, count} -> IO.puts("#{value}: #{count}") end)
    end
  end

  defp count_chunk(chunk) do
    Enum.reduce(chunk, %{}, fn value, counts ->
      Map.update(counts, value, 1, &(&1 + 1))
    end)
  end
end

FrequencyCounter.run()
