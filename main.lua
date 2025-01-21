function love.load()

    math.randomseed(os.time())

    sprites = {}
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.zombie = love.graphics.newImage('sprites/zombie.png')

    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() /2
    player.speed = 180
    player.state = 1
    injuredTimer = 2

    myFont  = love.graphics.newFont(40)

    zombies = {}
    bullets = {}

    gameState = 1
    maxTime = 2
    score = 0
    timer = maxTime
end

function love.update(dt)

    if gameState == 2 then
        if love.keyboard.isDown('d') and player.x < love.graphics.getWidth() then
            player.x = player.x + player.speed * dt
        end
        if love.keyboard.isDown('a') and player.x > 0 then
            player.x = player.x - player.speed * dt
        end
        if love.keyboard.isDown('w') and player.y > 0 then
            player.y = player.y - player.speed * dt
        end
        if love.keyboard.isDown('s') and player.y < love.graphics.getHeight() then
            player.y = player.y + player.speed * dt
        end
    end

    --]] iterador sendo utilizado para a movimentacao do zumbi
    --[[ 
     ->  movimentacao em X utiliza o coseno do calculo angulo do zumbi referente ao player
     ->  movimentacao em Y utiliza o seno do calculo angulo do zumbi referente ao player
    --]]
    
    for i,z in ipairs(zombies) do 
        z.x = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
        z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)

        if distanceBetween(z.x,z.y, player.x, player.y) < 30 then -- utiliza a distancia entre para verificar colisao
            for i,z in ipairs(zombies) do
                --[[
                zombies[i] = nil
                gameState = 1
                player.state = 2
                player.x = love.graphics.getWidth()/2
                player.y = love.graphics.getHeight()/2
                --]]
                -- player state 1 = normal player
                -- player state 2 = injured player


                if player.state == 1 then
                    zombies[i] = nil
                    player.state = 2
                    player.speed = player.speed * 2
                    injuredTimer = injuredTimer - dt
                    
                   
                elseif player.state == 2 then
                    zombies[i] = nil
                    player.state = 1
                    player.speed = 180
                    gameState = 1
                    player.x = love.graphics.getWidth()/2
                    player.y = love.graphics.getHeight()/2

                end
            end
        end
        

    end

    for i, b in ipairs(bullets) do 
        b.x = b.x + (math.cos(b.direction) * b.speed * dt)
        b.y = b.y + (math.sin(b.direction) * b.speed * dt)
    end

    --iterador para remover projetil do jogo caso for para fora da tela
    for i=#bullets, 1, -1 do
        local b = bullets[i]  
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    -- iterador de zumbi e projetil para detectar colisao e destruir ambos
    for i,z in ipairs(zombies) do
        for j,b in ipairs(bullets) do 
            if distanceBetween(z.x, z.y,b.x,b.y) < 20 then
                z.dead = true
                b.dead = true
                score = score + 1
            end
        end
    end

    for i=#zombies,1,-1 do
        local z = zombies[i]
        if z.dead == true then
            table.remove(zombies,i)
        end
    end

    for i =# bullets, 1, -1 do
        local b = bullets[i]
        if b.dead == true then
            table.remove(bullets, i)
        end
    end

    if gameState == 2 then
        timer = timer - dt
        if timer <= 0 then
            spawnZombie()
            maxTime = 0.95 * maxTime --acelerar o spawn de zumbi conforme o jogo continua
            timer = maxTime -- reseta o timer de spawn de zumbi
        end
    end
end

function love.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(sprites.background, 0, 0)

    if gameState == 1 then
        love.graphics.setFont(myFont) 
        love.graphics.printf("Click anywhere to begin!", 0, 50, love.graphics.getWidth(),"center")
    end
    love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")
    love.graphics.printf("Player.State: " .. player.state,0, love.graphics.getHeight() - 200, love.graphics.getWidth(), "center")

    for i,z in ipairs(zombies)do 
        love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
    end

    for i, b in ipairs(bullets) do --iterador que vai gerar o projetil conforme pressionar o botao
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, nil, sprites.bullet:getWidth()/2, sprites.zombie:getHeight()/2)
    end

    if player.state == 1 then
        love.graphics.setColor(1,1,1)
        love.graphics.draw(sprites.player, player.x,player.y, playerMouseAngle() ,nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)

    elseif player.state == 2 then
        love.graphics.setColor(1,0,0)
        love.graphics.draw(sprites.player, player.x,player.y, playerMouseAngle() ,nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)
    end


    
end

function love.keypressed(key) -- funcao do love para botao pressionado uma unica vez
    if key == "space" then
       -- spawnZombie()
    end
end

function love.mousepressed(x,y, button) -- funcao para os botoes do moues
    if  button == 1 and gameState == 2 then
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        gameState = 2
        maxTime = 2
        score = 0
    end
end


function playerMouseAngle() --player rotacionar na direção do mouse

    --formula para retornar o arco da tangente do coeficiente dor argumentos informados
    return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombiePlayerAngle(enemy) --funcao para direcionar o zumbi em direção ao jogador
    return math.atan2(player.y - enemy.y, player.x - enemy.x) 
end


function spawnZombie() --função para gerar um zumbi
    local zombie = {}
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = math.random(0, love.graphics.getHeight())
    zombie.speed = 140
    zombie.dead = false

    local side = math.random(1,4)

    if side == 1 then
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 2 then
        zombie.x = love.graphics.getWidth() + 30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = 30
    elseif side == 4 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = love.graphics.getHeight() + 30
    end

    table.insert(zombies, zombie)
end

function spawnBullet() --funcao para gerar uma munição
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.dead = false
    bullet.direction = playerMouseAngle()
    table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2) --calcular distancia entre dois objetos
    return math.sqrt((x2-x1)^2 + (y2 - y1)^2)
end