defmodule Cache.Replicator do
    @moduledoc """
    Este proceso se encarga de replicar la información cuando:
    * un proceso es reiniciado
    * entra un nuevo nodo al cluster
    TODO: Agregar la replicación que se hace ante una escritura de un nuevo dato
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
    
    # Callbacks ***********************************************************************
    def init(args) do
        #acá usamos el módulo net_kernel de erlang para hacer que este proceso sea notificado ante las altas/bajas de nodos
        :net_kernel.monitor_nodes(true)
        Cache.Logger.log(self(), "Replicator started")
        {:ok, args}
    end

    def handle_call({:replicate_from}, _from, state) do
        cond do
            length(Node.list) >= 1 ->
                #TODO: por ahora me quedo con el primero, pero en realidad debería recorrer la lista hasta encontrar alguno que este vivo
                [ first | _ ] = Node.list
                Cache.Logger.log(self(), "Se tomarán los datos del nodo #{first}")
                # con :rpc.call me aseguro que le mando el mensaje al nodo que yo quiero
                nodestate = :rpc.call(first, Cache, :get_stats, [])
                for {key, value} <- nodestate do
                    #inserto cada valor
                    #podría también exponer una función que guarde el estado completo, 
                    #   pero corro riesgo de pisar valores si alguien justo insertó algo más
                    Cache.Server.replication_write(key, value)
                end
                Cache.Logger.log(self(), "Recuperada la información del cluster")
            true ->
                Cache.Logger.log(self(), "No hay otros nodos en el cluster")
        end
        {:reply, :ok, state}
    end

    @doc """
    Callback para atender el mensaje que se genera al conectarse un nuevo nodo
    """
    def handle_info({:nodeup, node}, state) do
        Cache.Logger.log(self(), "Entró un nuevo nodo: #{node}")
        replicateto(node)
        {:noreply, state}
    end

    @doc """
    análogo al anterior, pero al darse la baja de un nodo
    """
    def handle_info({:nodedown, node}, state) do
        Cache.Logger.log(self(), "Se bajó el nodo: #{node}")
        #no hago nada por ahora
        {:noreply, state}
    end
    
    @doc """
    este método toma cada uno de los valores que tenemos en el nodo actual y se lo envíamos al que acaba de entrar
    """
    defp replicateto(node) do
        for {key, value} <- Cache.get_stats do
            :rpc.call(node, Cache.Server, :replication_write, [key, value])
        end
        true
    end
end