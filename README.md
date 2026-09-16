
<div align="center">
  <img src="docs/assets/banner.png" alt="Serpantinum" width="850" />
</div>

## Превʼю

| | |
|---|---|
| ![Preview 1](docs/assets/previews/preview_1.png) | ![Preview 2](docs/assets/previews/preview_2.png) |
| ![Preview 3](docs/assets/previews/preview_3.png) | ![Preview 4](docs/assets/previews/preview_4.png) |

---

## Встановлення


### Arch Linux та похідні

Для дистрибутивів на основі Arch (включно з systemd, OpenRC та іншими init-системами) виконай автоматичний скрипт встановлення:
```

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/serpantinum/master/install/install.sh)"
```
```

> [!NOTE]
> To update, when or if you recieve a notification about the new version being available, just run the script again and choose "update"

---

### NixOS

Serpantinum надає flake-виводи, модуль NixOS для системних залежностей та модуль Home Manager для налаштувань користувача й керування сервісами.

#### 1. Додай Flake Input

Додай Serpantinum до свого `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    serpantinum.url = "github:ilyamiro/serpantinum";
  };

  outputs = { self, nixpkgs, serpantinum, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit serpantinum; };
      modules = [
        ./configuration.nix
        serpantinum.nixosModules.default
      ];
    };
  };
}

```

#### 2. configuration.nix

Увімкни модуль NixOS для налаштування системних передумов:

```nix
{
  programs.serpantinum.enable = true;
}

```

Якщо волієш встановити пакет напряму без системного модуля:

```nix
{ pkgs, serpantinum, ... }:

{
  environment.systemPackages = [
    serpantinum.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

```

#### 3. Конфігурація Home Manager

```nix
{ serpantinum, ... }:

{
  imports = [
    serpantinum.homeManagerModules.default
  ];

  programs.serpantinum = {
    enable = true;
    systemd.enable = true;

    settings = {
      wallpaperDir = "/home/username/Pictures/Wallpapers";

      general = {
        language = "en";
        weatherUnit = "metric";
        weatherInterval = 30;
      };

      bar = {
        position = "top";
        style = "solid";
        width = 40;
        workspaceCount = 10;
        modules = {
          left = [ "workspaces" ];
          center = [ "time" ];
          right = [ "tray" [ "kb" "wifi" "bt" "vol" "bat" ] ];
        };
      };

      theme = {
        fontFamily = "Adwaita Mono";
        borderRadius = 12;
        matugen = true;
      };

      notifications = {
        dnd = false;
        position = "top right";
        sound = true;
      };
    };
  };
}

```

#### 4. Оновлення

Онови lock-файл flake і перезбери систему:

```bash
nix flake update serpantinum
sudo nixos-rebuild switch --flake .

```

> **Примітка:** Автоматичний інсталятор налаштовує інтеграцію з компоузитором на стандартних дистрибутивах. На NixOS / Home Manager інтеграцію з конфігами компоузитора треба виконати вручну.
> Приклади конфігів, записи автозапуску та гарячі клавіші для підтримуваних віконних менеджерів і компоузиторів доступні в теці [compositors](https://github.com/ilyamiro/serpantinum/tree/master/compositors).

#### Необхідний автозапуск

Не забудь додати слухачів буфера обміну та потрібні сервіси до автозапуску свого компоузитора, щоб буфер обміну й еквалайзер працювали коректно.

Приклад для Hyprland:

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("systemctl --user enable --now easyeffects")
end)

```
---

## Запуск

Щоб запустити шел, виконай `serpantinumd start`

---

## Подяки

* Особлива подяка Darkall44/Qylock за чудову material-тему для SDDM!

---

## Ліцензія

Copyright (C) 2026 Illia Miroshnichenko

Цей проєкт ліцензований під GNU Affero General Public License версії 3, або (на твій вибір) будь-якою пізнішою версією. Повний текст ліцензії — у файлі [LICENSE.md](LICENSE.md).
