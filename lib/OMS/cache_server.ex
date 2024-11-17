defmodule ImtOrder.CacheServer do

	@moduledoc """
  	A GenServer module for managing product statistics in RAM and ensuring periodic integration of statistics from CSV files.
	"""

	use GenServer

	@doc """
	Starts the GenServer and initializes its state.
	The GenServer is named after the module (`ImtOrder.CacheServer`) and starts with an empty map as its state.
	"""
	def start_link(_) do

		GenServer.start_link(__MODULE__, [], name: __MODULE__)

	end


	@doc """
	Initializes the state of the GenServer.
	It sets an empty map as the initial state and schedules the first call to `:integrate_stats` after 5 seconds.
	"""
	def init(_) do

		Process.send_after(self(), :integrate_stats, 3000)
		{:ok, %{}}

	end


	@doc """
	Retrieves the statistics for a given `product_id` from RAM.
	This function is called via `GenServer.call/2` and returns a list of tuples representing quantity and price.
	"""
	def handle_call({:get_stats, product_id}, _from, state) do

		stats = Map.get(state, product_id, [])
		{:reply, stats, state}

	end


	@doc """
	Adds statistics for a product (identified by `product_id`) to the state.
	This function is called via `GenServer.cast/2` and adds a new tuple `{qty, price}` to the product's statistics list.
	"""
	def handle_cast({:add, product_id, {qty, price}}, state) do

		updated_stats = [{qty, price} | Map.get(state, product_id, [])]
		{:noreply, Map.put(state, product_id, updated_stats)}

	end


	@doc """
	Periodically integrates the statistics from files in the `data/` directory and then deletes the files.
	This function reads all CSV files matching `data/stat_*`, parses the data, and adds the statistics to the GenServer's state.
	After processing, the files are deleted to prevent redundant integration.
	The function also schedules the next call to `:integrate_stats` to occur after 5 seconds.
	"""
	def handle_info(:integrate_stats, state) do
		# Find all statistics files in the "data" directory
		stat_files = Path.wildcard("data/stat_*")

		# Read and integrate each file
		new_state = Enum.reduce(stat_files, state, fn file, acc_state ->

			stats = parse_file(file)

			Enum.reduce(stats, acc_state, fn {id, qty, price}, acc ->
				updated_stats = [{qty, price} | Map.get(acc, id, [])]
			  	Map.put(acc, id, updated_stats)
			end)

		end)

		Enum.each(stat_files, &File.rm!/1)

		# Persist the updated state in MicroDB
		persist_stats(new_state)

		Process.send_after(self(), :integrate_stats, 5000)

		{:noreply, new_state}

	end


	"""
	Private function that parses the contents of a statistics file and returns a list of tuples with product ID, quantity, and price.
	"""
	defp parse_file(file) do

		File.stream!(file)

		|> Enum.map(fn line ->
			[id, qty, price] = line |> String.trim() |> String.split(",")
		  	{String.to_integer(id), String.to_integer(qty), String.to_integer(price)}
		end)

	end


	"""
	Private function that persists the current state in MicroDB for long-term storage
	"""
	defp persist_stats(state) do

		Enum.each(state, fn {product_id, stats} ->
			MicroDb.HashTable.put("stats", product_id, stats)
		end)

	end

end
