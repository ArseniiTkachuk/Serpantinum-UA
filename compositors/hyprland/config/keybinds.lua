local mainMod = _G.mainMod or "SUPER"
local terminal = _G.terminal or "kitty"

-- Свайп 3 пальцями по горизонталі: перемикання воркспейсу
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Перетягування / зміна розміру вікна мишею
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Зміна розміру вікна (раніше: super + control + h/j/k/l через bspc node -z)
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Переміщення вікна між зонами (раніше: super + alt + h/j/k/l через bspc node -s)
hl.bind(mainMod .. " + ALT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + ALT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + ALT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + ALT + Down", hl.dsp.window.move({ direction = "d" }))

-- Фокус у напрямку (раніше: super + h/j/k/l через bspc node -f)
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))

-- Закрити вікно (раніше: super + c -> bspc node -c)
hl.bind(mainMod .. " + C", hl.dsp.window.close())

-- Плаваюче вікно (прямого відповідника в старому конфізі нема, лишив як було)
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))

-- Яскравість екрана (ті самі клавіші, що й раніше)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("serpantinum brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("serpantinum brightness raise"), { locked = true })

-- Скріншоти (раніше: Print -> flameshot gui)
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("serpantinum screenshot"), { locked = true })

-- Блокування екрана (раніше: super + shift + l -> screen-lock)
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("serpantinum lock"), { locked = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("serpantinum lock"), { repeating = true, locked = true })

-- Медіа-клавіші (ті самі, що й раніше)
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("serpantinum volume mic-toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("serpantinum volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("serpantinum volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("serpantinum volume raise"), { repeating = true, locked = true })

-- Запуск застосунків (раніше: super + e -> thunar, super + return -> kitty)
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("chromium"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("Telegram"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

-- Перезавантаження конфігу (раніше: super + Escape + r)
hl.bind(mainMod .. " + ESCAPE + R", hl.dsp.exec_cmd("serpantinum reload"))

-- Буфер обміну (прямого відповідника в старому конфізі нема, зайняв звільнену Q)
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("serpantinum msg toggle clipboard"))

-- Лаунчер (раніше: super + d -> rofi drun)
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))

-- Музика (прямого відповідника в старому конфізі нема, лишив як було)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("serpantinum msg toggle music"))

-- Системна панель (раніше: super + p -> toggle polybar)
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("serpantinum msg toggle system"))

-- Шпалери (раніше: super + w -> random_wallpaper)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("serpantinum msg toggle wallpaper"))

-- Календар (раніше: super + shift + k -> kitty -e calcurse)
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("serpantinum msg toggle calendar"))

-- Мережа (прямого відповідника в старому конфізі нема, лишив як було)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("serpantinum msg toggle network"))

-- Гучність (раніше: super + shift + p -> pavucontrol)
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("serpantinum msg toggle volume"))

-- Гайд (прямого відповідника в старому конфізі нема, лишив як було)
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("serpantinum msg toggle guide"))

-- Автоприховування (прямого відповідника в старому конфізі нема, лишив як було)
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum msg toggle autohide"))

-- Перемикання воркспейсів (раніше: super + {1-9,0} -> desktop -f)
-- Переміщення вікна на воркспейс (раніше: super + shift + {1-9,0} -> node -d)
for i = 1, 10 do
	local ws = tostring(i)
	local key = tostring(i % 10)
	hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws .. " move"))
end
