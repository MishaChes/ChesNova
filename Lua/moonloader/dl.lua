-- ============================================================
--  /dl - информация о транспорте на экране
--  Показывает: id (SAMP), model (ID модели), hp
--
--  /dl - вкл/выкл отображение
-- ============================================================
script_name("DL")
script_version("1.0")

require "lib.moonloader"
require "lib.sampfuncs"

local RADIUS = 30.0 -- дистанция показа авто, метров
local COLOR = 0xFF0088CC -- темно-голубой, как у обычного /dl

local enabled = false
local font

function main()
  if not isSampfuncsLoaded() then return end
  while not isSampAvailable() do wait(100) end

  sampRegisterChatCommand("dl", function()
    enabled = not enabled
  end)

  font = renderCreateFont("Tahoma", 7, FCR_BOLD + FCR_BORDER)

  while true do
    wait(0)
    if enabled and not isPauseMenuActive() then
      drawVehicles()
    end
  end
end

function drawVehicles()
  local px, py, pz = getCharCoordinates(playerPed)
  for _, car in ipairs(getAllVehicles()) do
    if doesVehicleExist(car) and isCarOnScreen(car) then
      local x, y, z = getCarCoordinates(car)
      if getDistanceBetweenCoords3d(px, py, pz, x, y, z) <= RADIUS then
        local ok, vid = sampGetVehicleIdByCarHandle(car)
        if ok then
          local hp = getCarHealth(car)
          local sx, sy = convert3DCoordsToScreen(x, y, z)
          local h = renderGetFontDrawHeight(font)
          local lines = {
            string.format("ID : %d", vid),
            string.format("HP : %d", hp),
            string.format("MODEL : %d", getCarModel(car)),
          }
          for i, line in ipairs(lines) do
            local w = renderGetFontDrawTextLength(font, line)
            renderFontDrawText(font, line, sx - w / 2, sy + (i - 1) * h, COLOR)
          end
        end
      end
    end
  end
end
