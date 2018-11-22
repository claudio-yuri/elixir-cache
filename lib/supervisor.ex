defmodule Cache.Supervisor do
  @moduledoc """
  Este supervisor se encarga de mantener vivos a los procesos workers ante algún fallo
  """
  use Supervisor

  def start_link(:ok) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    # en esta lista definimos qué procesos queremos que el supervisor controle 
    # y, si quisiéramos, podríamos pasarle parámetros a estos. En este caso no le pasamos nada: []
    children = [
      # el orden del child spec importa!
      worker(Cache.Logger, []),
      worker(Cache.Replicator, []),
      worker(Cache.Server, [])
    ]

    # el strategy le dice al supervisor qué hacer con ese proceso en caso de fallo
    # strategy: :one_for_one hace que solo se reinicie el proceso que murió, one_for_all hace que se reinicien todos
    supervise(children, strategy: :one_for_one)
  end
end
