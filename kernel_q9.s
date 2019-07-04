.text
.global main

main:
    
    #Set up the Interrupts
    movsg $2, $cctrl            #get the control register
    andi $2, $2, 0x000f         #disable all interrupts
    ori $2, $2, 0x42            #enable IRQ2 (the timer) and interupt enable
    movgs $cctrl, $2            #return the control register
    movsg $2, $evec             #get the old interrupt handlers address
    sw $2, oldVector($0)        #store that address in a variable in RAM
    la $2, handler              #get the address of our handler   
    movgs $evec, $2             #store it in the system handler address
  
    #setup timer                
    sw $0, TIA($0)              #clear old interrupts from timer
    addui $2, $0, 24            #set the amount of time inbetween each interrupt
    sw $2, TLR($0)              #store it in the timer load register    
    addi $2, $0, 3               
    sw $2, TCR($0)              #enable the timer so it starts when program starts    

    #setup pcb for task1
    addi $5, $0, 0x4d           #Unmask IRQ2,KU=1,OKU=1,IE=0,OIE=1
    la $1, task1_pcb            #get address of task1_pcb in RAM
    la $2, task2_pcb            #Setup the link field
    sw $2, pcb_link($1)
    la $2, task1_stack          #Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, serial_main           #Setup the $ear field
    sw $2, pcb_ear($1)
    sw $5, pcb_cctrl($1)        #Setup the $cctrl field
    addi $5, $0, 1              #Setup the enabled flag
    sw $5, pcb_enabled($1)  
    sw $0, pcb_exited($1)       #Setup the exited flag 
    la $5, exit                 #setup the return address
    sw $5, pcb_ra($1)
    addi $5, $0, 100		#Setup timeslice
    sw $5, pcb_timeslice($1)    
    j load_context              #load task1 pcb
  
handler:  
    movsg $13, $estat           #get the status register
    andi $13, $13, 0xffb0       #check if timer caused it
    beqz $13, handlerTimer 
    lw $13, oldVector($0)       #some other interrupt caused it so we dont want to handle it
    jr $13

handlerTimer:
    sw $0, TIA($0)              #acknowledge the interrupt
    lw $13, counter($0)         #get counter variable from RAM
    addi $13, $13, 1            #add 1 to it
    sw $13, counter($0)         #store counter variable back into RAM

    lw $13, timeSlice($0)       #Get the current time slice
    subi $13, $13, 1            #subtract 1
    beqz $13, dispatcher        #if time slice is 0, jump to dispatcher
    sw $13, timeSlice($0)       #if not, store time slice back in RAM
    rfe                         #return from the interrupt

dispatcher:
save_context:
     # Save the registers
	lw $13, current_task($0)    # Get the base address of the current PCB
	sw $1, pcb_reg1($13)        
	sw $2, pcb_reg2($13)
	sw $3, pcb_reg3($13)
	sw $4, pcb_reg4($13)
	sw $5, pcb_reg5($13)
	sw $6, pcb_reg6($13)
	sw $7, pcb_reg7($13)
	sw $8, pcb_reg8($13)
	sw $9, pcb_reg9($13)
	sw $10, pcb_reg10($13)
	sw $11, pcb_reg11($13)
	sw $12, pcb_reg12($13)
	sw $sp, pcb_sp($13) 
	sw $ra, pcb_ra($13) 

	movsg $1, $ers              # Get the old value of $13
	sw $1, pcb_reg13($13)       # and save it to the pcb
	movsg $1, $ear              # Get $ear
	sw $1, pcb_ear($13)
	movsg $1, $cctrl            # Get $cctrl
	sw $1, pcb_cctrl($13)

schedule:
	lw $13, current_task($0)    #Get current task
	lw $13, pcb_link($13)       #Get next task from pcb_link field
	sw $13, current_task($0)    #Set next task as current task 


    #if first time executing task 2, setup its pcb
    lw $13, setupTask2F($0)     
    sgt $13, $13, $0
	bnez $13, setupTask2    

    #if first time executing task 3, setup its pcb
    lw $13, setupTask3F($0)     
    sgt $13, $13, $0
	bnez $13, setupTask3

checkEnabled:
    lw $13, current_task($0)            #check if task is actually enabled
    lw $13, pcb_enabled($13)
    sgt $13, $13, $0
    beqz $13, incrementNumDisabled      #if task is NOT enabled, don't load its context
    j load_context                      #else, it is enabled so load its context

incrementNumDisabled:
    lw $13, current_task($0)
    lw $13, pcb_exited($13)             #check if first time exiting the task i.e. getting here
    sgt $13, $13, $0
    bnez $13, schedule                  #if it is NOT first time getting here, just jump back to schedule

    #It is first time getting here
    lw $13, current_task($0)            
    subi $sp, $sp, 1
    sw $1, 0($sp)
    addi $1, $0, 1
    sw $1, pcb_exited($13)              #Set exit flag to 1 so we don't increment numDisabled (i.e. get here) next time
    lw $1, 0($sp)
    addi $sp, $sp, 1

    lw $13, numDisabled($0)             #increment number of tasks disabled
    addi $13, $13, 1
    sw $13, numDisabled($0)

    seqi $13, $13, 3                    #if number of task disabled is 3
    bnez $13, setupIdleTask             #setup the idle task
    j schedule                          #else, jump to schedule to run the remaining tasks

setupIdleTask: 
    #setup pcb for idle task
    addi $5, $0, 0x4d               #Unmask IRQ2,KU=1,OKU=1,IE=0,OIE=1
    la $1, idle_task_pcb            #get address of idle_task_pcb in RAM
    la $2, idle_task_pcb            #Setup the link field
    sw $2, pcb_link($1)
    la $2, idle_task_stack          #Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, infiniteLoop             #Setup the $ear field
    sw $2, pcb_ear($1)
    sw $5, pcb_cctrl($1)            #Setup the $cctrl field
    addi $5, $0, 1                  #Setup the enabled flag
    sw $5, pcb_enabled($1)  
    sw $0, pcb_exited($1)           #Setup the exited flag 
    sw $1, current_task($0)         #set current task to idle task
    j load_context                  #load its context
        
infiniteLoop:
    #Infinetly prints "----" to the SSDs
    lw $13, PCR($0)
    andi $13, $13, 0xfffe
    sw $13, PCR($0)
    addi $13, $0, 64
    sw $13, SSD1($0)
    sw $13, SSD2($0)
    sw $13, SSD3($0)
    sw $13, SSD4($0)
    j infiniteLoop

load_context:
	lw $13, current_task($0)        #Get PCB of current task
	lw $1, pcb_reg13($13)           # Get the PCB value for $13 back into $ers
	movgs $ers, $1
	lw $1, pcb_ear($13)             # Restore $ear
	movgs $ear, $1
	lw $1, pcb_cctrl($13)           # Restore $cctrl
	movgs $cctrl, $1
    
    # Restore the other registers
	lw $1, pcb_reg1($13)
	lw $2, pcb_reg2($13)
	lw $3, pcb_reg3($13)
	lw $4, pcb_reg4($13)
	lw $5, pcb_reg5($13)
	lw $6, pcb_reg6($13)
	lw $7, pcb_reg7($13)
	lw $8, pcb_reg8($13)
	lw $9, pcb_reg9($13)
	lw $10, pcb_reg10($13)
	lw $11, pcb_reg11($13)
	lw $12, pcb_reg12($13)
    lw $sp, pcb_sp($13) 
	lw $ra, pcb_ra($13) 
	
	lw $13, pcb_timeslice($13)
	sw $13, timeSlice($0)	

	rfe                         # Return to the new task

setupTask2:   
    sw $0, setupTask2F($0)      #set setupTask2F to 0 so we don't setup its pcb here again

    #setup pcb for task2
    addi $5, $0, 0x4d           #Unmask IRQ2,KU=1,OKU=1,IE=0,OIE=1
    la $1, task2_pcb            #get address of task2_pcb in RAM
    la $2, task3_pcb            #Setup the link field
    sw $2, pcb_link($1)
    la $2, task2_stack          #Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, parallel_main         #Setup the $ear field
    sw $2, pcb_ear($1)
    sw $5, pcb_cctrl($1)        #Setup the $cctrl field
    addi $5, $0, 1              #Setup the enabled flag
    sw $5, pcb_enabled($1)  
    sw $0, pcb_exited($1)       #Setup the exited flag 
    la $5, exit                 #setup the return address
    sw $5, pcb_ra($1)
    addi $5, $0, 100
    sw $5, pcb_timeslice($1)
    j load_context              #load task2 pcb

setupTask3:
    sw $0, setupTask3F($0)      #set setupTask3F to 0 so we don't setup its pcb here again

    #setup pcb for task3
    addi $5, $0, 0x4d           #Unmask IRQ2,KU=1,OKU=1,IE=0,OIE=1
    la $1, task3_pcb            #get address of task3_pcb in RAM
    la $2, task1_pcb            #Setup the link field
    sw $2, pcb_link($1)
    la $2, task3_stack          #Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, rocks_main           #Setup the $ear field
    sw $2, pcb_ear($1)
    sw $5, pcb_cctrl($1)        #Setup the $cctrl field
    addi $5, $0, 1              #Setup the enabled flag
    sw $5, pcb_enabled($1)  
    sw $0, pcb_exited($1)       #Setup the exited flag 
    la $5, exit                 #Setup return address
    sw $5, pcb_ra($1)  
    addi $5, $0, 400
    sw $5, pcb_timeslice($1)
    j load_context              #load task3 pcb

exit: #subroutine for exiting a task
    lw $13, current_task($0)    #get current task
    sw $0, pcb_enabled($13)     #disable the task
    j schedule                  #move onto next task




.data

    current_task: .word task1_pcb
    setupTask2F: .word 1
    setupTask3F: .word 1
    timeSlice: .word 100
    numDisabled: .word 0
    

.bss
    oldVector: .word
    
    .equ TIA,           0x72003        #Timer Interrupt Acknowldeg register
    .equ TLR,           0x72001        #Timer Load Register
    .equ TCR,           0x72000        #Timer Control Register  
    .equ PCR,           0x73004        #Parallel control register
    .equ SSD1,          0x73006        #Parallel control register
    .equ SSD2,          0x73007        #Parallel control register
    .equ SSD3,          0x73008        #Parallel control register
    .equ SSD4,          0x73009        #Parallel control register
  
    .equ pcb_link, 0
    .equ pcb_reg1, 1
    .equ pcb_reg2, 2
    .equ pcb_reg3, 3
    .equ pcb_reg4, 4
    .equ pcb_reg5, 5
    .equ pcb_reg6, 6
    .equ pcb_reg7, 7
    .equ pcb_reg8, 8
    .equ pcb_reg9, 9
    .equ pcb_reg10, 10
    .equ pcb_reg11, 11
    .equ pcb_reg12, 12
    .equ pcb_reg13, 13
    .equ pcb_sp, 14 
    .equ pcb_ra, 15
    .equ pcb_ear, 16
    .equ pcb_cctrl, 17
    .equ pcb_enabled, 18
    .equ pcb_exited, 19
    .equ pcb_timeslice, 20

    .space 100
    task3_stack:

    task3_pcb:  
        .space 21
	
    .space 100
    task2_stack:

    task2_pcb:  
        .space 21

    .space 100
    task1_stack:

    task1_pcb:  
        .space 21

    idle_task_pcb:
        .space 21

    .space 100
    idle_task_stack:

  
