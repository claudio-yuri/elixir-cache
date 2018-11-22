defmodule Cache.Server do
  @moduledoc """
  Este proceso se encarga de mantener el estado de los datos que queremos almacenar
  Es básicamente un wrapper del Map que ofrece Elixir.
  Soporta las siguientes operaciones:
    * write(key, value)
    * read(key)
    * delete(key)
    * clear
    * exist?(key)
    * get_stats
    * connect(node)
  """
  use GenServer

  # nombre del process
  @name CH

  ## Client API ##################################################################################
  ##  en esta sección, como indica el nombre se pone todo lo que puede ver el cliente
  ##  no es buena práctica mandar el mensaje directamente desde un proceso externo, por eso se expone una api

  @doc """
  Inicia el proceso para el caché.
  """
  def start_link(opts \\ []) do
    # primero inicializo el estado y me guardo la respuesta porque es esto mismo lo que quiero devolverle al que me llamó
    resp = GenServer.start_link(__MODULE__, :ok, opts ++ [name: CH])

    # Esta función solo tiene efecto si el nodo ya estaba previamente conectado a al menos otro nodo
    #   Esto se da en dos casos:
    #     - que se haya conectado el nodo antes de iniciar la aplicación
    #     - en caso que este proceso se haya reiniciado en el nodo actual
    # y lo que hace básicamente es pedirle la info que tenga alguno de los nodos para traerla al actual
    Cache.Replicator.reaplicate_from()
    resp
  end

  @doc """
  Escribe un valor en el caché.
  """
  def write(key, value) do
    # GenServer.call realiza un llamado sincrónico
    GenServer.call(@name, {:write, key, value})
    {:ok}
  end

  @doc """
  Escribe un valor en el caché.
  """
  def replication_write(key, value) do
    # GenServer.call realiza un llamado sincrónico
    Cache.Logger.log(self(), "Replicando #{key}")
    GenServer.call(@name, {:replication_write, key, value})
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

  @doc """
  Conecta al nodo elegido
  """
  def connect(node) do
    GenServer.call(@name, {:connect, node})
  end

  ## server callbacks #########################################################################################################
  ##  en esta sección se ponen las funciones que actúan como callback a los mensajes envíados usando casts o calls
  ##  el orden es importante ya que podríamos tener condiciones inalcanzables
  ## también se recomienda agrupar casts, calls e info juntos

  @doc """
  Callback para inicializar el proceso
  """
  def init(:ok) do
    Cache.Logger.log(self(), "Cache server inciado")
    {:ok, %{}}
  end

  @doc """
  recibe los mensajes de escritura en el caché
  """
  def handle_call({:write, key, value}, _from, state) do
    # actualizo o creo la clave en el cache
    new_state = add_value(state, key, value)
    Cache.Replicator.replicate_to_nodes(key, value)
    # le respondo al cliente
    {:reply, :ok, new_state}
  end

  @doc """
  recibe los mensajes de escritura en el caché de una operación de replicación
  """
  def handle_call({:replication_write, key, value}, _from, state) do
    # actualizo o creo la clave en el cache
    new_state = add_value(state, key, value)
    # le respondo al cliente
    {:reply, :ok, new_state}
  end

  @doc """
  recibe los mensajes de lectura en el caché
  """
  def handle_call({:read, key}, _from, state) do
    # Map.get/2 devuelve nil si no lo encuentra, cosa que, por diseño en este caso, considero aceptable
    {:reply, Map.get(state, key), state}
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

  def handle_call({:connect, node}, _from, state) do
    # solo conecto al nodo deseado y dejo que Cache.Replicator se encargue de replicar
    resp = Node.connect(node)

    case resp do
      true ->
        {:reply, :ok, state}

      false ->
        {:reply, :notok, state}
    end
  end

  def handle_cast({:clear}, _state) do
    {:noreply, %{}}
  end

  ## private methods ########################################################################

  # agrega el valor recibido al map
  defp add_value(old_state, key, value) do
    case Map.has_key?(old_state, key) do
      true ->
        Map.update!(old_state, key, fn _ -> value end)

      false ->
        Map.put_new(old_state, key, value)
    end
  end
end
