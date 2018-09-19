defmodule Cache.Server do
  @moduledoc """
  Documentation for Cache.
  """
  use GenServer

  @name CH

  ## Client API
  ##  en esta sección, como indica el nombre se pone todo lo que puede ver el cliente
  @doc """
  Inicia el proceso para el caché.
  """
  def start_link(opts \\ []) do
    # Process.flag(:trap_exit, true)
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: CH])
  end

  @doc """
  Escribe un valor en el caché.
  """
  def write(key, value) do
    # GenServer.call realiza un llamado sincrónico
    IO.puts "escribiendo #{key}"
    GenServer.call(@name, {:write, key, value})
    Node.list |> :rpc.multicall(Cache.Server, :replication_write, [key, value])
    {:ok}
  end

  @doc """
  Escribe un valor en el caché.
  """
  def replication_write(key, value) do
    # GenServer.call realiza un llamado sincrónico
    IO.puts "escribiendo #{key}"
    GenServer.call(@name, {:write, key, value})
  end

  @doc """
  Busca un valor en el caché.
  """
  def read(key) do
    GenServer.call(@name, {:read, key})
  end

  @doc """
  Borra un valor del caché.
  """
  def delete(key) do
    GenServer.call(@name, {:delete, key})
  end

  @doc """
  Limpia el cache
  """
  def clear do
    GenServer.cast(@name, {:clear})
  end

  @doc """
  Determina si existe la key en cache
  """
  def exist?(key) do
    GenServer.call(@name, {:exist?, key})
  end

  @doc """
  Devuelve el listado completo de elementos en cache
  """
  def get_stats do
    GenServer.call(@name, {:get_stats})
  end

  ## server callbacks
  ##  en esta sección se ponen las funciones que actúan como callback a los mensajes envíados usando casts o calls
  ##  el orden es importante ya que podríamos tener condiciones inalcanzables
  def init(:ok) do
    {:ok, %{}}
  end

  @doc """
  recibe los mensajes de escritura en el caché
  """
  def handle_call({:write, key, value}, _from, state) do
    new_state = add_value(state, key, value) #actualizo o creo la clave en el cache
    {:reply, :ok, new_state} # le respondo al cliente
  end

  @doc """
  recibe los mensajes de lectura en el caché
  """
  def handle_call({:read, key}, _from, state) do

    {:reply, Map.get(state, key), state} # Map.get/2 devuelve nil si no lo encuentra, cosa que, por diseño en este caso, considero aceptable
  end

  def handle_call({:delete, key}, _from, state) do
    new_state = Map.delete(state, key)
    {:reply, :ok, new_state}
  end

  def handle_call({:exist?, key}, _from, state) do
    {:reply, Map.has_key?(state, key), state}
  end

  def handle_call({:get_stats}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:clear}, _state) do
    {:noreply, %{}}
  end

  def handle_info({:EXIT, pid, _reason}, _state) do
    IO.puts "received"
    {:noreply}
  end

  ## private methods
  defp add_value(old_state, key, value) do
    case Map.has_key?(old_state, key) do
      true ->
        Map.update!(old_state, key, fn(_) -> value end)
      false ->
        Map.put_new(old_state, key, value)
    end
  end
end
