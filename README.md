# Contenedores Docker — widget para KDE Plasma 6

Plasmoide para KDE Plasma 6 que muestra tus contenedores de Docker, su estado, y te deja levantarlos, reiniciarlos o detenerlos con un clic.

![Captura del widget](screenshots/widget.png)

## Qué hace

- Lista todos los contenedores (`docker ps -a`), agrupados por proyecto de Docker Compose.
- Tarjeta oscura con estilo moderno: filas redondeadas, punto de estado con pulso cuando el contenedor está corriendo (verde: corriendo, ámbar: pausado/reiniciando, rojo: muerto, gris: detenido).
- Los puertos publicados aparecen como chips; clic en uno para abrir `http://localhost:<puerto>`.
- Muestra imagen, estado y puertos publicados de cada contenedor.
- Botones para **levantar**, **reiniciar** y **detener**.
- Búsqueda por nombre, imagen, proyecto o puerto, y selector **Todos / Activos**.
- En el panel aparece como ícono con un tooltip que dice cuántos contenedores están corriendo; en el escritorio muestra la lista completa.
- Se actualiza solo: cada 3 s con el widget abierto y cada 15 s cerrado.

## Requisitos

- KDE Plasma 6.0 o superior
- Docker instalado, y tu usuario con permiso para usarlo sin `sudo`:

  ```bash
  sudo usermod -aG docker $USER
  # cierra sesión y vuelve a entrar para que aplique
  ```

  Comprueba que funciona con `docker ps`.

## Instalación

```bash
git clone https://github.com/<tu-usuario>/docker-widget.git
cd docker-widget
kpackagetool6 --type Plasma/Applet --install .
```

Después:

1. Clic derecho en el escritorio o en el panel → **Añadir o gestionar widgets**.
2. Busca **Contenedores Docker** y arrástralo a donde quieras.

### Actualizar

```bash
git pull
kpackagetool6 --type Plasma/Applet --upgrade .
```

Si no ves los cambios, reinicia Plasma:

```bash
systemctl --user restart plasma-plasmashell
```

### Desinstalar

```bash
kpackagetool6 --type Plasma/Applet --remove local.dockercontainers
```

## Problemas comunes

- **"No se pudo hablar con Docker"**: el servicio no está corriendo (`sudo systemctl start docker`) o tu usuario no está en el grupo `docker`. El widget muestra el mensaje de error de `docker` debajo.

## Licencia

[MIT](LICENSE)
