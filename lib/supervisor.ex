defmodule Cache.Supervisor do
    use Supervisor

    def start_link(:ok) do
        Supervisor.start_link(__MODULE__, :ok)
    end

    def init(:ok) do
        children = [
            worker(Cache.Logger, []), #el orden del child spec importa!
            worker(Cache.Replicator, []),
            worker(Cache.Server, [])
        ]
        
        #strategy: :one_for_one hace que solo se reinicie el proceso que murió, one_for_all hace que se reinicien todos
        supervise(children, [strategy: :one_for_one])
    end
end