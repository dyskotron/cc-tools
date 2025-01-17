-- Simple Snake Game with Correctly Aligned Right-Side UI for ComputerCraft

-- Setup screen
local w, h = term.getSize()
local uiWidth = 7
local uiCenter = w - 3
local gameWidth = w - uiWidth -- Adjust width for the border and UI
local gameHeight = h -- Full height used for the game

term.clear()

-- Snake initial settings
local snake = {
    {x = math.floor(gameWidth / 2), y = math.floor(gameHeight / 2)} -- Start at the center
}
local direction = {x = 1, y = 0} -- Initial movement direction (right)
local newDirection = direction -- Buffer for the next direction

local PIXEL_EMPTY =  " "
local PIXEL_FOOD =  "*"
local PIXEL_SNAKE_HEAD =  "@"
local PIXEL_SNAKE_BODY =  "#"

-- Food settings
local food = {x = math.random(1, gameWidth), y = math.random(1, gameHeight)}

-- Scoring and speed settings
local score = 0
local level = 1
local stepTime = 0.58 -- Initial step time

-- Speed progression table
local speedDecrements = {
    -0.05, -0.05, -0.05, -0.05, -0.05, -- Levels 1-5
    -0.04, -0.04, -0.04, -0.04, -0.04, -- Levels 6-10
    -0.03, -0.03, -0.03, -0.03, -0.03, -- Levels 11-15
    -0.02, -0.02, -0.02, -0.02,        -- Levels 16-19
    -0.01                              -- Level 20
}

-- Draw the static UI elements (title, labels, and border)
local function drawStaticUI()
    -- Draw the title
    term.setCursorPos(gameWidth + 2, 1)
    term.write("SNAKE")

    -- Draw the labels for level and score
    term.setCursorPos(gameWidth + 2, 3)
    term.write("Level:")
    term.setCursorPos(gameWidth + 2, 5)
    term.write("Score:")

    -- Draw the right border
    for y = 1, h do
        term.setCursorPos(gameWidth + 1, y)
        term.write("|")
    end
end

local function writeUiCentered(str, y)
    term.setCursorPos(gameWidth + 2, y)
    term.write("      ")
    term.setCursorPos(uiCenter, y)
    term.write(str)
end

-- Display the game over screen
local function displayGameOver()
    term.clear()
    local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
    local borderWidth = 30
    local startX = centerX - math.floor(borderWidth / 2)

    -- Draw the border
    term.setCursorPos(startX, centerY - 1)
    term.write("+" .. string.rep("-", borderWidth - 2) .. "+")
    for i = 0, 2 do
        term.setCursorPos(startX, centerY + i)
        term.write("|" .. string.rep(" ", borderWidth - 2) .. "|")
    end
    term.setCursorPos(startX, centerY + 3)
    term.write("+" .. string.rep("-", borderWidth - 2) .. "+")

    -- Display "GAME OVER" message
    term.setCursorPos(centerX - 5, centerY)
    term.write("GAME OVER")

    -- Display the score
    term.setCursorPos(centerX - 6, centerY + 1)
    term.write("Score: " .. tostring(score))

    -- Display buttons
    term.setCursorPos(startX + 1, centerY + 2)
    term.write("[Q]uit")
    term.setCursorPos(startX + borderWidth - 9, centerY + 2) -- Right-aligned
    term.write("[R]eplay")

    -- Handle input for quit or replay
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.q then
            term.clear()
            term.setCursorPos(1, 1)
            return false -- Exit the game
        elseif key == keys.r then
            return true -- Restart the game
        end
    end
end


-- Update only the dynamic UI values (level and score)
local function updateDynamicUI()
    writeUiCentered(tostring(level), 4)
    writeUiCentered(tostring(score), 6)
end

-- Draw a pixel at a specific position
local function drawPixel(segment, char)
    if segment.x <= gameWidth then -- Ensure within the game area
        term.setCursorPos(segment.x, segment.y)
        term.write(char)
    end
end

-- Erase the snake segment at a specific position
local function eraseSegment(segment)
    drawPixel(segment, PIXEL_EMPTY)
end

-- Check if a position collides with the snake
local function isPositionOnSnake(x, y)
    for _, segment in ipairs(snake) do
        if segment.x == x and segment.y == y then
            return true
        end
    end
    return false
end

local function initGame()
    score = 0
    level = 1
    stepTime = 0.58
    food = {x = math.random(1, gameWidth), y = math.random(1, gameHeight)}
    snake = {
        {x = math.floor(gameWidth / 2), y = math.floor(gameHeight / 2)} -- Start at the center
    }

    term.clear()
    drawStaticUI()
    updateDynamicUI()
end

-- Spawn and draw food in a valid position
local function spawnFood()
    repeat
        food.x = math.random(1, gameWidth)
        food.y = math.random(1, gameHeight)
    until not isPositionOnSnake(food.x, food.y)

    drawPixel(food, PIXEL_FOOD)
end

-- Update the snake's position
local function updateSnake()
    -- Apply the buffered direction immediately
    direction = newDirection

    local head = snake[1]
    local oldHead = head
    local newHead = {x = head.x + direction.x, y = head.y + direction.y}

    -- Check for collision with walls
    if newHead.x < 1 or newHead.x > gameWidth or newHead.y < 1 or newHead.y > gameHeight then
        return false
    end

    -- Check for collision with itself
    for _, segment in ipairs(snake) do
        if segment.x == newHead.x and segment.y == newHead.y then
            return false
        end
    end

    -- Add the new head
    table.insert(snake, 1, newHead)
    drawPixel(newHead, PIXEL_SNAKE_HEAD) -- Draw the new head
    drawPixel(oldHead, PIXEL_SNAKE_BODY) -- Convert old head to body

    -- Check if food is eaten
    if newHead.x == food.x and newHead.y == food.y then
        -- Increase score dynamically
        score = score + 1 + math.floor(#snake / 5)

        -- Level up every 10 foods
        if score % 10 == 0 and level < #speedDecrements then
            level = level + 1
            stepTime = stepTime + speedDecrements[level]
        end

        spawnFood()

        updateDynamicUI() -- Update UI with new score and level
    else
        -- Remove the tail if no food is eaten
        local tail = table.remove(snake)
        eraseSegment(tail)
    end

    return true
end

-- Change direction based on user input
local function handleInput()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.up and direction.y == 0 then
            newDirection = {x = 0, y = -1}
        elseif key == keys.down and direction.y == 0 then
            newDirection = {x = 0, y = 1}
        elseif key == keys.left and direction.x == 0 then
            newDirection = {x = -1, y = 0}
        elseif key == keys.right and direction.x == 0 then
            newDirection = {x = 1, y = 0}
        end
    end
end

-- Game loop
local function gameLoop()
    -- Draw the initial UI, food, and snake
    drawStaticUI()
    updateDynamicUI()
    spawnFood()
    drawPixel(snake[1], PIXEL_SNAKE_HEAD)

    while true do
        local frameStart = os.clock()

        -- Update snake position
        if not updateSnake() then
            if(displayGameOver()) then
                initGame()
            else
                break
            end
        end

        -- Sleep the remaining time for the current step
        local elapsed = os.clock() - frameStart
        if elapsed < stepTime then
            sleep(stepTime - elapsed)
        end
    end
end

-- Start the game using parallel execution
parallel.waitForAny(handleInput, gameLoop)
