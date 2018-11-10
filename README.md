# pipi-elixir-key-value-store

La idea de este es hace un key-value store in-memory como excusa de aprender algo de Elixir.

## Features

1. Soporta los siguientes métodos: `write(key, value)`, `read(key)`, `delete(key)`, `clear`, `exist?(key)`, `get_stats` y `connect(node)`.
2. Supervisión por nodo.
3. Replica cada escritura a todos los nodos conectados.
4. Replica la información a un nuevo nodo.
5. Al recuperarse un nodo, recupera la información del resto.

## Arquitectura

Hay 4 procesos:

1. Cache.Server: este es el que controla el estado de los datos y realiza el CRUD con los mismos.
2. Cache.Replicator: se encarga de enviar y recibir los datos a los demás nodos.
3. Cache.Logger: se usa para mostrar información en la consola.
4. Cache.Supervisor: se encarga de mantener vivos a los demás procesos.

## ¿Como lo puedo probar?

Podemos usar iex de la siguiente manera:

``` bash
> iex --sname nodo1 -S mix
```

## Notas finales

Esto es simplemente un experimento práctico. Cualquier comentario es bienvenido.
