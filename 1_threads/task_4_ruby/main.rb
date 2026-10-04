require "thread"

# Input format:
# initial_balance thread_count operation_count
# followed by operation_count lines: deposit amount | withdraw amount
# Run: ruby main.rb
# Amounts are non-negative integer currency units.
# Thread scheduling can affect which withdrawals succeed.
class BankAccount
  def initialize(initial_balance)
    @balance = initial_balance
    @successful_operations = 0
    @rejected_operations = 0
    @mutex = Mutex.new
  end

  def apply(operation, amount)
    @mutex.synchronize do
      case operation
      when "deposit"
        @balance += amount
        @successful_operations += 1
      when "withdraw"
        if @balance >= amount
          @balance -= amount
          @successful_operations += 1
        else
          @rejected_operations += 1
        end
      else
        @rejected_operations += 1
      end
    end
  end

  def snapshot
    @mutex.synchronize { [@balance, @successful_operations, @rejected_operations] }
  end
end

tokens = STDIN.read.split
exit if tokens.empty?

initial_balance = Integer(tokens.shift)
thread_count = Integer(tokens.shift)
operation_count = Integer(tokens.shift)
raise ArgumentError, "initial_balance must be non-negative" if initial_balance < 0
raise ArgumentError, "thread_count must be positive" if thread_count <= 0
raise ArgumentError, "operation_count must be non-negative" if operation_count < 0

operations = operation_count.times.map do
  operation = tokens.shift
  amount = Integer(tokens.shift)
  raise ArgumentError, "amount must be non-negative" if amount < 0
  raise ArgumentError, "unknown operation" unless ["deposit", "withdraw"].include?(operation)
  [operation, amount]
end

account = BankAccount.new(initial_balance)
worker_count = [thread_count, operations.length].min
threads = worker_count.times.map do |worker_index|
  Thread.new do
    operations.each_with_index do |(operation, amount), index|
      account.apply(operation, amount) if index % worker_count == worker_index
    end
  end
end

threads.each(&:join)
balance, successful, rejected = account.snapshot
puts "Final balance: #{balance}"
puts "Successful operations: #{successful}"
puts "Rejected operations: #{rejected}"
