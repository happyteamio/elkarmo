defmodule Elkarmo.Store do
  use GenServer

  def start_link(karma), do: GenServer.start_link(__MODULE__, karma, name: __MODULE__)

  def get, do: GenServer.call(__MODULE__, :get)

  def set(new_karma), do: GenServer.cast(__MODULE__, {:set, new_karma})

  def init(initial_karma) do
    db_file = ensure_file() |> to_charlist

    {:ok, table} = :dets.open_file(db_file, type: :set)

    karma =
      case :dets.lookup(table, :karma) do
        [karma: found_karma] -> found_karma
        [] -> initial_karma
      end

    {:ok, {db_file, karma}}
  end

  defp ensure_file() do
    cwd = File.cwd!()
    path = Path.join(cwd, "data")

    if !File.dir?(path) do
      File.mkdir!(path)
    end

    Path.join(path, "karma_db")
  end

  def handle_call(:get, _from, state = {_db_file, karma}), do: {:reply, karma, state}

  def handle_cast({:set, new_karma}, {db_file, _current_karma}) do
    :dets.insert(db_file, {:karma, new_karma})
    :dets.sync(db_file)
    {:noreply, {db_file, new_karma}}
  end

  def terminate(_reason, _state = {db_file, _karma}) do
    :dets.close(db_file)
  end
end
