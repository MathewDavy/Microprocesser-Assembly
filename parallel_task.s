.text
.global parallel_main

parallel_main:

    lw $13, PBR($0)                 #check which push button was pressed
    seqi $12, $13, 1                #if it is the rightmost one
    bnez $12, setToBase16           #set to base 16 
    seqi $12, $13, 2                #if it was the middle button
    bnez $12, setToBase10           #set to base 10 
    seqi $12, $13, 4                #if it is the leftmost one
    bnez $12, terminate             #terminate the program
    j process                       #if anything else, just keep current base

process: 
	lw $1, switches($0)             #read switches
    lw $2, whichBase($0)            #load flag indicating which base
    bnez $2, base16                 #if flag is 1, show in base 16, else show in base 10
	subi $2, $1, 10000              #check if greater than 4 digits
	slti $2, $2, 1
	beqz $2, digit5
	divi $2, $1, 1000               #get 1000's column
	sw $2, SSD1($0)
	remi $1, $1, 1000
	divi $2, $1, 100                #get 100's column
	sw $2, SSD2($0)
	remi $1, $1, 100
	divi $2, $1, 10                 #get 10's column
	sw $2, SSD3($0)
	remi $1, $1, 10                 #get 1's column
	sw $1, SSD4($0)
	j parallel_main                         #infinite loop

setToBase10:
    sw $0, whichBase($0)            #set flag 0
    j process

setToBase16:
   addi $13, $0, 1
   sw $13, whichBase($0)            #set flag to 1
   j process

terminate:
    jr $ra

base16:
    srli $2, $1, 12             #Write to 1st SSD
    sw $2, SSD1($0)
    andi $2, $1, 0x00000F00     #Write to 2nd SSD
    srli $2, $2, 8
    sw $2, SSD2($0)
    andi $2, $1, 0x000000F0     #Write to 3rd SSD
    srli $2, $2, 4
    sw $2, SSD3($0)  
    andi $2, $1, 0x0000000F     #write to 4th SSD
    sw $2, SSD4($0) 
    j parallel_main      

digit5:
	addi $1, $0, 9              #number is over 4 digits so store '9999'
	sw $1, SSD1($0)
	sw $1, SSD2($0)
	sw $1, SSD3($0)
	sw $1, SSD4($0)
	j parallel_main

.data
   
    whichBase:      .word 1     #flag for indicating base 10 or 16

.bss
    
	.equ switches,      0x73000    	#switches register
	.equ SSD1,      	0x73006    	#SSD1
	.equ SSD2,      	0x73007    	#SSD2
	.equ SSD3,      	0x73008    	#SSD3
	.equ SSD4,      	0x73009    	#SSD4
    .equ PBR,           0x73001     #Parallel Push Button Register
	

