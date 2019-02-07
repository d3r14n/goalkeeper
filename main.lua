function collision(object1X, object1Y, object1Width, object1Height, object2X, object2Y, object2Width, object2Height)
	if object1X < object2Width and object1Width > object2X and object1Y < object2Height and object1Height > object2Y then
		return true
	else
		return false
	end
end

function newAnimation(image, width, height, duration)
	local animation = {}
	animation.spriteSheet = image
	animation.quads = {}

	for y=0, image:getHeight() - height, height do
		for x=0, image:getWidth() - width, width do
			table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
		end
	end

	animation.duration = duration or 1
	animation.currentTime = 0

	return animation
end

function getImageScaleForNewDimensions(image, newWidth, newHeight)
    local currentWidth, currentHeight = image:getDimensions()
    return (newWidth / currentWidth), (newHeight / currentHeight)
end

function love.load()
	love.window.setFullscreen(true)
	love.window.setTitle("Goalkeeper") --Titulo
	windowWidth, windowHeight = love.graphics.getDimensions( )
	love.mouse.setVisible(false) --Ocultar Mouse
	background = love.graphics.newImage("sprites/bg.png")

	gameOver = false
	score = 0
	lives = 5
	liveSprite = love.graphics.newImage("sprites/life.png")
	canLoseLives = true

	gravity = windowHeight/128

	fieldHeight = windowHeight/1.1


	keeper = love.graphics.newImage("sprites/player.png")
	keeperX = windowWidth/8
	keeperY = windowHeight/1.5
	keeperWidth = 25
	keeperHeight = 25
	keeperGroundShotPower = 1.8
	keeperAirShotPower = 0.15
	jumpSprite = love.graphics.newImage("sprites/playerJump.png")
	jump = false
	hasJumped = false
	runSprite = love.graphics.newImage("sprites/playerRun.png")
	runAnimation = newAnimation(runSprite, keeperWidth, keeperHeight, 0.5)
	run = false
	runningBackwards = false

	oneBall = love.graphics.newImage("sprites/ball.png")
	ball = love.graphics.newImage("sprites/balls.png")
	ballAnimation = newAnimation(ball, 15, 14, 0.2)
	ballX = windowWidth
	ballY = love.math.random(0, fieldHeight-15)
	ballBounce = false
	ballFall = 0
	ballMinSpeed = windowWidth/1024
	ballMaxSpeed = windowWidth/64
	ballSpeedX = love.math.random(ballMinSpeed, ballMaxSpeed)
	ballReturn = false
	catched = false

end

function love.update(dt)
	runAnimation.currentTime = runAnimation.currentTime + dt
	if runAnimation.currentTime >= runAnimation.duration then
		runAnimation.currentTime = runAnimation.currentTime - runAnimation.duration
	end

	ballAnimation.currentTime = ballAnimation.currentTime + dt
	if ballAnimation.currentTime >= ballAnimation.duration then
		ballAnimation.currentTime = ballAnimation.currentTime - ballAnimation.duration
	end

	windowWidth, windowHeight = love.graphics.getDimensions()
	fieldHeight = windowHeight/1.1
	goalWidth = windowWidth/16
	goalHeight = windowHeight/1.8
	keeperXSpeed = windowWidth/256
	keeperJumpHeight = goalHeight - windowHeight/1024

	keeperY = keeperY + gravity
	run = false

	bgScaleX, bgScaleY = getImageScaleForNewDimensions(background, windowWidth, windowHeight)

	if collision(keeperX, keeperY, keeperX+keeperWidth, keeperY+keeperHeight, 0, fieldHeight, windowWidth, windowHeight) then
			keeperY = fieldHeight-keeperHeight
			jump = false
			hasJumped = false
	end

	if collision(keeperX, keeperY, keeperX+keeperWidth, keeperY+keeperHeight, ballX, ballY, ballX+15, ballY+15) then
		ballReturn = true
		ballBounce = true
		ballSpeedX = love.math.random(ballMinSpeed, ballMaxSpeed)
		if jump or hasJumped then
			if runningBackwards then
				ballSpeedX = ballSpeedX * keeperAirShotPower
			else
				if love.math.random(0, 1) == 1 then
					ballSpeedX = ballSpeedX * 0
					catched = true
				else
					ballSpeedX = ballSpeedX * keeperAirShotPower
				end
			end
		else
			ballSpeedX = ballSpeedX * keeperGroundShotPower
		end
	end

	if catched and hasJumped and not ballReturn then
		ballX = keeperX + keeperWidth
		ballY = keeperY + keeperHeight
	end

	if ballX > windowWidth then
		ballReturn = false
		ballY = love.math.random(0, fieldHeight-15)
		ballBounce = false
		ballFall = 0
		ballSpeedX = love.math.random(ballMinSpeed, ballMaxSpeed)
		score = score + 1
	end

	if love.keyboard.isDown("up") or love.keyboard.isDown("space") then
		hasJumped = true
		if not jump then
			keeperY = keeperY - (gravity+10)
			if keeperY < keeperJumpHeight then
				jump = true
			end
		end
	end

	function love.keyreleased(key)
   		if key == "up" or key == "space" then
   			jump = true
   		end
	end

	if love.keyboard.isDown("left") then
		if keeperX > 0 then
			keeperX = keeperX - keeperXSpeed
			run = true
			runningBackwards = true
			catched = false
		end
	end
	if love.keyboard.isDown("right") then
		if keeperX < windowWidth-keeperWidth then
			keeperX = keeperX + keeperXSpeed
			run = true
			runningBackwards = false
		end
	end

	if (ballY > fieldHeight and not ballBounce) or collision(ballX, ballY, ballX+15, ballY+15, 0, fieldHeight, windowWidth, windowHeight) then
		ballBounce = true
		catched = false
		ballFall = ballFall * 0.8
		if ballX > 0 then
			ballSpeedX = ballSpeedX * 0.8
		end
		if ballY > windowHeight-fieldHeight+15 then
			ballY = fieldHeight-20
		end
	end
	if ballBounce then
		ballY = ballY - ballFall
		ballFall = ballFall - gravity/60
		if ballFall < 0 then
			ballBounce = false
		end
	else
		ballY = ballY + ballFall
		ballFall = ballFall + gravity/60
	end

	if ballX > 0 then
		if ballReturn then
			ballX = ballX + ballSpeedX
		else
			ballX = ballX - ballSpeedX
		end
	else
		ballX = 0
	end

	if ballX <= 0  or ballY > windowHeight then
		if ballX<=0 and ballY > goalHeight and canLoseLives then
			lives = lives - 1
			canLoseLives = false
		end
		ballX = windowWidth
		ballY = love.math.random(0, fieldHeight-15)
		ballBounce = false
		ballSpeedX = love.math.random(ballMinSpeed, ballMaxSpeed)
		canLoseLives = true
	end

	if lives <= 0 then
		gameOver = true
	end

	if love.keyboard.isDown("escape") then
		love.window.close()
	end
end

function love.draw()
	if gameOver then
		love.graphics.print("GAME OVER", windowWidth/2, windowHeight/2)
		if love.keyboard.isDown("escape") then
			love.window.close()
		end
		if love.keyboard.isDown("return") or love.keyboard.isDown("space") or love.mouse.isDown(1,2) then
			gameOver = false
			score = 0
			lives = 5
			liveSprite = love.graphics.newImage("sprites/life.png")
			canLoseLives = true

			gravity = windowHeight/128

			keeper = love.graphics.newImage("sprites/player.png")
			keeperX = windowWidth/8
			keeperY = windowHeight/1.5
			jump = false
			hasJumped = false

			ballX = windowWidth
			ballY = love.math.random(0, fieldHeight-15)
			ballBounce = false
			ballFall = 0
			ballMinSpeed = windowWidth/1024
			ballMaxSpeed = windowWidth/64
			ballSpeedX = love.math.random(ballMinSpeed, ballMaxSpeed)
			catched = false
		end
	else
		love.graphics.draw(background, x, y, rotation, bgScaleX, bgScaleY)

		love.graphics.setColor(0, 0, 0)
		love.graphics.print("SCORE: "..score, 100, 50)
		love.graphics.reset()
		for i=1,lives do
			love.graphics.draw(liveSprite, 80+(i*20), 80)
		end

		love.graphics.setColor(0, 0, 0, 0)
		love.graphics.rectangle("fill", 0, fieldHeight, windowWidth, windowHeight-fieldHeight)
		love.graphics.reset()

		if hasJumped then
			if runningBackwards then
				love.graphics.draw(jumpSprite, keeperX, keeperY, 0, -1, 1)
			else
				love.graphics.draw(jumpSprite, keeperX, keeperY)
			end
		else
			if run then
				local spriteNum = math.floor(runAnimation.currentTime / runAnimation.duration * #runAnimation.quads) + 1
				if runningBackwards then
					love.graphics.draw(runAnimation.spriteSheet, runAnimation.quads[spriteNum], keeperX, keeperY, 0, -1, 1)
				else
					love.graphics.draw(runAnimation.spriteSheet, runAnimation.quads[spriteNum], keeperX, keeperY)
				end
			else
				if runningBackwards then
					love.graphics.draw(keeper, keeperX, keeperY, 0, -1, 1)
				else
					love.graphics.draw(keeper, keeperX, keeperY)
				end
			end
		end

		love.graphics.setLineWidth(10)
		love.graphics.setColor(64, 64, 64)
		love.graphics.line(0, windowHeight, 0, goalHeight, goalWidth, goalHeight)
		love.graphics.reset()

		if ballSpeedX > 0.1 then
			ballSpriteNum = math.floor(ballAnimation.currentTime / ballAnimation.duration * #ballAnimation.quads) + 1
			if ballReturn then
				love.graphics.draw(ballAnimation.spriteSheet, ballAnimation.quads[ballSpriteNum], ballX, ballY, 0, -1, 1)
			else
				if ballSpriteNum > 3 then
				    ballSpriteNum = 3
				end
				love.graphics.draw(ballAnimation.spriteSheet, ballAnimation.quads[ballSpriteNum], ballX, ballY)
			end
		else
			if ballReturn then
				love.graphics.draw(oneBall, ballX, ballY, 0, -1, 1)
			else
				love.graphics.draw(oneBall, ballX, ballY)
			end
		end
	end
end