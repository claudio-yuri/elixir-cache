defmodule Cache.Logger do
    use GenServer

    @name CHL

    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts ++ [name: CHL])
    end

    def log(pid, msg) do
        GenServer.cast(@name, {:log, pid, msg})
    end

    def init(args) do
        printline_withpid(self(), "Logger started")
        {:ok, args}
    end

    def handle_cast({:log, pid, msg}, state) do
        printline_withpid(pid, msg)
        {:noreply, state}
    end

    defp printline_withpid(pid, msg) do
        #esta es la forma de poder imprimir por pantalla el PID de un proceso
        IO.inspect(pid, label: msg <> ". PID: ")
    end
end