/* Code by: Kyle Sutherland and Brian Brzezina
Modified: March 23/2015

This file Initializes the SNES Controller and Read from
the SNES

*/

.equ    GPIOFSEL0, 0x20200000
.equ    GPIOFSEL1, 0x20200004
.equ 	CLO, 0x20003004

	.section .text

/*
	In this function, we are initializing the LATCH pin, the Clock
	pin and the Data pin. 
*/
	
	.global initializeController
	
initializeController:
	
	push {r0-r8}

	/* Setting pin 9 [Latch] Line */
	
	ldr r0, =GPIOFSEL0              // address for GPIOFSEL0
	ldr r1, [r0]                    // Copy GPIOFSELO into r1
	
	mov r2, #7                      // Function call b0111
	lsl r2, #27                     // index of 1st bit for pin 9
	bic r1, r2                      // clear pin 9 bits
	mov r3, #1                      // output function code
	lsl r3, #27                     
	orr r1, r3                      // set pin9 function into r1
	
	str r1, [r0]                    // write back to GPI0FSEL0

	/* Setting pin 10 [Data] Line */
	
	ldr r0, =GPIOFSEL1              // address of GPI0FSEL1
	ldr r1, [r0]                    // Copy GPI0FSEL1
	mov r2, #7                      // Function call b011
	bic r1, r2                      // Clear pin
	str r1, [r0]                    // write back to GPIOFSEL1
	
	/* Setting pin 11 [Clock] Line
	Referenced from J. Kawash Lecture slides */
	
	ldr r0, =GPIOFSEL1              // address of GPIOFSEL1
	ldr r1, [r0]                    // Copy GPIOFSEL1 INTO r1
	
	mov r2, #7                      // Function call b0111
	lsl r2, #3                      // index of 1st bit of pin11
	bic r1, r2                      // clear pin11
	mov r3, #1                      // Output function code
	lsl r3, #3                      
	orr r1, r3                      // set pin11 function in r1
	str r1, [r0]                    // write back to GPIOSEL1
	
	pop {r0-r8}
	bx lr

/*
	This function reads the given SNES and sends 
	which button pattern has been used.
	References code by J. Kawash Lecture slide
	References code by Bayo Omole and Janine Villareal
*/

.global  readSNES
readSNES:

    push        {r4,r5,lr}

    buttons     .req r4             // local Variable of buttons in r4
    i           .req r5             // local Variable of i counter in r5

    mov         buttons, #0         // buttons = 0
    mov         r1, #0              // r1 = 0
    bl          writeGPIOCLK        // writeGPIO(CLOCK, #1)

    mov         r1, #1				// r1 = 1
    bl          writeGPIOLATCH      // writeGPIO(LATCH, #1)
    bl          wait12ms            // wait(12ms) - signal to SNES to sample buttons
    
    mov         r1, #0              // r1 = 0
    bl          writeGPIOLATCH      // writeGPIO(LATCH, #0)
    mov         i, #0               // i = 0

pulseLoop:

    bl          wait6ms             // wait(6ms)
    mov         r1, #0              // r1 = 0
    bl          writeGPIOCLK        // writeGPIO(CLOCK, #0)
    bl          wait6ms             // wait(6ms)
    bl          readGPIODATA        // readGPIO(DATA, b) - read bit i

    cmp         r0, #1              // r0 = 1
    bne         buttonPressed       // buttons[i] = b
    lsl         r0, i
    orr         buttons, r0         // Outputs buttons

buttonPressed:

    mov         r0, #3              // r0 = 3
    mov         r1, #1              // r1 = 1
    bl          writeGPIOCLK        // writeGPIO(CLOCK, #1) - New Cycle
    add         i, #1               // i++ - next button
    cmp         i, #16              // checks if i < 16
    blt         pulseLoop           
    
    mov         r0, buttons         // return button signal in r0
    
    pop         {r4,r5,lr}    
    bx          lr

writeGPIOCLK:

    ldr         r2, =GPIOFSEL0      // Base GPIO function select register
    mov         r3, #1              
    lsl         r3, #11             // align bit for pin11 (CLOCK)
    teq         r1, #0
    streq       r3, [r2, #40]       // GPIOCLR0
    strne       r3, [r2, #28]       // GPIOSET0
    bx          lr

writeGPIOLATCH:

    ldr         r2, =GPIOFSEL0      // Base GPIO function select register
    mov         r3, #1
    lsl         r3, #9              // align bit for pin9 (Latch)
    teq         r1, #0
    streq       r3, [r2, #40]       // GPIOCLR0
    strne       r3, [r2, #28]       // GPIOSET0
    bx          lr

readGPIODATA:

    ldr         r2, =GPIOFSEL0      // Base GPI0 function select register
    ldr         r1, [r2, #52]       // GPLEV0
    mov         r3, #1
    lsl         r3, #10             // align pin10 bit (DATA)
    and         r1, r3              // Mask everything else
    teq         r1,  #0
    moveq       r0, #0              // return 0
    movne       r0, #1              // return 1
    bx          lr

wait12ms:

    ldr         r0, =CLO            // Address of CLO
    ldr         r1, [r0]            // read CLO
    add         r1, #12             // add 12 micros

waitLoop:

    ldr         r2, [r0]            // read CLO
    cmp         r1, r2              // stop when CLO = r1
    bhi         waitLoop            
    
    bx          lr

wait6ms:

    ldr         r0, =CLO            // Address of CLO
    ldr         r1, [r0]            // read CLO
    add         r1, #6              // add 6 micros

waitLoop1:

    ldr         r2, [r0]            // read CLO
    cmp         r1, r2              // stop when CLO = r1
    bhi         waitLoop1
    
    bx          lr	


/*
	This interpretes the value the SNES controller returns to us
	and give it a integer value so it may be used to evaluate what 
	action must be done when pressed. The interger value will be the
	be default button number/clock cycle given to it already.
	
	References code by J. Kawash
	References code by Bayo Omole and Janine Villareal
*/
	.global interpreteSNES
interpreteSNES:

	push {r4, lr}
	
	
	/* This checks if the start button has been pressed */
	
	mov r1, r0                      // moves the button sequence into r1
	ldr r4, =0xfffffff7             // bit number for start
	orr r1, r4
	cmp r1, #0xfffffff7             // compares button sequence to bit number
	moveq r2, #4                    // moves the button number to r2 if equal
	beq endInterpreteSNES
	
	/* This checks if the up button hass been pressed */
	
	mov r1, r0                      // moves the button sequence into r1
	ldr r4, =0xffffffef             // bit number for left
	orr r1, r4
	cmp r1, #0xffffffef             // compares button sequence to bit number
	moveq r2, #5                    // moves the button number to r2 if equal
	beq endInterpreteSNES

	/* This checks if the down button hass been pressed */
	
	mov r1, r0                      // moves the button sequence into r1
	ldr r4, =0xffffffdf             // bit number for left
	orr r1, r4
	cmp r1, #0xffffffdf             // compares button sequence to bit number
	moveq r2, #6                    // moves the button number to r2 if equal
	beq endInterpreteSNES

	/* This checks if the left button has been pressed */
	
	mov r1, r0                      // moves the button sequence into r1
	ldr r4, =0xffffffbf             // bit number for left
	orr r1, r4
	cmp r1, #0xffffffbf             // compares button sequence to bit number
	moveq r2, #7                    // moves the button number to r2 if equal
	beq endInterpreteSNES
	
	/* This checks if right button was pressed */
	
	mov r1, r0                      // moves the button sequence into r1
	ldr r4, =0xffffff7f             // bit number for right
	orr r1, r4
	cmp r1, #0xffffff7f             // compares button sequence to bit number
	moveq r2, #8                    // moves the button number to r2 if equal
	beq endInterpreteSNES
	
	/* This checks if the A button was pressed */
	
	mov r1, r0                      // Moves the button sequence into r1
	ldr r4, =0xfffffeff             // bit number for A
	orr r1, r4
	cmp r1, r4                      // Compares button sequence to bit number
	moveq r2, #9                    // moves the button number to r2 if equal
	beq endInterpreteSNES

	/* This checks anything anything was pressed or not */
	
	mov r1, r0                      // Moves the button sequence into r1
	ldr r4, =0x0000ffff             
	orr r1, r4
	cmp r1, r4
	movne r2, #1                    // return 1 if pressed
	moveq r2, #0                    // return 0 if nothing
	bne endInterpreteSNES

endInterpreteSNES:

	mov     r0, r2                 // moves it into the return register
	
	pop     {r4, lr} 
	bx      lr

.section .data
