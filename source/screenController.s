/*
	Code by Kyle Sutherland and Brian Brzezina
	
	This file deals with all the drawing on the screen. 
	That includes the main menu, enemies, user, obstacles 
	and every game screen.

*/
	.section .text
/* Draw Pixel
    r0 - x
    r1 - y
 	r2 - color
    
    Reference to Tutorial/Lecture code
 */
 
.global DrawPixel
DrawPixel:
    
    px      .req    r0                  // x pixel
    py      .req    r1                  // y pixel
	color	.req	r2                  // color
    addr    .req    r3                  // addr

	push	{r4}
    
    ldr     addr,   =FrameBufferInfo    // Address FrameBufferInfo
    
    height  .req    r4                  // height = r4
    ldr     height, [addr, #4]          
    sub     height, #1
    cmp     py,     height
    movhi   pc,     lr
    .unreq  height
    
    width   .req    r4
    ldr     width,  [addr, #0]
    sub     width,  #1
    cmp     px,     width
    movhi   pc,     lr
    
    ldr     addr,   =FrameBufferPointer
	ldr		addr,	[addr]
	
    add     width,  #1
    
    mla     px,     py, width, px       // px = (py * width) + px
    .unreq  width
    .unreq  py
    
    add     addr,   px, lsl #1			// addr += (px * 2) (ie: 16bpp = 2 bytes per pixel)
    .unreq  px
    
    strh    color,  [addr]
    
    .unreq  addr
    
	pop		{r4}

    bx		lr


/* Draw the characters
   r0 - Letter
   r1 - x
   r2 - y
   r3 - color
 
 Reference from Lecture/Tutorial code
 
 */
 
	.global DrawChar
DrawChar:
	push	{r4-r8, lr}

	chAdr	.req	r4
	px		.req	r5
	py		.req	r6
	row		.req	r7
	mask	.req	r8
	
	mov r9, r1
	mov py, r2
	mov r10, r3

	ldr		chAdr,	=font		        // load the address of the font map
	add		chAdr,	r0, lsl #4	        // char address = font base + (char * 16)

charLoop$:
	mov px, r9			                // init the X coordinate

	mov		mask,	#0x01		        // set the bitmask to 1 in the LSB
	
	ldrb	row,	[chAdr], #1	        // load the row byte, post increment chAdr

rowLoop$:
	tst		row,	mask		        // test row byte against the bitmask
	beq		noPixel$

	mov		r0,		px
	mov		r1,		py
	mov		r2,		r10		            // red
	bl		DrawPixel			        // draw red pixel at (px, py)

noPixel$:
	add		px,		#1			        // increment x coordinate by 1
	lsl		mask,	#1			        // shift bitmask left by 1

	tst		mask,	#0x100		        // test if the bitmask has shifted 8 times (test 9th bit)
	beq		rowLoop$

	add		py,		#1			        // increment y coordinate by 1

	tst		chAdr,	#0xF
	bne		charLoop$			        // loop back to charLoop$, unless address evenly divisibly by 16 (ie: at the next char)

	.unreq	chAdr
	.unreq	px
	.unreq	py
	.unreq	row
	.unreq	mask

	pop		{r4-r8, pc}
	bx lr


/* Draw String will draw out an array of characters
   r0 - address of array
   r1 - x coord
   r2 - y coord
   r3 - color
*/

	.global drawString
	
drawString: 
	push {r4-r8,lr}

	mov r4, r0                          
	mov r5, #0                          
	mov r6, r1                         
	mov r7, r2
	mov r8, r3

drawStringLoop:
	ldrb r0, [r4, r5]

	cmp r0, #'\n'                       // Compares to end of string
	beq endDrawString                   

	mov r1, r6                          // x cordinate
	mov r2, r7                          // y cordinate
	mov r3, r8                          // color
	bl DrawChar
	
	add r6, #8                          // r6 = r6 + 8
	add r5, #1                          // r5 = r5 + 1

	b drawStringLoop

endDrawString:

	pop {r4-r8, lr}
	bx lr

/*
	This function creates the gamestate of the initial
	Screen.
	
	X Cordinate = r0
	Y Cordinate = r1
	Color = r2
*/

	.global displayInitScreen
	
displayInitScreen:	
	push {lr}
	
	bl clearScreen
	
	mov r0, #0                          // Initial x Cordinate
	mov r1, #0                          // Initial y Cordinate
	ldr r2, =0xFFFF                     // White Color
	bl DrawPixel

	mov r4, #1                          // Counter for Vertical
	mov r5, #1024                       // Limit for Horizontal
	sub r5, r5, #1                      // r5 = r5 - 1
	
drawTopLoop:

	add r0, r0, #1                      // r0 = r0 + 1
	ldr r2, =0xFFFF                     // White Color
	bl DrawPixel

	add r4, r4, #1                      // r4 = r4 + 1
	cmp r4, r5                          // Checks if r4 > r5
	ble drawTopLoop

	mov r0, #0                          // Initial x Cordinate
	mov r1, #0                          // Initial y Cordinate
	mov r4, #1                          // Counter for y
	mov r5, #768                        // Limit for y
	sub r5, #1                          // r5 = r5 - 1
	
drawLeftLoop:

	mov r0, #0                          // Initial x Cordinate
	add r1, r1, #1                      // r1 = r1 + 1
	ldr r2, =0xFFFF                     // White
	bl DrawPixel

	add r4, r4, #1                      // r4 = r4 + 1
	cmp r4, r5                          // Checks if counter is less than limit
	ble drawLeftLoop

	mov r1, #0                          // Inital y
	mov r4, #1                          // Counter y
	mov r5, #768                        // Limit y
	sub r5, #1                          // r5 = r5 - 1
	
drawRightLoop:

	mov r0, #1024                       // Initial x cordinate
	sub r0, r0, #1                      // r0 = r0 - 1 
	add r1, r1, #1                      // r1 = r1 + 1
	ldr r2, =0xFFFF                     // White
	bl DrawPixel

	add r4, r4, #1                      // r4 = r4 +1
	cmp r4, r5                          // Checks if counter is less than limit
	ble drawRightLoop 

	mov r6, #0                          // r6 = 0
	mov r1, #768                        // Initial Y cordinate
	sub r1, r1, #1                      // r1 = r1 - 1
	
	mov r4, #1                          // Initial X Counter
	mov r5, #1024                       // X limit
	sub r5, #1                          // r5 = r5 - 1
	
drawBottomLoop:

	add r6, r6, #1                      // r6 = r6 + 1
	mov r0, r6                          // r0 = r6
	ldr r2, =0xFFFF                     // White
	bl	DrawPixel

	add r4, r4, #1                      // r4 = r4 + 1
	cmp r4, r5                          // Checks if counter is less than limit
	ble drawBottomLoop

messageStart:

	ldr r0, =gameName                   // Loads Game name Address
	mov r1, #400                        // Initial X cordinate
	mov r2, #100                        // Initial Y cordinate
	ldr r3, =0xF800                     // Red
	bl drawString

	ldr r0, =startMessage               // Loads Start Message Address
	mov r1, #432                        // Initial X cordinate
	mov r2, #300                        // Initial Y cordinate
	ldr r3, =0xFFFF                     // White
	bl drawString

	ldr r0, =names                      // Loads names address
	mov r1, #380                        // Initial X cordinate
	mov r2, #700                        // Initial Y cordinate
	ldr r3, =0xFFFF                     // White
	bl drawString

	pop {lr}
	bx lr

/* 
	Draws a queen at the specified location
 	 r0 - x
 	 r1 - y
 	
 	Referenced by TutorialSlide
*/

	.global drawQueen
drawQueen:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X Cordinate
	mov r5, r1	                        // Y Cordinate
	mov r6, #0 	                        // X counter
	mov r7, #0	                        // Y counter
	mov r8, #32                         // 32x32 box for queen

queenHoriLoop:

	cmp r6, r8                          // Checks of Counter is equal to size
	bge endDrawQueenHori

	mov r0, r4                          // x value
	mov r1, r5                          // y value
	ldr r2, =0x07FF                     // Cyan
	bl DrawPixel

	add r4, #1                          // adds to initial x 
	add r6, #1                          // Adds to x counter
	b queenHoriLoop

endDrawQueenHori:

	cmp r7, r8                          // Checks if Y counter is equal to size
	bge endDrawQueen
	
	sub r4, #32                         // Resets x value
	add r5, #1                          // Adds to initial y
	add r7, #1                          // Adds to y counter
	mov r6, #0                          // Resets x counter
	b queenHoriLoop

endDrawQueen:

	pop {r4-r8, lr}
	bx lr

/* 
	Draws a knight at the specified location
 	  r0 - x
 	  r1 - y
*/

	.global drawKnight
drawKnight:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X value
	mov r5, r1	                        // Y value
	mov r6, #0 	                        // X counter
	mov r7, #0	                        // Y counter
	mov r8, #32                         // 32x32 box for knight

knightHoriLoop:

	cmp r6, r8                          // Checks if x counter is equal to limit
	bge endDrawKnightHori

	mov r0, r4                          // x value
	mov r1, r5                          // y value
	ldr r2, =0x001F                     // Shade of Blue
	bl DrawPixel

	add r4, #1                          // Adds to initial x 
	add r6, #1                          // Adds to x counter
	b knightHoriLoop

endDrawKnightHori:

	cmp r7, r8                          // Checks if y counter is equal to limit
	bge endDrawKnight
	
	sub r4, #32                         // Resets x initial value
	add r5, #1                          // Adds to Y initial value
	add r7, #1                          // Adds to Y counter
	mov r6, #0                          // Resets x counter
	b knightHoriLoop 

endDrawKnight:
	pop {r4-r8, lr}
	bx lr

/* 
	Draws a pawn at the specified location
 	  r0 - x
 	  r1 - y
*/

	.global drawPawn
drawPawn:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X value
	mov r5, r1	                        // Y Value
	mov r6, #0 	                        // X counter
	mov r7, #0	                        // Y counter
	mov r8, #32                         // 32x32 box for Pawn

pawnHoriLoop:

	cmp r6, r8                          // Checks if x counter is equal to limit
	bge endDrawPawnHori

	mov r0, r4                          // X value
	mov r1, r5                          // Y value
	ldr r2, =0x00CB                     // Shade of Blue
	bl DrawPixel

	add r4, #1                          // Adds to Initial x value
	add r6, #1                          // Adds to x counter
	b pawnHoriLoop

endDrawPawnHori:

	cmp r7, r8                          // Checks if y counter is equal to limit
	bge endDrawPawn
	
	sub r4, #32                         // Resets x initial value
	add r5, #1                          // Adds to Y initial value
	add r7, #1                          // Adds to Y counter
	mov r6, #0                          // Resets x counter
	b pawnHoriLoop

endDrawPawn:
	pop {r4-r8, lr}
	bx lr

/* 
	Draws a cover box at the specified location
 	  r0 - x
 	  r1 - y
*/

	.global drawCover
drawCover:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X value
	mov r5, r1	                        // Y value
	mov r6, #0 	                        // X counter
	mov r7, #0	                        // Y counter
	mov r8, #32                         // 32x32 box for cover

coverHoriLoop:

	cmp r6, r8                          // Checks if X counter is equal to limit
	bge endDrawCoverHori

	mov r0, r4                          // X value
	mov r1, r5                          // Y value
	ldr r2, =0xFF12                     // Baige
	bl DrawPixel

	add r4, #1                          // Adds to initial x
	add r6, #1                          // Adds to X counter
	b coverHoriLoop

endDrawCoverHori:

	cmp r7, r8                          // Checks if Y counter is equal to Limit
	bge endCover
	
	sub r4, #32                         // Resets Initial X
	add r5, #1                          // Add to Y Initial
	add r7, #1                          // Add to Y counter
	mov r6, #0                          // Resets X counter
	b coverHoriLoop

endCover:
	pop {r4-r8, lr}
	bx lr

/* 
	Draws a cover box 2 at the specified location
 	  r0 - x
 	  r1 - y
*/

	.global drawCover2
drawCover2:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X value
	mov r5, r1	                        // Y value
	mov r6, #0 	                        // X counter
	mov r7, #10	                        // Y counter
	mov r8, #32                         // 32x32 box for cover

cover2HoriLoop:

	cmp r6, r8                          // Checks if X counter is equal to limit
	bge endDrawCover2Hori

	mov r0, r4                          // X value
	mov r1, r5                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel

	add r4, #1                          // Adds to initial x
	add r6, #1                          // Adds to X counter
	b cover2HoriLoop

endDrawCover2Hori:

	cmp r7, r8                          // Checks if Y counter is equal to Limit
	bge end2Cover
	
	sub r4, #32                         // Resets Initial X
	add r5, #1                          // Add to Y Initial
	add r7, #1                          // Add to Y counter
	mov r6, #0                          // Resets X counter
	b cover2HoriLoop

end2Cover:
	pop {r4-r8, lr}
	bx lr


/* 
	Draws a cover box 3 at the specified location
 	  r0 - x
 	  r1 - y
*/

	.global drawCover3
drawCover3:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X value
	mov r5, r1	                        // Y value
	mov r6, #0 	                        // X counter
	mov r7, #20	                        // Y counter
	mov r8, #32                         // 32x32 box for cover

cover3HoriLoop:

	cmp r6, r8                          // Checks if X counter is equal to limit
	bge endDrawCover3Hori

	mov r0, r4                          // X value
	mov r1, r5                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel

	add r4, #1                          // Adds to initial x
	add r6, #1                          // Adds to X counter
	b cover3HoriLoop

endDrawCover3Hori:

	cmp r7, r8                          // Checks if Y counter is equal to Limit
	bge endCover3
	
	sub r4, #32                         // Resets Initial X
	add r5, #1                          // Add to Y Initial
	add r7, #1                          // Add to Y counter
	mov r6, #0                          // Resets X counter
	b cover3HoriLoop

endCover3:
	pop {r4-r8, lr}
	bx lr


/* 
	Draws a user at the specified location
 	  r0 - x
 	  r1 - y
*/

		.global drawUser
drawUser:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X value
	mov r5, r1	                        // Y value
	mov r6, #0 	                        // X counter
	mov r7, #0	                        // Y counter
	mov r8, #32                         // 32x32 box for User

drawUserHoriLoop:

	cmp r6, r8                          // Checks if X counter is equal to limit
	bge endDrawUserHori

	mov r0, r4                          // X value
	mov r1, r5                          // Y value
	ldr r2, =0x0AE0                     // Green
	bl DrawPixel

	add r4, #1                          // Adds to initial x
	add r6, #1                          // Adds to X counter
	b drawUserHoriLoop

endDrawUserHori:

	cmp r7, r8                          // Checks if Y counter is equal to Limit
	bge endDrawUser
	
	sub r4, #32                         // Resets Initial X
	add r5, #1                          // Add to Y Initial
	add r7, #1                          // Add to Y counter
	mov r6, #0                          // Resets X counter
	b drawUserHoriLoop

endDrawUser:

	pop {r4-r8, lr}
	bx lr
	
/*
	Erases a placement on the board by a 32 by 32 square
	  r0 - x
	  r1 - y 
*/

	.global eraseSquare
eraseSquare:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // x Value
	mov r5, r1	                        // Y Value
	mov r6, #0                          // X Counter
	mov r7, #0	                        // Y counter
	mov r8, #32                         // 32x32 box for Square

eraseHoriLoop:

	cmp r6, r8                          // Checks if X counter is equal to limit
	bge endEraseHori

	mov r0, r4                          // X value
	mov r1, r5                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel

	add r4, #1                          // Increments x value by 1
	add r6, #1                          // Increments x counter by 1
	b eraseHoriLoop

endEraseHori:

	cmp r7, r8                          // Checks if Y counter is equal to limit
	bge endEraseSquare
	
	sub r4, #32                         // Resets X Initial value
	add r5, #1                          // Increments y value by 1
	add r7, #1                          // Increments y counter by 1
	mov r6, #0                          // Resets x counter
	b eraseHoriLoop

endEraseSquare:

	pop {r4-r8, lr}
	bx lr

/* 
	Draws a projectile on the screen
 	  r0 - x
 	  r1 - y
 */
 
	.global drawProjectile
drawProjectile:

	push {r4-r8, lr}
	
	lsl r0, #5
	lsl r1, #5
	mov r4, r0	                        // X Value
	add r4, #15                         // adds 15 to the initial x value 
	mov r5, r1	                        // Y Value
	add r5, #8                          // adds 8 to the initial y value
	mov r7, #0	                        // Y counter
	mov r8, #16                         // Y limit

projectileVertLoop:

	cmp r7, r8                          // Checks if Y counter is equal to Y limit
	bge endDrawProjectile

	mov r0, r4                          // X Value 
	mov r1, r5                          // Y Value
	ldr r2, =0xDDDD                     // Grey
	bl DrawPixel

	add r5, #1                          // Increments Y by 1
	add r7, #1                          // Increments Y counter by 1
	b projectileVertLoop

endDrawProjectile:
	pop {r4-r8, lr}
	bx lr


/* 
	Displaying the gameboard array
 	  inputs:
 	  r0 - gameBoard address (32x24 game board)
*/

	.global displayGameBoard
displayGameBoard:

	push {r1-r8, lr}

	mov r4, r0                          // r4 = GameBoard address
	mov r5, #0                          // Initial x array location
	mov r6, #32                         // Limit X array location
	mov r7, #0                          // Initial Y array Location
	mov r8, #24                         // Limit Y array Location

arrayLoop:

	cmp r7, r8                          // Checks if Y array is equal to Limit
	bge endArrayLoop

	ldr r0, [r4], #4                    // Loads Gameboard array

	cmp r0, #'\n'                       // Checks if entry is equal to end of line
	beq endArrayLoop

	cmp r0, #'9'                        // Checks if entry is equal to full cover
	beq coverSpotted
	cmp r0, #'8'                        // Checks if entry is equal to partially hit cover
	beq cover3Spotted
	cmp r0, #'7'                        // Checks if entry is equal to very hit cover
	beq cover2Spotted

	cmp r0, #'6'                        // Checks if queen is detected
	beq queenSpotted
	cmp r0, #'5'                        // Checks if damaged Queen is detected
	beq queenSpotted
	cmp r0, #'4'                        // Checks if Very damaged Queen is detected
	beq queenSpotted

	cmp r0, #'3'                        // Checks if knight is spotted
	beq knightSpotted
	cmp r0, #'2'                        // Checks if damaged Knight is spotted
	beq knightSpotted

	cmp r0, #'1'                        // Checks if Pawn is detected
	beq pawnSpotted 

	cmp r0, #'u'                        // Checks if user is detected
	beq userSpotted

	cmp r0, #'f'                        // Checks for friendly projectile
	beq projectileSpotted
	cmp r0, #'e'                        // Checks for enemy projectile
	beq projectileSpotted

	cmp r0, #'R'                        // Checks for empty spot
	beq eraseSpotted
	

drawFinished:

	add r5, #1                          // Increments X array value

	cmp r5, r6                          // checks is x array is less than limit
	blt arrayLoop
	
	mov r5, #0                          // Resets x array value
	add r7, #1                          // Increments Y array value

	b arrayLoop

eraseSpotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl eraseSquare

	mov r0, #''                         // Gets empty space value
	str r0, [r4,#-4]                    // Stores new value

	b drawFinished

projectileSpotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl drawProjectile                   

	b drawFinished

queenSpotted:

	mov r0, r5                          // X Value
	mov r1, r7                          // Y Value
	bl drawQueen

	b drawFinished

knightSpotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl drawKnight

	b drawFinished

pawnSpotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl drawPawn

	b drawFinished

coverSpotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl drawCover

	b drawFinished

cover2Spotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl drawCover2

	b drawFinished

cover3Spotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	bl drawCover3

	b drawFinished

userSpotted:

	mov r0, r5                          // X value
	mov r1, r7                          // Y value
	
breakpoint:
	bl drawUser

	b drawFinished

endArrayLoop:

	pop {r1-r8, lr}
	bx lr

/*
	This function draws the Pause Menu
*/

	.global displayPauseMenu
displayPauseMenu:
	push {lr}

	bl drawPauseBox

	pop {lr}
	bx lr

/*

	This function draws the pause menu Box
*/	
	
	.global drawPauseBox
drawPauseBox:
	
	push {lr}
	
	mov r0, #412                        // Initial X value
	mov r1, #200                        // Initial Y value
	mov r3, #612                        // X value Limit
	mov r4, #500                        // Y value Limit
	mov r5, #412                        // X counter
	mov r6, #200                        // Y counter

drawPauseBoxLine:
	
	mov r0, r5                          // X Value
	mov r1, r6                          // Y Value
	ldr r2, =0x7FF                      // Some Color name
	bl DrawPixel
	
	add r5, #1                          // Increment X counter by 1
		
	cmp r5, #612                        // Checks if equal to limit
	bne drawPauseBoxLine
	
drawPauseBoxNextLine:

	mov r5, #412                        // Resets X Counter
	add r6, #1                          // Increments Y counter by 1
	cmp r6, #500                        // Checks id Y counter is not equal to Limit
	bne drawPauseBoxLine

drawPauseBoxAddText:

	ldr r0, =menuResume                 // Loads Resume Text
	mov r1, #488                        // X value
	mov r2, #244                        // Y value
	ldr r3, =0x0000                     // Black
	bl drawString
	
	ldr r0, =menuRestart                // Loads Restart Text
	mov r1, #484                        // X Value
	mov r2, #340                        // Y value
	ldr r3, =0x0000                     // Black
	bl drawString

	ldr r0, =menuQuit                   // Loads Quit Text
	mov r1, #492                        // X value
	mov r2, #448                        // Y value
	ldr r3, =0x0000                     // Black
	bl drawString

	pop {lr}
	bx lr

/*
	This function draws a Top and Bottom border for the Menu
	screen for Resume.
*/

	.global borderSelectResume
borderSelectResume:
	
	push {lr}                           
	
	mov r0, #436                        // Initial X Value
	mov r1, #224                        // Initial Y Value
	mov r3, #588                        // Limit X Value
	mov r4, #280                        // Limit Y value
	mov r5, #436                        // X counter            
	mov r6, #224                        // Y counter

drawBorderTopSelect:
	mov r0, r5                          // X Value
	mov r1, r6                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel
	
	add r5, #1                          // Increment x counter by 1
		
	cmp r5, #588                        // Checks if x counter is equal to limit
	bne drawBorderTopSelect
	
	mov r5, #436                        // Resets X counter

drawBorderBottomSelect:

	mov r0, r5                          // X value
	mov r1, r4                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel

	add r5, #1                          // Increment X counter

	cmp r5,#588                         // Checks if x counter is equal to limit
	bne drawBorderBottomSelect
	
	pop {lr}
	bx lr	

/*

	This function makes a top and bottom border for restart
	in the menu screen

*/

	.global borderSelectRestart
borderSelectRestart:
	
	push {lr}
	
	mov r0, #436                        // Initial X Value
	mov r1, #324                        // Initial Y Value
	mov r3, #588                        // X value Limit
	mov r4, #380                        // Y value Limit
	mov r5, #436                        // X counter
	mov r6, #324                        // Y counter

drawBorderRestartTopSelect:

	mov r0, r5                          // X value
	mov r1, r6                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel
	
	add r5, #1                          // Increments x counter by 1
		
	cmp r5, #588                        // Checks if x counter is equal to limit
	bne drawBorderRestartTopSelect
	
	mov r5, #436                        // Resets x counter

drawBorderRestartBottomSelect:

	mov r0, r5                          // x value
	mov r1, r4                          // y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel

	add r5, #1                          // Increments x counter by 1

	cmp r5,#588                         // Checks if x counter is equal to limit
	bne drawBorderRestartBottomSelect
	
	pop {lr}
	bx lr	

/*

	This function draws a top and bottom border for the 
	Quit option in the menu.

*/

	.global borderSelectQuit
borderSelectQuit:

	push {lr}

	mov r0, #436                        // Initial X value
	mov r1, #424                        // Initial Y Value
	mov r3, #588                        // X limit
	mov r4, #480                        // Y limit
	mov r5, #436                        // X counter
	mov r6, #424                        // Y counter

drawBorderQuitTopSelect:

	mov r0, r5                          // Xvalue
	mov r1, r6                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel
	
	add r5, #1                          // Increments x counter by 1
		
	cmp r5, #588                        // Checks if x counter is equal to limit
	bne drawBorderQuitTopSelect
	
	mov r5, #436                        // Resets x counter

drawBorderQuitBottomSelect:

	mov r0, r5                          // X value
	mov r1, r4                          // Y value
	ldr r2, =0x0000                     // Black
	bl DrawPixel

	add r5, #1                          // Increment x counter by 1

	cmp r5,#588                         // Checks if x counter is equal to limit
	bne drawBorderQuitBottomSelect
	
	pop {lr}
	bx lr

/*
	This function displays the win screen
*/

	.global displayWinScreen
displayWinScreen:

	push {lr}

	bl clearScreen                      // Clears screen

	ldr r0, =winMessage                 // Loads win message
	mov r1, #480                        // X value
	mov r2, #300                        // Y value
	ldr r3, =0xFFFF                     // White
	bl drawString

	ldr r0, =playAgainMessage           // Loads play again message
	mov r1, #360                        // X value
	mov r2, #600                        // Y value
	ldr r3, =0xFFFF                     // White
	bl drawString

	pop {lr}
	bx lr

/*
	This function displays the loser screen.
*/

	.global displayLoseScreen
displayLoseScreen:

	push {lr}
	
	bl clearScreen                      // Clears screen

	ldr r0, =loseMessage                // Loads losers message
	mov r1, #480                        // X value
	mov r2, #300                        // Y value
	ldr r3, =0xFFFF                     // White
	bl drawString

	ldr r0, =playAgainMessage           // Loads Play again message
	mov r1, #360                        // X value
	mov r2, #600                        // Y value
	ldr r3, =0xFFFF                     // White
	bl drawString
	
	pop {lr}
	bx lr

/*
	This function displays a score bar. It gets modified every time the score
	changes

    r4 - color of message
    r5 - score
    r6 - x start
    r7 - y start
    r8 - y limit
 */
 
	.global displayScore
displayScore:
	
	push {r4-r8, lr}

	mov r4, r0			                // Color of message
	mov r5, r1			                // address of current Score

	ldr r0, =scoreMessage               // Loads the score message
	mov r1, #20                         // X value 
	mov r2, #10                         // Y value
	mov r3, r4                          // Color
	bl drawString

	ldr r5, [r5]
	mov r6, #70			                // Start limit x
	add r5, r6			                // End limit x
	mov r7, #13			                // Start limit y
	mov r8, #22			                // end limit y

displayScoreHoriz:

	cmp r6, r5                          // Checks x limit if equal to score
	bge endDisplayScoreHoriz
	
	mov r0, r6                          // X value
	mov r1, r7                          // Y value
	mov r2, r4                          // color
	bl DrawPixel

	add r6, #1                          // increment x value
	b displayScoreHoriz

endDisplayScoreHoriz:

	cmp r7, r8                          // checks if y counter is equal to limit
	bge endDisplayScore

	add r7, #1                          // Increments y counter
	mov r6, #70                         // Resets x counter
	b displayScoreHoriz

endDisplayScore:

	pop {r4-r8, lr}
	bx lr

/*
	This function clears the screen and everything on it
*/

	.global clearScreen
clearScreen:

	push {lr}
	
	mov r4, #1024                       // Limit x value
	sub r4, r4, #2                      // Limit - 2
	mov r5, #768                        // Limit y value
	sub r5, r5, #2                      // Limit - 2
	mov r6, #1                          // Starting X value
	mov r7, #1                          // Starting Y value
	ldr r8, =0x0000                     // Black
 
horClear:

	cmp r6, r4                          // checks if x value is equal to Limit
	bge vertInc
	
	mov r0, r6                          // X value
	mov r1, r7                          // Y value
	mov r2, r8                          // Color
	bl DrawPixel
	
	add r6, #1                          // Increment x value by 1

	b horClear
	
vertInc:

	cmp r7, r5                          // checks if limit is hit
	bge endClearScreen

	add r7, #1                          // increments y counter
	mov r6, #1                          // resets x value
	
	b horClear

endClearScreen:

	pop {lr}	
	bx lr

/*
	This function clears the menu screen
*/

	.global clearMenuScreen
clearMenuScreen:
	
	push {lr}
	
	mov r4, #616                        // Limit x value
	sub r4, r4, #2                      // Limit - 2
	mov r5, #504                        // Limit Y value
	sub r5, r5, #2                      // Limit - 2
	mov r6, #396                        // Start x value
	mov r7, #196                        // Start Y value
	ldr r8, =0x0000                     // Black

horMenuClear:

	cmp r6, r4                          // Checks if limit is hit
	bge vertMenuInc
	
	mov r0, r6                          // X value
	mov r1, r7                          // Y value
	mov r2, r8                          // color
	bl DrawPixel
	add r6, #1                          // Increments x value

	b horMenuClear
	
vertMenuInc:

	cmp r7, r5                          // Checks y limit is hit
	bge endMenuClearScreen

	add r7, #1                          // Increments y value
	mov r6, #396                        // Resets x value
	
	b horMenuClear

endMenuClearScreen:
	pop {lr}	
	bx lr



.section .data
.align 4
font: .incbin "font.bin"
gameName: .byte 'A','t','t','a','c','k',' ','o','f',' ','t','h','e',' ','B','l','u','e',' ','M','a','n',' ','G','r','o','u','p','\n'
names: .byte 'K','y','l','e',' ','S','u','t','h','e','r','l','a','n','d',' ','&',' ','B','r','i','a','n',' ','B','r','z','e','z','i','n','a','\n'
startMessage: .byte 'P','r','e','s,'s',' ','s','t','a','r','t',' ','t','o',' ','b','e','g','i','n','\n'
winMessage: .byte 'Y','o','u',' ','W','o','n','!','\n'
loseMessage: .byte 'Y','o','u',' ','L','o','s','t','.','.','.','\n'
playAgainMessage: .byte 'P','r','e','s','s',' ','a','n','y',' ','b','u','t','t','o','n',' ','t','o',' ','g','o',' ','t','o',' ','t','h','e',' ','m','a','i','n',' ','m','e','n','u','\n'
scoreMessage: .byte 'S','c','o','r','e',':',' ','\n'
menuResume: .byte 'R','E','S','U','M','E','\n'
menuRestart: .byte 'R','E','S','T','A','R','T','\n'
menuQuit: .byte 'Q','U','I','T','\n'
