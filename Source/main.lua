local gfx = playdate.graphics
local snd = playdate.sound

FPS = 30
WIDTH = playdate.display.getWidth()
HEIGHT = playdate.display.getHeight()
BORDER = 4

-- [[ BRICK CONSTANTS ]]
BRICK_START_X = BORDER + 60
BRICK_START_Y = HEIGHT - BORDER + 1
BRICK_PAD = 1
BRICK_W = 20
BRICK_H = 6

CHECKERED = { 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 }
BRICK = { 0x11, 0x11, 0xff, 0x44, 0xff, 0x88, 0x88, 0xff }
BASKET = { 0xbb, 0x55, 0xee, 0x55, 0xbb, 0x55, 0xee, 0x55 }
STRIPE = { 0xc3, 0x87, 0x0f, 0x1e, 0x3c, 0x78, 0xf0, 0xe1 }
DIAMOND = { 0x22, 0x41, 0x80, 0x41, 0x22, 0x14, 0x08, 0x14 }

Synth = {
    snd.synth.new(snd.kWaveSquare),
    snd.synth.new(snd.kWavePOPhase),
    snd.synth.new(snd.kWavePODigital),
    hitWall = snd.synth.new(snd.kWavePOVosim),
    snd.synth.new(snd.kWaveSine),
    hitPaddle = snd.synth.new(snd.kLFOSquare),
    snd.synth.new(snd.kLFOSine),
    snd.synth.new(snd.kLFOTriangle),
    snd.synth.new(snd.kLFOSawtoothUp),
    snd.synth.new(snd.kLFOSawtoothDown),
    snd.synth.new(snd.kLFOSampleAndHold),
    snd.synth.new(snd.kWaveSawtooth),
    snd.synth.new(snd.kWaveTriangle),
    snd.synth.new(snd.kFilterLowPass),
    snd.synth.new(snd.kFilterPEQ),
    snd.synth.new(snd.kFilterNotch),
    snd.synth.new(snd.kFilterBandPass),
    snd.synth.new(snd.kFilterHighPass),
    snd.synth.new(snd.kFilterLowShelf),
    hitBrick = snd.synth.new(snd.kFormat8bitMono),
    snd.synth.new(snd.kFormat8bitStereo),
    snd.synth.new(snd.kFormat16bitMono),
    snd.synth.new(snd.kFormat16bitStereo),
}

Synth.hitBrick:setVolume(0.9)
Synth.hitPaddle:setVolume(0.3)

BrickNotes = {
    snd.track.new(),
    snd.track.new(),
    snd.track.new(),
    snd.track.new(),
}

BrickNotes[1]:addNote(1, 'E3', 1, 0.2)
BrickNotes[1]:addNote(2, '0', 1, 0.2)

BrickNotes[2]:addNote(1, 'A3', 1, 0.2)
BrickNotes[2]:addNote(2, '0', 1, 0.2)

BrickNotes[3]:addNote(1, 'D4', 1, 0.2)
BrickNotes[3]:addNote(2, '0', 1, 0.2)

BrickNotes[4]:addNote(1, 'G5', 1, 0.2)
BrickNotes[4]:addNote(2, '0', 1, 0.2)

BrickNotes[1]:setInstrument(Synth.hitBrick:copy())
BrickNotes[2]:setInstrument(Synth.hitBrick:copy())
BrickNotes[3]:setInstrument(Synth.hitBrick:copy())
BrickNotes[4]:setInstrument(Synth.hitBrick:copy())

BreakoutFont = gfx.font.new 'font/breakoutfont'

BricksList = {}

playdate.display.setRefreshRate(FPS)

Point = {
    x = nil,
    y = nil,
}

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

local function intersection(ax, ay, ah, aw, bx, by, bh, bw)
    -- Horizontal
    local aMin = ax
    local aMax = aMin + aw
    local bMin = bx
    local bMax = bMin + bw
    if bMin > aMin then
        aMin = bMin
    end
    if bMax < aMax then
        aMax = bMax
    end
    if aMax <= aMin then
        return false
    end

    -- Vertical
    aMin = ay
    aMax = aMin + ah
    bMin = by
    bMax = bMin + bh
    if bMin > aMin then
        aMin = bMin
    end
    if bMax < aMax then
        aMax = bMax
    end
    if aMax <= aMin then
        return false
    end
    return true
end

function ScoreUI(x, y, digits)
    local scoreUI = {
        x = x,
        y = y,
        w = 18,
        h = 25,
        size = 3,
        value = 0,
        digits = {},

        init = function(self)
            for d = 1, digits, 1 do
                self.digits[d] = 0
            end
        end,

        update = function(self)
            local val = self.value
            for d = 1, digits, 1 do
                local current = val % 10
                val = math.floor(val / 10)
                self.digits[d] = current
            end
        end,

        show = function(self)
            for d = 1, #self.digits, 1 do
                BreakoutFont:drawText(self.digits[d], self.x, self.y + (self.w * d))
            end
        end,
    }
    scoreUI:init()
    return scoreUI
end

function Brick(x, y)
    print('Creating Brick...' .. #BricksList .. ': ' .. x .. ', ' .. y)

    local brick = {
        x = x or BRICK_START_X,
        y = y or BRICK_START_Y,
        w = BRICK_W,
        h = BRICK_H,
        p = BRICK,
        hp = 1,
        hit = false,
        value = 1,

        snd = function(self)
            local brickSequence = snd.sequence.new()
            if brickSequence ~= nil then
                brickSequence:addTrack(BrickNotes[self.value])
                brickSequence:setTempo(30)
                brickSequence:setLoops(self.value)
                brickSequence:play()
            end
        end,

        show = function(self)
            gfx.setPattern(self.p)
            gfx.fillRect(self.x, self.y, self.h, self.w)
        end,

        update = function(self) end,
    }
    return brick
end

function Ball()
    print 'Creating Ball'

    local ball = {
        x = clamp(math.random() * WIDTH, 210, 270),
        y = clamp(math.random() * HEIGHT, 10, 220),
        dx = 1,
        dy = math.random() >= 0.5 and 1 or -1,
        speed = 5,
        w = 5,
        h = 3,

        snd = function()
            Synth.hitWall:playNote('C4', 0.75, 0.05)
        end,

        show = function(self)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(self.x, self.y, self.h, self.w)
        end,

        checkVerticalCollision = function(self)
            local nx = self.x + self.dx * self.speed
            local paddleVCollision = intersection(nx, self.y, self.w, self.h, GamePaddle.x, GamePaddle.y, GamePaddle.w, GamePaddle.h)

            if paddleVCollision then
                GamePaddle:snd()
                local a = GamePaddle.x - (self.x + self.h)
                local b = self.x - (GamePaddle.x + GamePaddle.h)
                if a > b then
                    self.x = GamePaddle.x - self.h
                    local ballMidY = self.y + (self.w / 2)
                    local rightBounds = GamePaddle.y + (GamePaddle.w * 0.35)
                    local leftBounds = GamePaddle.y + GamePaddle.w - (GamePaddle.w * 0.35)

                    if ballMidY >= leftBounds then
                        -- print 'hit the top left of the paddle\n'
                        if self.dy > 0 then
                            self.dy = 1.4
                        else
                            self.dy = -self.dy
                        end
                    elseif ballMidY <= rightBounds then
                        -- print 'hit the top right of the paddle\n'
                        if self.dy > 0 then
                            self.dy = -self.dy
                        else
                            self.dy = -1.4
                        end
                    else
                        -- print 'hit the top center of the paddle\n'
                        if self.dy > 0 then
                            self.dy = 0.45
                        else
                            self.dy = -0.45
                        end
                    end

                    self.dx = -1
                    -- print 'hit the top of the paddle\n'
                else
                    self.x = GamePaddle.x + GamePaddle.h
                    self.dx = 1
                    -- print 'hit the bottom of the paddle\n'
                end
                return nil
            end

            if nx < BORDER or nx + self.h > WIDTH - BORDER then
                local a = self.x - BORDER
                local b = WIDTH - self.x - self.h
                if a > b then
                    self.x = WIDTH - BORDER - self.h
                    DeathCounter.value += 1
                    Game:checkGameOver()
                    -- print 'hit the bottom of the screen\n'
                else
                    self:snd()
                    self.x = BORDER
                    self.dx = -self.dx
                    -- print 'hit the top of the screen\n'
                end
                return nil
            end

            for i = 1, #BricksList, 1 do
                local brick = BricksList[i]
                if brick.hp > 0 then
                    local bVCollision = intersection(nx, self.y, self.w, self.h, brick.x, brick.y, brick.w, brick.h)
                    if bVCollision then
                        local a = brick.x - (self.x + self.h)
                        local b = self.x - (brick.x + brick.h)
                        if a > b then
                            self.x = brick.x - self.h
                            self.dx = -1
                            -- print 'hit the top of a brick\n'
                        else
                            self.x = brick.x + brick.h
                            self.dx = 1
                            -- print 'hit the bottom of a brick\n'
                        end
                        return brick
                    end
                end
            end
            self.x = nx
            return nil
        end,

        checkHorizontalCollision = function(self)
            local ny = self.y + self.dy * self.speed
            local paddleHCollision = intersection(self.x, ny, self.w, self.h, GamePaddle.x, GamePaddle.y, GamePaddle.w, GamePaddle.h)

            if paddleHCollision then
                GamePaddle:snd()
                -- print 'a paddle horizontal collision\n'
                local a = GamePaddle.y - (self.y + self.w)
                local b = self.y - (GamePaddle.y + GamePaddle.w)
                if a > b then
                    self.y = GamePaddle.y - self.w
                    self.dy = -1
                    -- print 'hit the right of the paddle\n'
                else
                    self.y = GamePaddle.y + GamePaddle.w
                    self.dy = 1
                    -- print 'hit the left of the paddle\n'
                end
                return nil
            end

            if ny < BORDER or ny + self.w > HEIGHT - BORDER or paddleHCollision then
                self:snd()
                local a = self.y - BORDER
                local b = HEIGHT - self.y - self.w
                if a > b then
                    self.y = HEIGHT - BORDER - self.w
                    self.dy = -self.dy
                    -- print 'hit the left of the screen\n'
                else
                    self.y = BORDER
                    self.dy = -self.dy
                    -- print 'hit the right of the screen\n'
                end
                return nil
            end

            for i = 1, #BricksList, 1 do
                local brick = BricksList[i]
                if brick.hp > 0 then
                    local bHCollision = intersection(self.x, ny, self.w, self.h, brick.x, brick.y, brick.w, brick.h)
                    if bHCollision then
                        local a = brick.y - (self.y + self.w)
                        local b = self.y - (brick.y + brick.w)
                        if a > b then
                            self.y = brick.y - self.w
                            self.dy = -1
                            -- print 'hit the right of a brick\n'
                        else
                            self.y = brick.y + brick.w
                            self.dy = 1
                            -- print 'hit the left of a brick\n'
                        end
                        return brick
                    end
                end
            end
            self.y = ny
            return nil
        end,

        update = function(self)
            local brickHitVertical = self:checkVerticalCollision()
            local brickHitHorizontal = self:checkHorizontalCollision()

            if brickHitVertical ~= nil then
                brickHitVertical:snd()
                brickHitVertical.hp -= 1
                PlayerScore.value += brickHitVertical.value
                return
            end
            if brickHitHorizontal ~= nil then
                brickHitHorizontal:snd()
                brickHitHorizontal.hp -= 1
                PlayerScore.value += brickHitHorizontal.value
                return
            end
        end,
    }
    return ball
end

function Paddle()
    print 'Creating paddle...'

    local paddle = {
        x = WIDTH - 28,
        y = (HEIGHT / 2) - (30 / 2),
        speed = 2.5,
        h = 6,
        w = 30,

        snd = function()
            Synth.hitPaddle:playNote('G5', 0.75, 0.05)
        end,

        show = function(self)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(self.x, self.y, self.h, self.w)
        end,

        update = function(self)
            self.dx = 0
            local crank, _ = playdate.getCrankChange()
            local newY = self.y + self.speed * crank
            self.y = clamp(newY, 0, HEIGHT - self.w)
        end,
    }
    return paddle
end

function DrawBackground()
    gfx.clear(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(5, 5, playdate.display.getWidth() - 10, playdate.display.getHeight() - 10)
end

function BuildLevel()
    local rows = 11
    local cols = 8
    local i = 1

    for col = 1, cols, 1 do
        for row = 1, rows, 1 do
            local brick = Brick(BRICK_START_X + (BRICK_H * col) + BRICK_PAD - BRICK_H - 1 + col - 1, BRICK_START_Y - (BRICK_W * row) - BRICK_PAD - row)
            if col <= 2 then
                brick.p = CHECKERED
                brick.value = 4
            elseif col <= 4 then
                brick.p = DIAMOND
                brick.value = 3
            elseif col <= 6 then
                brick.p = BASKET
                brick.value = 2
            elseif col <= 8 then
                brick.p = STRIPE
                brick.value = 1
            end

            -- [[ Some Asertions for sideways sanity ]]
            if col == 1 and row == 1 then
                assert(brick.x == 64)
            end
            if col == 1 and row == 2 then
                assert(brick.x == 64)
            end
            BricksList[i] = brick
            i += 1
        end
    end
end

local function handlAllBricks()
    for b = 1, #BricksList, 1 do
        if BricksList[b].hp > 0 then
            BricksList[b]:show()
            BricksList[b]:update()
        end
    end
end

function Game()
    local game = {
        continue = function()
            GamePaddle = Paddle()
            GameBall = Ball()
        end,
        init = function()
            GamePaddle = Paddle()
            GameBall = Ball()
            PlayerScore = ScoreUI(BORDER + 32, BORDER + 144, 3)
            if HighScore == nil then
                HighScore = ScoreUI(BORDER + 32, BORDER + 39, 3)
                HighScore.value = 0
            end
            DeathCounter = ScoreUI(BORDER + 2, BORDER + 90, 1)
            DeathCounter.value = 0
            PlayerNumber = ScoreUI(BORDER + 2, BORDER + 195, 1)
            PlayerNumber.value = 1
            BuildLevel()
        end,
        checkGameOver = function(self)
            if DeathCounter.value > 3 then
                self:handleHighScore()
                State = 'GameOver'
            else
                State = 'Continue'
            end
        end,
        handleHighScore = function()
            if PlayerScore.value > HighScore.value then
                HighScore.value = PlayerScore.value
            end
        end,
    }
    return game
end

State = 'Start'
Game = Game()

function playdate.update()
    if State == 'Start' then
        Game:init()
        State = 'Pause'
    end
    DrawBackground()
    handlAllBricks()
    GameBall:show()
    GamePaddle:show()
    PlayerScore:show()
    HighScore:show()
    DeathCounter:show()
    PlayerNumber:show()
    if State == 'Game' then
        PlayerScore:update()
        HighScore:update()
        DeathCounter:update()
        PlayerNumber:update()
        GamePaddle:update()
        GameBall:update()
    end
end

function playdate.AButtonDown()
    if State == 'Start' or State == 'Pause' then
        State = 'Game'
    end
    if State == 'Continue' then
        State = 'Game'
        Game:continue()
    end
    if State == 'GameOver' then
        Game:init()
        State = 'Game'
    end
end
