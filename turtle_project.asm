#The overall structure of the instructionsam is that initially 'paint' paints the picture white, 'picture_init' loads the image and 
#'main_loop' loads the instructions and executes addequate instruction

#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90122
.eqv BYTES_PER_ROW 1800
.eqv HEADER_SIZE 122
.eqv BMP_IMAGE_SIZE 90000
.eqv BIN_FILE_SIZE 6000
.data
#some values to input to console
debug: .asciiz "here_it_be_buggy "
bug: .asciiz "its_bugged"

f_output: .asciiz "output.bmp"
f_input:  .asciiz "input.bin"
.align 2
instructions:		.space BIN_FILE_SIZE
.align 2
		.space 2
		#storing the header of the .bmp file in field 'picture'
picture:	.byte 0x42,0x4d,0x0a,0x60,0x01,0,0,0,0,0,0x7a,0,0,0,0x6c,0,0,0,0x58,0x02,0,0,0x32,0,0,0,0x01,0,0x18,0,0,0,0,0,0x60,0x5f,0x01,0,0x13,0x0b,0,0,0x13,0x0b,0,0,0,0,0,0,0,0,0,0,0x42,0x47,0x52,0x73,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0x02,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.space BMP_IMAGE_SIZE
.text
paint: #loading the file
	li $t0, BMP_IMAGE_SIZE #load immiediate value BMP_IMAGE_SIZE into temporary register t0
	srl $t0, $t0, 2 #shifting right logically the value in temporary register t0 by 2 bits. 
	la $t1, picture + HEADER_SIZE #loading address of the last bit of our .bmp file
	li $t2, 0xffffffff #painting the file white
picture_init:
	sw $t2, ($t1) #allocating data
	addi $t1, $t1, 4 #adding 4 to allocate 4 bits at a time
	subi $t0, $t0, 1 #subtracting 1 since some data was already allocated
	bgtz $t0, picture_init #branching if an picture was not loaded
	jal read_bin_file #jump and link to 'read_bin_file'
	la $s6, instructions #loading address of BIN_FILE_SIZE into register s6 (saved register)
main_loop:
	blez $s0, save #branch to save if s0 (counter of instructions) is less or equal to 0
	#loading instructions
	lbu $t0, ($s6) #loading first word from register s6
	sll $t0, $t0, 8 #adding additional 8 bits to t0
	lbu $t1, 1($s6) #loading second word from register s6
	or $t0, $t0, $t1 #merging data from t0 and t1 and storing it in t0
	addi $s6, $s6, 2 #moving the file by 2 bytes to take the next 2 words upon next iteration of the main_loop
	subi $s0, $s0, 1 #decrementing the counter of instructions by 1
	andi $t2, $t0, 3 #logically and'ing the data from register t0 with immediate value 3 (bitwise in binary)
	#choosing which instruction to execute, depending on the result from the line 61
	beqz $t2, instr00
	beq $t2, 1, instr01
	beq $t2, 2, instr10
	beq $t2, 3, instr11
#'pen state' instruction
instr00: 
	andi $s5, $t0, 0xf000 #checking if t0 contains bits for red color
	sll $s5, $s5, 8 #zero'ing s5
	andi $t2, $t0, 0x0f00 #checking if t0 contains bits for green color
	sll $t2, $t2, 4 #shifting t2 by 4 bits to theck for the next color
	or $s5, $s5, $t2 #or'ing data from t2 with s5 (bitwise, in binary)
	andi $t2, $t0, 0x00f0 #checking if t0 contains bits for blue color
	or $s5, $s5, $t2 #or'ing data from s5 and t2
	#U/D (D=8=1000 in bin)
	andi $s4, $t0, 0x0008 #checking if pen is up or down
	j main_loop
#'move' instruction
instr01:
	srl $t2, $t0, 6 #distance to be travelled
	#chosing direction
	beqz $s3, right
	beq $s3, 1, up
	beq $s3, 2, left
	beq $s3, 3, down
right:
	beq $s1, 599, main_loop #branch to 'main_loop' if x-coordinate reach the boundry
	#boundries
	addu $s7, $s1, $t2 #adding the distance that the turtle is to travel to current position in s1
	ble $s7, 599, goright #branching to 'goright' if s7 has not reached the boundry
	li $s7, 599 #starting from 599 (boundry)
goright:
	beqz $s4, jump_right #branch if pen is up
draw_right:
	addiu $s1, $s1, 1 #iterate x coordinate
	move $a0, $s1 #copy data from s1 to a0 (s1 stores the x-coordinate)
	move $a1, $s2 #copy data from s2 to a1 (s2 stores the y-coordinate)
	move $a2, $s5 #copy data from s5 to a2 (s5 stores the information about colors)
	jal put_pixel #jump and link to 'put_pixel'
	bltu $s1, $s7, draw_right #branch to 'draw_right' if x-coordinate is lower than boundry
jump_right:
	move $s1, $s7 #copy x-coordinate to s1
	j main_loop #jump back to main_loop after moving the turtle by a certain distance to the right
up:	#this follows the identical reasoning as 'right' except for 'up' and 'down' 599 changes to 49 since that is our new boundry in y-axis. Also for 'down' and 'left' ble changes to bge and addu to subu since
	#we are moving in the opposite direction in respect to 'up' and 'right' respectively
	beq $s2, 49, main_loop
	#borders
	addu $s7, $s2, $t2
	ble $s7, 49, goup
	li $s7, 49
goup:
	beqz $s4, jump_up #dont draw if pen is up
draw_up:
	addiu $s2, $s2, 1 #iterate y coordinate
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bltu $s2, $s7, draw_up
jump_up:
	move $s2, $s7
	j main_loop
left:
	beqz $s1, main_loop
	#borders
	subu $s7, $s1, $t2
	bgez $s7, goleft
	li $s7, 0
goleft:
	beqz $s4, jump_left  #dont draw if the pen is up
draw_left:
	subiu $s1, $s1, 1 #decrement x coordinate
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bgtu $s1, $s7, draw_left
jump_left:
	move $s1, $s7
	j main_loop
down:
	beqz $s2, main_loop
	#borders
	subu $s7, $s2, $t2
	bgez $s7, godown
	li $s7, 0
godown:
	beqz $s4, jump_down #dont draw if pen is up
draw_down:
	subiu $s2, $s2, 1	#decrement y coordinate
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bgtu $s2, $s7, draw_down
jump_down:
	move $s2, $s7
	j main_loop
instr10: #'set direction' instruction
	srl $s3, $t0, 14 #shifting to the right to check last two bits and know what direction the turtle should be facing.
	j main_loop #jumping back to main_loop
instr11: #'set position' instruction
	#y-coordinate
	andi $s2, $t0, 0x00fc #logically and'ing to check y-coordinate
	srl $s2, $s2, 2 #shifting to the right to remove unnecessary instruction bits
	#taking next word to check the x-coordinate
	lbu $s2, ($s6)
	sll $s1, $s1, 8
	lbu $t1, 1($s6)
	or $1, $s1, $t1
	addi $s6, $s6, 2
	subi $s0, $s0, 1
	#x-coordinate
	andi $s1, $s1, 0x03ff #logically ending to check the x-coordinate
	j main_loop #jumping back to main_loop
save:	
	jal save_bmp #jumping and linking to save the .bmp
exit: 	#exiting the instructionsam
	li $v0, 10
	syscall
#-----------------------------------
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1,($sp)
#open file
	li $v0, 13
        la $a0, f_output		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...
	bgtz $s1, save_file
	
	lw $s1, ($sp)
	add $sp, $sp, 4
	li $v0, 4
	la $a0, bug
	syscall
	jr $ra
	
save_file:
	li $v0, 15
	move $a0, $s1
	la $a1, picture
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, ($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra


#-----------------------------------
read_bin_file:
	sub $sp, $sp, 4		# push $ra to the stack
	sw $ra, ($sp)
	sub $sp, $sp, 4		# push $s1
	sw $s1, ($sp)
	
	li $v0, 13			# open file
	la $a0, f_input
	li $a1, 0		# 0 = read
	li $a2, 0 		# ignored
	syscall	
	move $s1, $v0		# save the file descriptor to $s1
	
	bgtz $s1, read
	
	lw $s1, ($sp)
	add $sp, $sp, 4
	lw $ra, ($sp)
	add $sp, $sp, 4
	li $v0, 4			# print string
	la $a0, bug
	syscall
	
	jr $ra
#-----------------------------------
read:
	li $v0, 14
	move $a0, $s1
	la $a1, instructions
	li $a2, BIN_FILE_SIZE
	syscall
	
#	move $s0, $v0
	sra $s0, $v0, 1
	
	li $v0, 16 #close file
	move $a0, $a1 #file descriptor
	syscall
	
	lw $s1, ($sp)
	add $sp, $sp, 4
	lw $ra, ($sp)
	add $sp, $sp, 4
	
	jr $ra
#-----------------------------------
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)

	la $t1, picture + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, picture		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
