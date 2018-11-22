defmodule Cache.Replicator do
  @moduledoc """
  Este proceso se encarga de replicar la información cuando:
  * un proceso es reiniciado
  * entra un nuevo nodo al cluster
  * se escribe un valor en el server del nodo
  """
  use GenServer

  @name CHR

  # API ****************************************************************************
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: CHR])
  end

  @doc """
  esta función se llama cuando se inicia el proceso server y solo tiene efecto cuando esto sucedió porque dicho proceso fue reiniciado
  """
  def reaplicate_from() do
    GenServer.call(@name, {:replicate_from})
  end

  @doc """
  hace un broadcast del mensaje al resto de los nodos (si los hay)
  """
  def replicate_to_nodes(key, value) do
    GenServer.cast(@name, {:broadcast, key, value})
  end

  # Callbacks ***********************************************************************
  def init(args) do
    # acá usamos el módulo net_kernel de erlang para hacer que este proceso sea notificado ante las altas/bajas de nodos
    :net_kernel.monitor_nodes(true)
    Cache.Logger.log(self(), "Replicator started")
    {:ok, args}
  end

  def handle_call({:replicate_from}, _from, state) do
    cond do
      length(Node.list()) >= 1 ->
        # TODO: por ahora me quedo con el primero, pero en realidad debería recorrer la lista hasta encontrar alguno que este vivo
        [first | _] = Node.list()
        Cache.Logger.log(self(), "Se tomarán los datos del nodo #{first}")
        # con :rpc.call me aseguro que le mando el mensaje al nodo que yo quiero
        nodestate = :rpc.call(first, Cache, :get_stats, [])

        for {key, value} <- nodestate do
          # inserto cada valor
          # podría también exponer una función que guarde el estado completo, 
          #   pero corro riesgo de pisar valores si alguien justo insertó algo más
          Cache.Server.replication_write(key, value)
        end

        Cache.Logger.log(self(), "Recuperada la información del cluster")

      true ->
        Cache.Logger.log(self(), "No hay otros nodos en el cluster")
    end

    {:reply, :ok, state}
  end

  def handle_cast({:broadcast, key, value}, state) do
    Cache.Logger.log(self(), "Replicando mensaje en #{Enum.count(Node.list())} nodos")
    Node.list() |> broadcast_message(key, value)
    {:noreply, state}
  end

  @doc """
  Callback para atender el mensaje que se genera al conectarse un nuevo nodo
  """
  def handle_info({:nodeup, node}, state) do
    Cache.Logger.log(self(), "Entró un nuevo nodo: #{node}")
    replicate_values_to_node(node)
    {:noreply, state}
  end

  @doc """
  análogo al anterior, pero al darse la baja de un nodo
  """
  def handle_info({:nodedown, node}, state) do
    Cache.Logger.log(self(), "Se bajó el nodo: #{node}")
    # no hago nada por ahora
    {:noreply, state}
  end

  # esta función toma cada uno de los valores que tenemos en el nodo actual y se lo envíamos al que acaba de entrar
  defp replicate_values_to_node(node) do
    for {key, value} <- Cache.get_stats() do
      replicate_value_to_node(node, key, value)
    end

    true
  end

  # realiza una write simple del los valores dados para el nodo elegido
  defp replicate_value_to_node(node, key, value) do
    :rpc.call(node, Cache.Server, :replication_write, [key, value])
  end

  # matchea con listas de uno o más elementos
  defp broadcast_message([currentnode | rest], key, value) do
    broadcast_message_log(currentnode, rest)
    replicate_value_to_node(currentnode, key, value)
    broadcast_message(rest, key, value)
  end

  defp broadcast_message([], _, _) do
    Cache.Logger.log(self(), "Se replicó el mensaje en todos los nodos")
  end

  defp broadcast_message_log(currentnode, rest) do
    Cache.Logger.log(
      self(),
      "Replicando mensaje en el nodo #{currentnode}. " <>
        broadcast_message_log_reaming_nodes(rest)
    )
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
