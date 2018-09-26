# pipi-elixir-cache

La idea de este es hace un cache in-memory como excusa de aprender algo de Elixir.

## Features

1. Soporta los siguientes métodos: `write(key, value)`, `read(key)`, `delete(key)`, `clear`, `exist?(key)`, `get_stats`.
2. Supervisión por nodo *[en desarrollo]*.
3. Replica cada escritura a todos los nodos conectados.
4. Replica la información a un nuevo nodo **[pendiente]**.
5. Fail-over take-over **[pendiente]**.
