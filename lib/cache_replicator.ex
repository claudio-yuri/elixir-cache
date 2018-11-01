defmodule Cache.Replicator do
    use GenServer

    @name CHR

    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts ++ [name: CHR])
    end

    def reaplicate_from() do
        GenServer.call(@name, {:replicate_from})
        
    end
    
    def init(args) do
        :net_kernel.monitor_nodes(true)
        Cache.Logger.log(self(), "Replicator started")
        {:ok, args}
    end

    def handle_call({:replicate_from}, _from, state) do
        len = length(Node.list)
        IO.puts "len #{len}"
        cond do
            length(Node.list) >= 1 ->
                #por ahora me quedo con el primero, pero en realidad debería recorrer la lista hasta encontrar alguno que este vivo
                [ first | _ ] = Node.list
                IO.puts "el nodo #{first}"
                # Node.connect(first)
                nodestate = :rpc.call(first, Cache, :get_stats, [])
                for {key, value} <- nodestate do
                    Cache.Server.replication_write(key, value)
                end
                Cache.Logger.log(self(), "Conectado al cluster")
            true ->
                Cache.Logger.log(self(), "No hay otros nodos en el cluster")
        end
        {:reply, :ok, state}
    end

    def handle_info({:nodeup, node}, state) do
        Cache.Logger.log(self(), "Entro un nuevo nodo: #{node}")
        replicateto(node)
        {:noreply, state}
    end

    def handle_info({:nodedown, node}, state) do
        Cache.Logger.log(self(), "Se bajó el nodo: #{node}")
        #no hago nada por ahora
        {:noreply, state}
    end
                
    defp replicateto(node) do
        for {key, value} <- Cache.get_stats do
            :rpc.call(node, Cache.Server, :replication_write, [key, value])
        end
        true
    end
end