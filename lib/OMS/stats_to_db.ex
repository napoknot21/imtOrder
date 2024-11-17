defmodule ImtOrder.StatsToDb do
    @moduledoc """
    The `ImtOrder.StatsToDb` module provides a simplified interface for interacting with the `ImtOrder.CacheServer`.
    """


    @doc """
    Retrieves the statistics for a given `product_id` from the in-memory cache managed by the `ImtOrder.CacheServer`.
    """
    def get(product_id) do

        GenServer.call(ImtOrder.CacheServer, {:get_stats, product_id})

    end


    @doc """
    Adds a new statistic (quantity and price) for a given `product_id` to the in-memory cache and persists it via `ImtOrder.CacheServer`.
    """
    def add(product_id, {qty, price}) do

        GenServer.cast(ImtOrder.CacheServer, {:add_stats, product_id, {qty, price}})

    end


end
