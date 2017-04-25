/* 
	Code by: Kyle Sutherland and Brian Brzezina
	Modified: March 20/2015

	This is our Main function our game
	"Attack of the Blue Man Group"

	Awesome Name minus the Music
	Enjoy!
	
*/

.section    .init
.globl     _start

_start:
    b       main
    
.section .text

main:
    mov sp, #0x8000
	
	bl EnableJTAG

	mov r0, #42                         //Sets r0 so HaltLoop$ doesnt run

	bl InitFrameBuffer                  //Initializes the framebuffer
	bl initializeController             //Initializes the Controller

	// branch to the halt loop if there was an error initializing the framebuffer
	cmp		r0, #0
	beq		haltLoop$

	bl startGame                        //Runs Game
    
haltLoop$:
	b		haltLoop$

.section .data


