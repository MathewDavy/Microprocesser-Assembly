.text
.global serial_main
.global counter
   
serial_main:

    #check which format to print the time
    lw $1, format($0)       #get char recieved from SP2
    seqi $2, $1, 49         #if char was '1'
    bnez $2, format1
    
    seqi $2, $1, 50         #if char was '2'
    bnez $2, format2

    seqi $2, $1, 51         #if char was '3'
    bnez $2, format3

    seqi $2, $1, 113        #if char was 'q'
    bnez $2, format4

    j getChar		        #if char was none of these, wait for next char

format1:
    subui $sp, $sp, 6        #make room for 6 chars
    addi $1, $0, -38         #store new line char
    sw $1, 0($sp)
    lw $1, counter($0)       #load counter
    divi $1, $1, 100         #get its seconds value
    divi $2, $1, 60          #get the minutes
    sgti $3, $2, 99          #if minutes greater than 99
    bnez $3, tooBig             
    divi $3, $2, 10          #get the minutes 10's column
    sw $3, 1($sp)
    remi $3, $2, 10          #get the minutes 1's column
    sw $3, 2($sp)
    
    addi $2, $0, 10          #store colon char
    sw $2, 3($sp)
    
    remi $1, $1, 60          #get the seconds 10's
    divi $2, $1, 10
    sw $2, 4($sp)
    remi $2, $1, 10          #get the seconds 1's
    sw $2, 5($sp)
    
    addi $2, $0, 6           #counter variable for number of chars  
    j print

tooBig:
    addi $1, $0, 9          #store '9' for every column
    sw $1, 1($sp)
    sw $1, 2($sp)
    addi $2, $0, 10	        #Store colon char
    sw $2, 3($sp)
    sw $1, 4($sp)
    sw $1, 5($sp)
    addi $2, $0, 6          #counter variable for number of chars  
    j print
    
format2:
    subui $sp, $sp, 8        #make room for 5 chars
    addi $1, $0, -38         #store new line char
    sw $1, 0($sp)
    lw $1, counter($0)       #load counter
    divi $2, $1, 100         #get its seconds value

    divi $3, $2, 1000        #get 1000's column
    sw $3, 1($sp)
    remi $2, $2, 1000

    divi $3, $2, 100         #get 100's column
    sw $3, 2($sp)
    remi $2, $2, 100

    divi $3, $2, 10          #get 10's column
    sw $3, 3($sp)
    remi $2, $2, 10          #get 1's column
    sw $2, 4($sp)

    addi $2, $0, -2         #store fullstop char
    sw $2, 5($sp)

    remi $1, $1, 100        #get number after the decimal point
    divi $2, $1, 10         #get the tenths column
    sw $2, 6($sp)
    remi $1, $1, 10         #get the hundreths column
    sw $1, 7($sp)
    
    addi $2, $0, 8          #counter variable for number of chars  
    j print

format3:
    subui $sp, $sp, 7        #make room for 7 chars
    addi $1, $0, -38         #store new line char
    sw $1, 0($sp)
    lw $1, counter($0)       #load counter
    divi $2, $1, 10000      #get 100,000's column
    divi $2, $2, 10
    sw $2, 1($sp)
    addi $2, $0, 1000
    multi $2, $2, 100
    rem $1, $1, $2

    divi $2, $1, 10000      #get 10,000's column
    sw $2, 2($sp)
    remi $1, $1, 10000

    divi $2, $1, 1000      #get 1,000's column
    sw $2, 3($sp)
    remi $1, $1, 1000

    divi $2, $1, 100      #get 100's column
    sw $2, 4($sp)
    remi $1, $1, 100

    divi $2, $1, 10      #get 10's column
    sw $2, 5($sp)
    remi $1, $1, 10         #get 1's column
    sw $1, 6($sp) 
    
    addi $2, $0, 7          #counter variable for number of chars  
    j print

format4:
    jr $ra

print:  
    lw $1, SP2SR($0)          #get serial port 2 status
    andi $1, $1, 0x2        #check char has been sent
    beqz $1, print          #if not, keep checking
    lw $1, 0($sp)           #if so, print char in stack
    addi $1, $1, 48
    sw $1, SP2($0)
    addui $sp, $sp, 1
    subi $2, $2, 1
    seqi $1, $2, 0
    bnez $1, getChar
    j print

getChar:

    lw $1, SP2SR($0)      #Get serial port 1 status
    andi $1, $1, 0x1      #check char has been recieved
    beqz $1, getChar
    lw $1, SP2RD($0)      #we got the char so load it to $1   
    sw $1, format($0)     #Store char in RAM
    j serial_main                #change format


.data
    counter:        .word 0
    format:         .word 50
   
.bss
    .equ SP2,            0x71000     #Serial port 2
    .equ SP2SR,           0x71003     #Serial port 2 status register
    .equ SP2RD,           0x71001     #Serial port 2 receive data register

