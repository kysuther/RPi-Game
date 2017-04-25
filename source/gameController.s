/*
	Code Written by Kyle Sutherland and Brian Brzezina
	
	This file deals with the game. It includes all the shooting, point getting,
	ai movement, movement by user, updating of the screen, score updating 
	and interface. Deals with the pause menu as well.

	Presenting the Game loop

*/
.section .text

/*
	This function deals with starting a new game
*/

.global startGame
startGame:

	push {r0-r8, lr}
	bl displayInitScreen                    // Displays initial screen
	
preStartLoop:
	bl readSNES                             // Reads from SNES
	bl interpreteSNES                       // Interpretes SNES and returns int value 
	
	cmp r0, #4                              // If start is pressed, game starts
	beq gameStart
	
	b preStartLoop

gameStart:

	bl clearScreen                          // Clears Screen

	ldr r0, =0xFFFF                         // Black
	ldr r1, =score                          // Address of score 
	bl displayScore                         // Displays score
 
	ldr r0, =gameboard                      // Address of gameboard
	bl displayGameBoard                     // Displays the gameboard

gameLoop:

	ldr r8, =gamestate                      // Loads Address of gamestate
	ldr r8, [r8]
	
	cmp r8, #'p'                            // checks if gamestate is pause
	beq gamePause
	
	cmp r8, #'r'                            // checks if gamestate is still playing
	bne gameOver

	bl readSNES                             // Reads SNES
	bl interpreteSNES                       // Interpretes SNES and returns int value
	mov r4, r0                              // return value into r4

	cmp r4, #9                              // If A is pressed
	bleq userShoot

	cmp r4, #8                              // If Right is pressed
	bleq moveUserRight

	cmp r4, #7                              // If Left is pressed
	bleq moveUserLeft

	cmp r4, #4                              // If start is pressed
	bleq gamePause

	mov r0, #16                             // First arg = 16
	mov r1, #2                              // Second arg = 2
	
	bl updateAi	                            // Updates Ai
	bl updateBalistics                      // Updates User Balisitics
	bl updateEnemyBalistics                 // Updates Enemy Balistics


	ldr r0, =gameboard                      // Loads gameboard address
	bl displayGameBoard                     // Displays board
	
drawbreak:

	ldr r0, =0x20003004                     // Address of CLO
	ldr r1, [r0]
	add r1, #131072                         // 131072 Microseconds
	
waitLoop:

	ldr r2, [r0]                            // Address of CLO
	cmp r1, r2                              // Stops when CLO is equal to r1
	bhi waitLoop

	ldr r8, =enemiesOnBoard                 //Loads number of enemies on board
	ldr r8, [r8]  
	cmp r8, #0                              // Checks if enemy count is 0
	bgt endCheckWin

	ldr r8, =gamestate                      // load game state
	mov r7, #'w'                            // change to won
	str r7, [r8]                            // stores back gamestate

endCheckWin:

	ldr r8, =score                          // Loads score
	ldr r8, [r8]                            
	cmp r8, #0                              // Checks if score is 0
	bgt gameCont

	ldr r8, =gamestate                      // loads game state
	mov r7, #'l'                            // changes to lost
	str r7, [r8]                            // Stores back gamestate
	
gameCont:
	b gameLoop                              // loops around

gamePause:

gamePauseLoop:

	ldr r0, =gameboard                      // Loads gameboard address
	bl displayPauseMenu                     // Displays pause menu
	
	ldr r0, =0x20003004                     // Address of CLO
	ldr r1, [r0]
	add r1, #262144                         // 262144 Micro seconds
	
waitLoop2:

	ldr r2, [r0]                            // Addres of CLO
	cmp r1, r2                              // Stops when CLO is equal to r1
	bhi waitLoop2
	
gamePauseResumeLoop:

	bl displayPauseMenu                     // display Pause Menu
	bl borderSelectResume                   // Display selection border
	
	ldr r0, =0x20003004                     // Address of CLO
	ldr r1, [r0]
	add r1, #131072                         // 131072 Micro seconds
	
waitPauseLoop:
	
	ldr r2, [r0]                            // Address of CLO
	cmp r1, r2                              // Stops when CLO is equal to r1
	bhi waitPauseLoop	
	
gamePauseResumeLoop1:
	
	bl readSNES                             // Read SNES
	bl interpreteSNES                       // Interpretes SNES and return int value
	
	cmp r0, #4                              // If Start is pressed 
	bleq gamePauseResume
	cmp r0, #6                              // If Down is pressed
	bleq gamePauseRestartLoop
	cmp r0, #9                              // If A is pressed
	bleq gamePauseResume
	
	b gamePauseResumeLoop1                  // Else loops

gamePauseRestartLoop:
	
	bl displayPauseMenu                     // Display Pause Menu
	bl borderSelectRestart                  // Display selection border
	
	ldr r0, =0x20003004                     // Address of CLO
	ldr r1, [r0]
	add r1, #131072                         // 131072 Micro seconds
	
waitPauseLoop1:
	
	ldr r2, [r0]                            // Address of CLO
	cmp r1, r2                              // Stops when CLO is equal ro r1
	bhi waitPauseLoop1 
	
gamePauseRestartLoop1:
	
	bl readSNES                             // Read SNES
	bl interpreteSNES                       // Interpretes SNES and returns int value
	
	cmp r0, #4                              // If Start is pressed
	bleq gamePauseResume
	cmp r0, #5                              // If Up is pressed
	bleq gamePauseResumeLoop
	cmp r0, #6                              // If down is pressed
	bleq gamePauseQuitLoop
	cmp r0, #9                              // If A is pressed
	bleq gamePauseRestart
	
	b gamePauseRestartLoop1                 // Loops

gamePauseQuitLoop:
	
	bl displayPauseMenu                     // display pause Menu
	bl borderSelectQuit                     // Displays selection border
	
	ldr r0, =0x20003004                     // Address of CLO
	ldr r1, [r0]                           
	add r1, #131072                         // 131072 Micro Seconds
	
waitPauseLoop2:
	
	ldr r2, [r0]                            // Address of CLO
	cmp r1, r2                              // Stops when CLO is equal to r1
	bhi waitPauseLoop2
	
gamePauseQuitLoop1:
	
	bl readSNES                             // Read SNES
	bl interpreteSNES                       // Interpretes SNES and returns int value
	
	cmp r0, #4                              // If start is pressed
	bleq gamePauseResume 
	cmp r0, #5                              // If Up is pressed
	bleq gamePauseRestartLoop
	cmp r0, #9                              // If A is pressed
	bleq gamePauseQuit
	
	b gamePauseQuitLoop1                    // Loop

gamePauseResume:
	
	bl clearMenuScreen                      // Menu screen is cleared 
	ldr r0, =0xFFFF                         // White
	ldr r1, =score                          // Address of Score
	bl displayScore                         // Display score

	ldr r0, =0x20003004                     // CLO is addressed
	ldr r1, [r0]
	add r1, #262144                         // 262144 micro seconds
	 
waitLoopOnResume:
	
	ldr r2, [r0]
	cmp r1, r2                              // Stops when CLO is equal to r1
	bhi waitLoopOnResume

	b gameCont

gamePauseRestart:
	
	bl resetGame                            // Game is restarted
	b gameStart                             // Game Start

gamePauseQuit:
	
	bl resetGame                            // Game is restarted 
	b startGame                             // Game start
	
gameOver:
	
	ldr r8, =gamestate                      // Load gamestate
	ldr r8, [r8]
	
	cmp r8, #'l'                            // checks if gamestate is lost
	beq gameLost

gameWon:
	
	bl displayWinScreen                     // Display win screen
	b gameHaltLoop                          // Goes to Halt loop

gameLost:
	
	bl displayLoseScreen                    // Display lose screen
	b gameHaltLoop                          // Goes to Halt loop

gameHaltLoop:
	
	bl readSNES                             // Reads SNES
	bl interpreteSNES                       // Interpretes SNES and returns int value
	
	cmp r0, #4                              // If start is pressed
	beq gameRestarted
	cmp r0, #5                              // If up is pressed
	beq gameRestarted
	cmp r0, #6                              // If down is pressed
	beq gameRestarted
	cmp r0, #7                              // If left is pressed
	beq gameRestarted
	cmp r0, #8                              // If right is pressed
	beq gameRestarted
	cmp r0, #9                              // If A is pressed
	beq gameRestarted
	
	b gameHaltLoop                          // Loop

gameRestarted:
	
	bl resetGame                            // Reset game
	b startGame                             // Start Game
 
gameClosed:
	
	pop {r0-r8, lr}
	bx lr


/* 
	Calculates the offset of the array (((32*x)+y)*4)
	r0 - x value
    r1 - y value
    Result returned in the r0 register
 */
 
	.global calcArrOffset
calcArrOffset:

	push {r4-r8, lr}
	
	mov r4, #32                             // r4 = 32
	mla r6, r4, r1, r0
	mov r0, r6                              // r0 = r6
	lsl r0, #2                              // Lsl by 2

	pop {r4-r8, lr}
	bx lr

/*
	This function deals with the user moving right on the screen
*/

	.global moveUserRight
moveUserRight:
	
	push {r4-r8,lr}

	ldr r4, =userLoc                        // Loads users location
	ldr r0, [r4]
	ldr r1, [r4, #4]                        // loads users right location
	bl calcArrOffset
	
	mov r7, r0                              // r7 = offset
	add r8, r7, #4                          // adds offset + 4

	ldr r4, =gameboard                      // loads gameboard
	ldr r5, [r4, r8]                        // loads location by offset

	cmp r5, #'b'                            // if location is border
	beq endMoveUserRight

	mov r5, #'u'                            // Move user
	str r5, [r4, r8]                        // Store to Gameboard
	
	mov r5, #'R'                            // Move R
	str r5, [r4, r7]                        // Store to Gameboard

	ldr r4, =userLoc                        // Load users location
	ldr r0, [r4]
	add r0, #1                              // Increment by 1
	str r0, [r4]                            // Store update location

endMoveUserRight:

	pop {r4-r8, lr}
	bx lr

/*
	This function moves the user to the left
*/

	.global moveUserLeft
moveUserLeft:

	push {r4-r8,lr}

	ldr r4, =userLoc                        // Loads User location
	ldr r0, [r4]
	ldr r1, [r4, #4]                        // Location of user location +4
	bl calcArrOffset                        
	
	mov r7, r0                              // r7 = offset
	sub r8, r7, #4                          // offset - 4

	ldr r4, =gameboard                      // Load gameboard
	ldr r5, [r4, r8]                        // Load location with offset

	cmp r5, #'b'                            // checks if a boarder
	beq endMoveUserLeft

	mov r5, #'u'                            // Moves User
	str r5, [r4, r8]                        // Store in new location
	
	mov r5, #'R'                            // move R
	str r5, [r4, r7]                        // Store in old location

	ldr r4, =userLoc                        // Load user location
	ldr r0, [r4]
	sub r0, #1                              // Subtract by 1
	str r0, [r4]                            // Store new location

endMoveUserLeft:

	pop {r4-r8, lr}
	bx lr

/*
	This function is for creating a shot for the user. This happens
	when the user presses A.
*/

	.global userShoot
userShoot:

	push {r4-r8, lr}

	ldr r4, =userLoc                        // Loads users locations
	ldr r0, [r4]
	ldr r1, [r4, #4]                        // Loads location + 4
	sub r1, #1                              // Decrement by 1
	bl calcArrOffset
	
	mov r7, r0                              // r7 = offset

	ldr r4, =gameboard                      // load gameboard
	ldr r5, [r4, r7]                        // Load gameboard with offset

	cmp r5, #'f'                            // checks if it equals user shot
	beq endUserShoot

	mov r5, #'f'                            // Moves F
	str r5, [r4, r7]                        // Stores in location
	
endUserShoot:
	
	pop {r4-r8, lr}
	bx lr

/* 
	Puts a bullet in front of a specified enemy
    inputs:
    r0 - enemy x value
    r1 - enemy y value
*/

	.global enemyShoot
enemyShoot:

	push {r4-r8, lr}

	mov r4, r0                              // X location of Enemy
	mov r5, r1                              // Y location of Enemy

	add r1, #1                              // r1 = r1 + 1
	bl calcArrOffset                
	mov r7, r0                              // r7 = offset

	ldr r4, =gameboard                      // Load gameboard
	ldr r5, [r4, r7]                        // load gameboard with offset

	cmp r5, #'e'                            // Checks if enemy bullet there
	beq endEnemyShoot

	mov r5, #'e'                            // Move E
	str r5, [r4, r7]                        // Stores enemy bullet to board
	
endEnemyShoot:
	
	pop {r4-r8, lr}
	bx lr

/* 
	Decides if an enemy should shoot based on the users location
 	takes no inputs, gets user location from memory
 	and uses a memory counter to stop constant fire
*/

	.global decideAiShoot
decideAiShoot:
	push {r4-r8, lr}

	ldr r4, =enemyFireCounter               // Loads Enemy fire Counter
	ldr r5, [r4]
	cmp r5, #3			                    // Checks if Enemy Fire Counter is equal to 3
	bne noShootAi

	ldr r4, =userLoc                        // Load users location
	ldr r5, [r4, #4]	                    // User y value
	ldr r4, [r4]		                    // User x value

	ldr r8, =gameboard                      // Loads gameboard

shootLoop:

	sub r5, #1                              // Counter decrement
	mov r0, r4                              // X value
	mov r1, r5                              // Y value
	bl calcArrOffset
	ldr r7, [r8,r0]                         // Load gameboard with offset
	cmp r7, #'b'                            // checks if hit border
	beq endShootLoop

	cmp r7, #'1'                            // checks if 1
	beq fireAiBullet
	cmp r7, #'2'                            // checks if 2
	beq fireAiBullet
	cmp r7, #'3'                            // checks if 3
	beq fireAiBullet                        
	cmp r7, #'4'                            // checks if 4
	beq fireAiBullet
	cmp r7, #'5'                            // checks if 5
	beq fireAiBullet
	cmp r7, #'6'                            // checks if 6
	beq fireAiBullet

	b shootLoop

endShootLoop:

	b noShootAi

fireAiBullet:

	mov r0, r4                              // X value
	mov r1, r5                              // Y value
	bleq enemyShoot

noShootAi:

	ldr r4, =enemyFireCounter               // Load enemy fire counter
	ldr r5, [r4]
	cmp r5, #3					            //Checks enemyFireCounter
	bge resetAiShootCounter
	ldr r4, =enemyFireCounter               // Loads enemy fire counter
	add r5, #1                              // Increments by 1
	str r5, [r4]                            // Stores Enemy fire counter
	
	b endDecideAiShoot

resetAiShootCounter:

	ldr r4, =enemyFireCounter               // Load enemy fire counter
	mov r5, #0                              // Resets counter
	str r5, [r4]                            // Stores 
	
endDecideAiShoot:

	pop {r4-r8, lr}
	bx lr

/*
	This function updates the ai movemebt on the board 	
*/
	.global updateAi
updateAi:
	push {r3-r8, lr}
	
	ldr r3, =queenMoveDir                   // Direction queen is moving
	ldr r4, [r3]
	mov r0, #2                              // r0 = 2
	cmp r4, #'r'                            // Checks if direction is right
	beq queenRight

	bl moveAiRowLeft                        // if not then left
	b queenEnd

queenRight:

	bl moveAiRowRight                       // Ai moves right
	
queenEnd:
	str r0, [r3]                            // Stores new location of queen

	ldr r3, =knightMoveDir                  // Direction Knight is moving
	ldr r4, [r3]
	mov r0, #6                              // r0 = 6
	cmp r4, #'r'                            // checks if direction is right
	beq knightRight

	bl moveAiRowLeft                        // If not, then left
	b knightEnd

knightRight:
	
	bl moveAiRowRight                       // Ai moves right
	
knightEnd:

	str r0, [r3]                            // Stores location of knight

	ldr r3, =pawnMoveDir                    // Direction of Pawn
	ldr r4, [r3]
	mov r0, #10                             // r0 = 10
	cmp r4, #'r'                            // Checks if direction is right
	beq pawnRight

	bl moveAiRowLeft                        // if not then left
	b pawnEnd

pawnRight:

	bl moveAiRowRight                       // Ai move right
	
pawnEnd:

	str r0, [r3]                            // stores location of pawn            

	bl decideAiShoot                        // decide ai shoots
	
	pop {r3-r8, lr}
	bx lr

/* 
	Takes in a row and moves every object in that row left
 	r0 - row
 */
 
	.global moveAiRowLeft
moveAiRowLeft:
	push {r3-r8, lr}

	ldr r3, =gameboard                      // Loads gameboard
	mov r5, r0                              // Row Value
	mov r4, #1					            // Start of search for object

	mov r0, r4                              // X Value
	mov r1, r5                              // Y Value
	bl calcArrOffset

	ldr r8, [r3, r0]                        // Loads gameboard with offset

	cmp r8, #'f'				            //Ignores bullets at border
	beq detectObjectLeft     
	cmp r8, #'e'                            // checks if enemy bullet
	beq detectObjectLeft
 
	cmp r8, #''                             // Checks if empty
	bne objectsAtLeftBorder

detectObjectLeft:

	add r4, #1                              // increment row
	mov r0, r4                              // X value
	mov r1, r5                              // Y value
	bl calcArrOffset

	ldr r8, [r3, r0]                        // Loads gameboard with offset
	cmp r8, #'b'                            // checks for border
	beq objectsNotAtLeftBorder

	cmp r8, #'f'				            // Does not move bullets
	beq detectObjectLeft
	cmp r8, #'e'                            // Does not move bullets
	beq detectObjectLeft
	
	cmp r8, #''                             // If the is space
	beq detectObjectLeft

moveLeft:
	
	mov r0, r4                              // X value
	mov r1, r5                              // Y value
	bl calcArrOffset 
	mov r6, r0                              // r6 = offset
	mov r7, r0                              // r7 = offset
	sub r7, #4                              // r7 = r7 - 4
	
	str r8, [r3, r7]                        // Store offset r7 in gameboard
	mov r8, #'R'
	str r8, [r3, r6]                        // Store R in r6 offset

	b detectObjectLeft

objectsAtLeftBorder:

	mov r0, #'r'                            // r0 = 'r'
	b endMoveAiRowLeft

objectsNotAtLeftBorder:

	mov r0, #'l'                            // r0 = 'l'

endMoveAiRowLeft:

	pop {r3-r8, lr}
	bx lr

/* 
	Takes in a row and moves every object in that row right
	r0 - row
*/

	.global moveAiRowRight
moveAiRowRight:

	push {r3-r8, lr}

	ldr r3, =gameboard                      // Load gameboard
	mov r5, r0								// y value
	mov r4, #30					            //Start of search for object

	mov r0, r4                              // X Value
	mov r1, r5                              // Y value
	bl calcArrOffset

	ldr r8, [r3, r0]                        // load gameboard with offset

	cmp r8, #'f'				            //Ignores bullets at border
	beq detectObjectRight
	cmp r8, #'e'                            // Ignores bullets at border
	beq detectObjectRight

	cmp r8, #''                             // If there is a space
	bne objectsAtRightBorder

detectObjectRight:
	sub r4, #1                              // Decrement x value
	mov r0, r4                              // X value
	mov r1, r5                              // Y value
	bl calcArrOffset

	ldr r8, [r3, r0]                        // Load gameboard with offset
	cmp r8, #'b'                            // checks for border
	beq objectsNotAtRightBorder

	cmp r8, #'f'				            // Does not move bullets
	beq detectObjectRight
	cmp r8, #'e'                            // Does not move bullets 
	beq detectObjectRight
	
	cmp r8, #''                             // Space check
	beq detectObjectRight

moveRight:

	mov r0, r4                              // X value
	mov r1, r5                              // Y Value
	bl calcArrOffset
	mov r6, r0                              // r6 = offset
	mov r7, r0                              // r7 = offset
	add r7, #4                              // r7 = r7 + 4
	
	str r8, [r3, r7]                        // Store update gameboard
	mov r8, #'R'
	str r8, [r3, r6]                        // store R in old space
 
	b detectObjectRight

objectsAtRightBorder:

	mov r0, #'l'                            // r0 = 'l'
	b endMoveAiRowRight

objectsNotAtRightBorder:

	mov r0, #'r'                            // r0 = 'r'

endMoveAiRowRight:

	pop {r3-r8, lr}
	bx lr

/* 
	Moves a projectile when given its x and y coords
 	r0 - projectile x
 	r1 - projectile y
*/

	.global moveProjectile
moveProjectile:
	push {r4-r8, lr}

	mov r4, r0                              //x value
	mov r5, r1                              //updated y value

	bl calcArrOffset
	mov r6, r0                              //Current location offset
	
	mov r0, r4                              // X value
	sub r5, #1                              // Decrement Y value by 1
	mov r1, r5                              // Y value
	bl calcArrOffset
	mov r7, r0                              //New location offset

	ldr r4, =gameboard                      // Load gameboard
	ldr r5, [r4, r7]                        // Load gameboard with offset

	cmp r5, #''                             // Checks if empty
	bne projectileHitObject

	mov r5, #'f'                            
	str r5, [r4, r7]                        // Stores user fire in gameboard
	mov r5, #'R'
	str r5, [r4, r6]                        // Stores R in old location
	
	b endMoveProjectile

projectileHitObject:

	cmp r5, #'b'                            // Checks if border
	beq projectileHitBorder

	cmp r5, #'e'                            // Checks if Enemy bullet
	beq projectileHitBorder

	cmp r5, #'f'                            // Checks if friendly bullet
	beq projectileHitBorder

	cmp r5, #'R'                            // checks if R
	beq projectileHitBorder

	mov r0, r7                              
	bl checkCollision

projectileHitBorder:

	mov r5, #'R'                            
	str r5, [r4, r6]                        // Store R in Gameboard

endMoveProjectile:	
	pop {r4-r8, lr}
	bx lr

/* 
	Moves a projectile when given its x and y coords
 	r0 - projectile x
 	r1 - projectile y
*/

	.global moveEnemyProjectile
moveEnemyProjectile:
	push {r4-r8, lr}

	mov r4, r0                              // x value
	mov r5, r1                              // updated y value

	bl calcArrOffset
	mov r6, r0                              // Current location offset
	
	mov r0, r4
	add r5, #1
	mov r1, r5
	bl calcArrOffset
	mov r7, r0                              // New location offset

	ldr r4, =gameboard                      // Loads Gameboard
	ldr r5, [r4, r7]

	cmp r5, #''                             // checks if there is a space
	bne enemyProjectileHitObject

	mov r5, #'e'                            // checks if enemy bullet
	str r5, [r4, r7]
	mov r5, #'R'                            // checks if empty space
	str r5, [r4, r6]
	
	b endMoveEnemyProjectile

enemyProjectileHitObject:
 
	mov r0, r7
	bl checkEnemyCollision

	mov r5, #'R'                           
	str r5, [r4, r6]                        // Stores R at gameboard

endMoveEnemyProjectile:	

	pop {r4-r8, lr}
	bx lr

/* 
	This function updates the score
*/

	.global updateScore
updateScore:

	push {r4-r8, lr}

	mov r4, r0		                        // Number to modify score by
	ldr r5, =score         					// Loads score
	ldr r6, [r5]
	
	ldr r0, =0x0000							// Black
	mov r1, r5								// Score
	bl displayScore

	add r6, r4								// Adds modify score amount
	str r6, [r5]							// Stores updated score

	ldr r0, =0xFFFF 						// White
	mov r1, r5								// Score
	bl displayScore

	pop {r4-r8, lr}
	bx lr
/*
	This checks if there is any collisions with anything
*/

	.global checkCollision
checkCollision:

	push {r2-r8, lr}

	ldr r2, =gameboard						// loads gameboard
	mov r3, r0                              // Offset of the item collided with
	ldr r4, [r2, r3]                        // Value of the item collided with

	mov r5, #'R'			                // Pawn collision detection
	cmp r4, #'1'							// checks if its Pawn
	streq r5, [r2, r3]						// Stores if equal
	moveq r0, #5							// Moves if equal
	bleq updateScore						// Update score
	bleq subtractEnemyCounter  				// Subtracts enemy

	mov r5, #'R'			                // Knight collision detection
	cmp r4, #'2'							// Checks if Knight
	streq r5, [r2, r3] 						// Update gameboard if equal
	moveq r0, #10							// Arg = 10
	bleq updateScore						// Update Score
	bleq subtractEnemyCounter				// Subtracts enemy

	mov r5, #'2'							// Knigh that is clean
	cmp r4, #'3'
	streq r5, [r2, r3]						// Update gameboard

	mov r5, #'R'			                // Queen Collision detection
	cmp r4, #'4'							// Check for queen
	streq r5, [r2, r3]						// Update board
	moveq r0, #90							// Arg = 90
	bleq updateScore						// Updates score
	bleq subtractEnemyCounter				// Subtract Enemy

	mov r5, #'4'							// Queen That is one hit
	cmp r4, #'5'
	streq r5, [r2, r3]

	mov r5, #'5'							// Queen that is clean
	cmp r4, #'6'
	streq r5, [r2, r3]

	mov r5, #'8'			                // Cover collision detection
	cmp r4, #'9'							// Cover is fine
	streq r5, [r2, r3]

	mov r5, #'7'							// Cover is hit once
	cmp r4, #'8'
	streq r5, [r2, r3]

	mov r5, #'R'							// Cover is hit twince
	cmp r4, #'7'
	streq r5, [r2, r3]

	mov r5, #'R'
	cmp r4, #'f'							// hits air
	streq r5, [r2, r3]

	cmp r4, #'u'			                // User Collision detection
	moveq r0, #-10
	bleq updateScore

	pop {r2-r8, lr}
	bx lr

/*
	This is the enemy collision checker. It checks if it hit
	anything with the bullet
*/

	.global checkEnemyCollision
checkEnemyCollision:

	push {r4-r8, lr}

	ldr r2, =gameboard
	mov r8, r0                              // Offset of the item collided with
	ldr r4, [r2, r8]                        // Value of the item collided with

	mov r5, #'8'			                //Cover collision detection
	cmp r4, #'9'							// Cover is fine
	streq r5, [r2, r8]

	mov r5, #'7'							// Cover is hit once
	cmp r4, #'8'
	streq r5, [r2, r8]

	mov r5, #'R'							// Cover is hit twice
	cmp r4, #'7'
	streq r5, [r2, r8]

	mov r5, #'R'							// Hit air
	cmp r4, #'e'
	streq r5, [r2, r8]

	cmp r4, #'u'			                // User Collision detection
	moveq r0, #-10							// Update score because hit
	bleq updateScore

	pop {r4-r8, lr}
	bx lr

/*
	This function modifies the enemy counter when an enemy is killed
*/

	.global subtractEnemyCounter
subtractEnemyCounter:
	push {r4-r8, lr}

	ldr r4, =enemiesOnBoard					// Enemies on board address
	ldr r5, [r4]
	sub r5, #1								// Decrement by one
	str r5, [r4]

	pop {r4-r8, lr}
	bx lr

/*
	This updates the shots in the playing field
*/

	.global updateBalistics
updateBalistics:
	push {r3-r8, lr}
	
	ldr r3, =gameboard						// Load gameboard
	mov r4, #0								// Initial value
	mov r5, #0								// Initial Value
	mov r6, #32                             // horizontal limit
	mov r7, #24                             // Vertical limit

balisticsHorizLoop:
	cmp r4, r6								//if intial value is equal to limit
	bge endBalisticsHorizLoop

	mov r0, r4								// X value
	mov r1, r5								// Y value
	bl calcArrOffset
	ldr r8, [r3, r0]						// Load gameboard with offset
		
	cmp r8, #'f'							// Check if friendly projectile
	beq friendlyProjectileFound

finishedMoveProjectile:
	
	add r4, #1								// Add one to x value
	b balisticsHorizLoop	

endBalisticsHorizLoop:
	
	cmp r5, r7								// y value is equal tp limit
	bge endUpdateBalistics

	mov r4, #0								// reset x value
	add r5, #1								// add 1 to Y value

	b balisticsHorizLoop

friendlyProjectileFound:
	
	mov r0, r4								// X value
	mov r1, r5								// Y value
	bleq moveProjectile

	b finishedMoveProjectile

endUpdateBalistics:	

	pop {r3-r8, lr}
	bx lr

/*
	This updates the Enemy shots on the playing feild
*/

	.global updateEnemyBalistics
updateEnemyBalistics:
	push {r3-r8, lr}
	
	ldr r3, =gameboard						// Loads gameboard
	mov r4, #31								// Starting X
	mov r5, #23								// Starting Y
	mov r6, #0                              // horizontal limit
	mov r7, #0                              // Vertical limit

enemyBalisticsHorizLoop:

	cmp r4, r6								// If x value is equal to limit
	blt endEnemyBalisticsHorizLoop

	mov r0, r4								// X value
	mov r1, r5								// Y value
	bl calcArrOffset
	ldr r8, [r3, r0]						// Loads gameboard with offset

	cmp r8, #'e'							// Checks if enemny bullet
	beq enemyProjectileFound

finishedMoveEnemyProjectile:
	
	sub r4, #1								// Decrement by 1
	b enemyBalisticsHorizLoop

endEnemyBalisticsHorizLoop:
	
	cmp r5, r7								// Y values is equal to limit
	blt endUpdateEnemyBalistics

	mov r4, #31								// Reset X value
	sub r5, #1								// Decrement Y value

	b enemyBalisticsHorizLoop

enemyProjectileFound:
	
	mov r0, r4								// X value
	mov r1, r5								// Y value
	bleq moveEnemyProjectile

	b finishedMoveEnemyProjectile

endUpdateEnemyBalistics:
		
	pop {r3-r8, lr}
	bx lr
/*
	This function resets the game. That includes the gameboard and the score
*/

	.global resetGame
resetGame:

	push {r1-r8, lr}

	ldr r3, =gameboard						// Loads gameboard
	ldr r4, =gameboardReset					// Loads a reseted game board
	mov r5, #0
	
resetBoard:
	ldr r6, [r4, r5]						// load game reset board
	cmp r6, #'\n'							// Compares to end of line
	beq endResetBoard
	
	str r6, [r3, r5]						// store value in gameboard
	add r5, #4								// Increment r5 by 4
	b resetBoard	

endResetBoard:

	ldr r3, =score                        	// Load score
	mov r4, #100							
	str r4, [r3]							// Store default value of score

	ldr r3, =gamestate						// Load game state
	mov r4, #'r'
	str r4, [r3]							// Store gamestate

	ldr r3, =userLoc						// Load user location
	mov r4, #16						
	mov r5, #21
	str r4, [r3]							// Store X location
	str r5, [r3,#4]							// Store Y location
		
	ldr r3, =enemiesOnBoard					// Load enemy counter
	mov r4, #18
	str r4, [r3]							// Store default enemy counter
	
	pop {r1-r8, lr}
	bx lr


.section .data
.align 4
gamestate: .word 'r' //r- running, w-won, l-lost, p-paused
pausestate: .word 'u' //u - unpause, r - restart, q - quit
score: .word 100, '\n'
userLoc: .word 16, 21
enemiesOnBoard: .word 18
enemyFireCounter: .word 0

pawnMoveDir: .word 'r'		//r - right, l - left for which direction to move the enemies
knightMoveDir: .word 'l'
queenMoveDir: .word 'r'

gameboard: .word 'b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','6','','','','','','','','','','','','','','','6','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','3','','','','3','','','','','3','','','','3','','','','','3','','','','3','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','1','','','1','','','1','','','1','','','1','','','1','','','1','','','1','','','1','','','1','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','9','','','','','','9','','','','','','','','9','','','','','9','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','u','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','\n'
gameboardReset: .word 'b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','6','','','','','','','','','','','','','','','6','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','3','','','','3','','','','','3','','','','3','','','','','3','','','','3','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','1','','','1','','','1','','','1','','','1','','','1','','','1','','','1','','','1','','','1','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','9','','','','','','9','','','','','','','','9','','','','','9','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','u','','','','','','','','','','','','','','','b', 'b','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','b', 'b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','b','\n'
