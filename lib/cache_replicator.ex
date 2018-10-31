defmodule Cache.Replicator do
    use GenServer

    @name CHR

    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts ++ [name: CHR])
    end
    
    def init(args) do
        :net_kernel.monitor_nodes(true)
        Cache.Logger.log(self(), "Replicator started")
        {:ok, args}
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