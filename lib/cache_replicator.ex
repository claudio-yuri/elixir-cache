defmodule Cache.Replicator do
    use GenServer

    @name CHR

    def start_link(opts \\ []) do
        # loop()
        GenServer.start_link(__MODULE__, :ok, opts ++ [name: CHR])
    end
    
    def init(args) do
        :net_kernel.monitor_nodes(true)
        IO.puts "Replicator started"
        {:ok, args}
    end

    def handle_info({:nodeup, node}, state) do
        IO.puts "Entro un nuevo nodo: #{node}"
        replicateto(node)
        {:noreply, state}
    end

    def handle_info({:nodedown, node}, state) do
        IO.puts "Se bajó el nodo: #{node}"
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