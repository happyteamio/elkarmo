defmodule Elkarmo.Store do
  use GenServer

  def start_link(karma), do: GenServer.start_link(__MODULE__, karma, name: __MODULE__)

  def get, do: GenServer.call __MODULE__, :get

  def set(new_karma), do: GenServer.cast __MODULE__, {:set, new_karma}

  def init(initial_karma) do
    {:ok, table} = :dets.open_file(:karma_db, [type: :set])
    karma = case :dets.lookup(table, :karma) do
      [karma: found_karma] -> found_karma
      [] -> initial_karma
    end

    {:ok, karma}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_cast({:set, new_karma}, _current_karma) do
    :dets.insert(:karma, {:karma, new_karma})
    :dets.sync(:karma)
    {:noreply, new_karma}
  end

  def terminate(_reason, _state) do
    :dets.close(:karma_db)
  end
end
