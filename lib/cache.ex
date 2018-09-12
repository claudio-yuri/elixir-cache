defmodule Cache do
    use Application

    def start(_, _) do
        Cache.Server.start_link
    end

    @doc """
    Escribe un valor en el caché.
    """
    def write(key, value) do
        Cache.Server.write(key, value)
    end

    @doc """
    Busca un valor en el caché.
    """
    def read(key) do
        IO.puts "pedido #{key}"
        Cache.Server.read(key)
    end

    @doc """
    Borra un valor del caché.
    """
    def delete(key) do
        Cache.Server.delete(key)
    end

    @doc """
    Limpia el cache
    """
    def clear do
        Cache.Server.clear
    end

    @doc """
    Determina si existe la key en cache
    """
    def exist?(key) do
        Cache.Server.exist?(key)
    end

    @doc """
    Devuelve el listado completo de elementos en cache
    """
    def get_stats do
        Cache.Server.get_stats
    end

    def exit do
        Cache.Server.exit
    end
end