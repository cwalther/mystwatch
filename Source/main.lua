import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

local ibackground = gfx.image.new('images/launchImage')
local ibell = gfx.image.new('images/bell')
local iboxes = {
    {
        gfx.image.new('images/boxes00'),
        gfx.image.new('images/boxes01'),
        gfx.image.new('images/boxes02'),
    },
    {
        gfx.image.new('images/boxes10'),
        gfx.image.new('images/boxes11'),
        gfx.image.new('images/boxes12'),
    },
    {
        gfx.image.new('images/boxes20'),
        gfx.image.new('images/boxes21'),
        gfx.image.new('images/boxes22'),
    }
}
local inumbers = {
    {
        gfx.image.new('images/numbers01'),
        gfx.image.new('images/numbers02'),
        gfx.image.new('images/numbers03'),
    },
    {
        gfx.image.new('images/numbers11'),
        gfx.image.new('images/numbers12'),
        gfx.image.new('images/numbers13'),
    },
    {
        gfx.image.new('images/numbers21'),
        gfx.image.new('images/numbers22'),
        gfx.image.new('images/numbers23'),
    },
}
local ileverlu = gfx.image.new('images/leverlu')
local ileverld = gfx.image.new('images/leverld')
local ileverru = gfx.image.new('images/leverru')
local ileverrd = gfx.image.new('images/leverrd')
local iweight = gfx.image.new('images/weight')
local f7seg = gfx.font.new('fonts/7seg')

local synth = playdate.sound.synth.new(playdate.sound.kWaveSquare)

local sbell = false
local sblink = false
local sboxes = {1, 1, 1}
local snumbers = {3, 3, 3}
local sleverl = 1
local sleverr = 1
local sweight = 9

local now = playdate.getCurrentTimeMilliseconds()

local function draw()
    ibackground:draw(0, 0)
    if sbell and (playdate.getCurrentTimeMilliseconds() & 0x200 ~= 0) then
        if not sblink then
            sblink = true
            synth:playNote(4000, 0.5, 0.1)
        end
        ibell:draw(256, 41)
    else
        sblink = false
    end
    iboxes[1][sboxes[1]]:draw(169, 64)
    iboxes[2][sboxes[2]]:draw(169, 92)
    iboxes[3][sboxes[3]]:draw(169, 120)
    if sboxes[1] == 1 then inumbers[1][snumbers[1]]:draw(169, 64) end
    if sboxes[2] == 1 then inumbers[2][snumbers[2]]:draw(169, 92) end 
    if sboxes[3] == 1 then inumbers[3][snumbers[3]]:draw(169, 120) end
    if sleverl == 1 then
        ileverlu:draw(140, 72)
    elseif sleverl == 2 then
        ileverld:draw(132, 101)
    end
    if sleverr == 1 then
        ileverru:draw(246, 72)
    elseif sleverr == 2 then
        ileverrd:draw(253, 101)
    end
    for i = 1, sweight do
        iweight:draw(127, 66-3*i)
    end
    local t = playdate.getTime()
    if not playdate.shouldDisplay24HourTime() then
        t.hour = (t.hour + 11) % 12 + 1
    end
    f7seg:drawText(string.format('%2d:%02d', t.hour, t.minute), 151, 38)
end

local function sleep(tick)
    draw()
    if tick == 0 then
        now = playdate.getCurrentTimeMilliseconds()
        coroutine.yield()
    else
        now += tick
        while playdate.getCurrentTimeMilliseconds() < now do
            if sbell then draw() end
            coroutine.yield()
        end
    end
end

local function move(rows, reset)
    if not reset then
        sweight -= 1
        if sweight < 0 then
            sweight = 0
            if sleverl ~= 1 or sleverr ~= 1 then
                sleverl = 1
                sleverr = 1
                synth:playNote(3000, 0.1, 0.01)
            end
            return
        end
    end
    synth:playNote(60, 0.1, 0.1)
    for _, i in ipairs(rows) do
        snumbers[i] = snumbers[i] % 3 + 1
        sboxes[i] = 2
    end
    sleep(100)
    for _, i in ipairs(rows) do
        sboxes[i] = 3
    end
    sleep(100)
    for _, i in ipairs(rows) do
        sboxes[i] = 1
    end
    sleep(200)
end

function playdate.update()
    if playdate.buttonIsPressed(playdate.kButtonUp | playdate.kButtonDown | ((sweight == 0) and (playdate.kButtonA | playdate.kButtonB) or 0)) then
        sbell = false
        for i = 1, 3 do
            while true do
                move({i}, true)
                if snumbers[i] == 3 then break end
            end
        end
        while sweight < 9 do
            sweight += 1
            synth:playNote(40, 0.2, 0.05)
            sleep(150)
        end
        while playdate.buttonIsPressed(0xFF) do
            sleep(0)
        end
    elseif playdate.buttonIsPressed(playdate.kButtonB) then
        sleverl = 2
        synth:playNote(4000, 0.1, 0.01)
        sleep(200)
        move({2, 3})
        if playdate.buttonIsPressed(playdate.kButtonB) then
            sleep(300)
            while true do
                move({2})
                if playdate.buttonIsPressed(playdate.kButtonB) then
                    sleep(300)
                else
                    break
                end
            end
        end
        if sleverl ~= 1 then
            sleverl = 1
            synth:playNote(3000, 0.1, 0.01)
        end
    elseif playdate.buttonIsPressed(playdate.kButtonA) then
        sleverr = 2
        synth:playNote(4000, 0.1, 0.01)
        sleep(200)
        move({1, 2})
        if playdate.buttonIsPressed(playdate.kButtonA) then
            sleep(300)
            while true do
                move({2})
                if playdate.buttonIsPressed(playdate.kButtonA) then
                    sleep(300)
                else
                    break
                end
            end
        end
        if sleverr ~= 1 then
            sleverr = 1
            synth:playNote(3000, 0.1, 0.01)
        end
    else
        draw()
        now = playdate.getCurrentTimeMilliseconds()
    end
    if not sbell and snumbers[1] == 2 and snumbers[2] == 2 and snumbers[3] == 1 then
        sleep(100)
        while sweight > 0 do
            sweight -= 1
            synth:playNote(40, 0.2, 0.05)
            sleep(150)
        end
        sbell = true
    end
end
