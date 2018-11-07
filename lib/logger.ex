defmodule Cache.Logger do
    @moduledoc """
    Este proceso se encarga de loggear la información que los demás procesos necesiten
    En esta implementación se elige como output la consola
    """
    use GenServer

    @name CHL

    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts ++ [name: CHL])
    end

    @doc """
    recibe el pid del proceso que origina el mensaje y un texto que se quiera mostrar
    """
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
        # a los pids, como son una estructura particula, no se les puede hacer directamente IO.puts pid
        IO.inspect(pid, label: msg <> ". PID: ")
    end
end