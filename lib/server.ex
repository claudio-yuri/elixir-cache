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

  @name CH # nombre del process

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
    Cache.Replicator.reaplicate_from
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
    new_state = add_value(state, key, value) #actualizo o creo la clave en el cache
    broadcast_message_to_nodes(key, value)
    {:reply, :ok, new_state} # le respondo al cliente
  end

  @doc """
  recibe los mensajes de escritura en el caché de una operación de replicación
  """
  def handle_call({:replication_write, key, value}, _from, state) do
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

  @doc """
  agrega el valor recibido al map
  """
  defp add_value(old_state, key, value) do
    case Map.has_key?(old_state, key) do
      true ->
        Map.update!(old_state, key, fn(_) -> value end)
      false ->
        Map.put_new(old_state, key, value)
    end
  end

  @doc """
  Replica el mensaje a todos los nodos conectados
  """
  defp broadcast_message_to_nodes(key, value) do
    # lo podría hacer así, pero prefiero la forma de pattern matching para logging
    # Node.list |> :rpc.multicall(Cache.Server, :replication_write, [key, value])
    Cache.Logger.log(self(), "Replicando mensaje en #{Enum.count(Node.list)} nodos")
    Node.list |> broadcast_message(key, value)
  end

  @doc """
  matchea con listas de uno o más elementos
  """ 
  defp broadcast_message([currentnode | rest], key, value) do
    broadcast_message_log(currentnode, rest)
    :rpc.call(currentnode, Cache.Server, :replication_write, [key, value])
    broadcast_message(rest, key, value)
  end

  defp broadcast_message([], _, _) do
    Cache.Logger.log(self(), "Se replicó el mensaje en todos los nodos")
  end

  defp broadcast_message_log(currentnode, rest) do
    Cache.Logger.log(self(), "Replicando mensaje en el nodo #{currentnode}. " <> broadcast_message_log_reaming_nodes(rest))
  end

  defp broadcast_message_log_reaming_nodes(rest) do
    nodecount = Enum.count(rest)
    case nodecount do
      0 -> 
        "Este es el último nodo."
      1 -> 
        "Falta #{nodecount} nodo..."
      _ -> 
        "Faltan #{nodecount} nodos..."
    end
  end
end
