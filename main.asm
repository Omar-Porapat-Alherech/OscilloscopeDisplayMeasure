.nolist
.include "m324adef.inc"  
.list
.CSEG
     ; interrupt vector table
	 ;, with several 'safety' stubs
     rjmp RESET;Reset
	 ;/Cold start vector
     reti  ;External 
	 ;Intr0 vector
     reti           
	  ;External Intr1 vector


; LCD DOG init/update procedures.
.include "lcd_dog_asm_driver_m324a.inc"
;---------------------------- SUBROUTINES
clr_dsp_buffs:
     ldi R25, 48               
	 ; load total length of both buffer.
     ldi R26, ' '              
	 ; load blank/space into R26.
     ldi ZH, high (dsp_buff_1) 
	 ; Load ZH and ZL as a pointer to 1st
     ldi ZL, low (dsp_buff_1)  
	 ; byte of buffer for line 1.
   
    ;set DDRAM address to 1s
	;t position of first line.
store_bytes:
     st  Z+, R26       ; store ' '
	 ; into 1st/next buffer byte and
                       ; auto inc 
					   ;ptr to next location.
     dec  R25          ; 
     brne store_bytes  ; cont until
	 ; r25=0, all bytes written.
     ret
	 
load_msg:
     ldi YH, high (dsp_buff_1) 
	 ; Load YH and YL as a pointer to 1st
     ldi YL, low (dsp_buff_1)  
	 ; byte of dsp_buff_1 (Note - assuming 
     ; (dsp_buff_1 for now).
     lpm R16, Z+
	 ; get dsply buff number (1st byte of msg).
     cpi r16, 1                
	 ; if equal to '1', ptr already setup.
     breq get_msg_byte        
	  ; jump and start message load.
     adiw YH:YL, 16           
	  ; else set ptr to dsp buff 2.
     cpi r16, 2               
	  ; if equal to '2', ptr now setup.
     breq get_msg_byte         
	 ; jump and start message load.
     adiw YH:YL, 16           
	  ; else set ptr to dsp buff 2.
        
get_msg_byte:
     lpm R16, Z+              
	  ; get next byte of msg and see if '0'.        
     cpi R16, 0               
	  ; if equal to '0', end of message reached.
     breq msg_loaded          
	  ; jump and stop message loading operation.
     st Y+, R16               
	  ; else, store next byte of msg in buffer.
     rjmp get_msg_byte         
	 ; jump back and continue...
msg_loaded:
     ret	 
	 

RESET:
    ldi r16, low(RAMEND)  
	; init stack/pointer
    out SPL, r16          ;
    ldi r16, high(RAMEND) ;
    out SPH, r16


    ldi r16, 0xff     
	; set portB = output.
    out DDRB, r16     ; 
    sbi portB, 4      
	; set /SS of DOG LCD = 1 (Deselected)


    rcall init_lcd_dog    
	; init display, using SPI serial interface
    rcall clr_dsp_buffs  
	 ; clear all three buffer lines


   ;load_line_1 into dbuff1:
   ldi  ZH, high(line1_testmessage<<1)  ;
   ldi  ZL, low(line1_testmessage<<1)   ;
   rcall load_msg          
   ; load message into buffer(s).


   ldi  ZH, high(line2_testmessage<<1)  ;
   ldi  ZL, low(line2_testmessage<<1)   ;
   rcall load_msg          
   ; load message into buffer(s).


   ldi  ZH, high(line3_testmessage<<1)  ;
   ldi  ZL, low(line3_testmessage<<1)   ;
   rcall load_msg          
   ; load message into buffer(s).
   rcall update_lcd_dog

 
   
   
;****************************************************
;M A I N   A P P L I C A T I O N   C O D E  *********
;****************************************************

configuration:
				ldi r16 , 0b11000010; PC6-7,1
				; - Outputs
                out DDRC, r16;
				ldi r16, 0b00111100; Inputs -  Enable
				; Pullups 
                out PORTC, r16;
				ldi r16, 0b10001111; PA6-PA4 - Inputs:
                out DDRA, r16;
				ldi r16, 0b00000000; PD0-7 - Inputs
                out DDRD,r16;
				ldi r16, $FF; Pull up Resistors
                out PORTD,r16;
				ldi r16, $80;; turn on led
                out PORTC, r16;
				rcall delay
				ldi r16, $02; turn on led
                out PORTC, r16
				rcall delay
				ldi r16, $40; turn on led
                out PORTC, r16;
				rcall delay
				ldi r16, 0b11000010
				out PORTC, R16
				rcall delay
				clr r18
				clr r19
				clr r20
				jmp main

			delay:	
				ldi  r18, 3
				ldi  r19, 138
                ldi  r20, 86
              L1: dec  r20
                brne L1
                dec  r19
                brne L1
                dec  r18
                brne L1
				ret

main:
waiting_for_one:
				sbis PINC, 0; check for 1
				rjmp waiting_for_one;
				ldi r18, 32; Set delay
				ldi r19, 0;
				nop;
				nop; nops fill in delay
				nop;
one:
				dec r18; countdown
				brne one; 
				ldi r18, 32;
				inc r19;	count every 0.1s
				sbic PINC, 0; check for 0
				rjmp one;
zero:
				dec r18; delay
				brne zero;
				ldi r18, 32; set delay
				inc r19;
				sbis PINC, 0; check for last 1
				rjmp zero;
load_first_line:
				ldi r22, 0b00001000; Set counter for 8
				ldi YH, high (dsp_buff_1); Load YH
				; pointer line 1
				ldi YL, low (dsp_buff_1); Load YL
				; pointer line 1
				adiw YH:YL, 7; Adds 7 to
				; the value of the y reg
				mov r23,r19; copies value to r20
				mov r24, r19;
				mov r25, r19;
count_binary:
				cpi r22, 0b00000000; compare to 0
				breq load_2nd_msg; if 0 msg is done
				lsl r23; shift left
				dec r22; count down
				brcc load_zero; checks carry flag 0
				brcs load_set; checks for 1
load_set:
				ldi r24, '1'; loads register
				; with ascii 1
				st Y+, r24; loads into next right
				; digit
				rjmp count_binary; next digit
load_zero:
				ldi r24, '0'; loads with ascii 0
				st Y+, r24; loads into next
				; right digit
				rjmp count_binary; next digit
load_2nd_msg: ; just exists to jump
; out of the loop			

decision_tree: ;compares the values to
 ;the tolerance percentage
			cpi r25, 97;
			brlo red_rebound_up_2;
			cpi r25, 107;
			brsh red_rebound_down_2;
			cpi r25, 104;
			brsh blue_rebound_down_2;
			cpi r25, 99;
			brlo blue_rebound_up_2;
			rjmp green_one_percent;

green_one_percent:                              
				cpi r25, 100
				brlo green_two_percent_up
				; 1 or 2 percent
				cpi r25, 102
				brsh green_two_percent_down
				; 1 or 2 percent
                ldi r16, $02;
				 ;load msg line2-3
                out PORTC, r16;
				ldi r16, '*'
				std Y+11, r16
				ldi r16, ' '
				std Y+7, r16
				std Y+8, r16
				std Y+9, r16
				std Y+10, r16
				std Y+12, r16 
				std Y+13, r16 
				std Y+14, r16 
				ldi YH, high (dsp_buff_3)
                ldi YL, low (dsp_buff_3)
				ldi r16, '0'
				std Y+7, r16
                ldi r16, '2'
                std Y+8, r16
                ldi r16, '%'
                std Y+9, r16 
                rcall update_lcd_dog
                jmp main;
green_two_percent_up:
				ldi YH, high (dsp_buff_2)
				; loads YH pointer line2
                ldi YL, low (dsp_buff_2)
				;  loads YL pointer line2
				clr r16;
				clr r17;
				ldi r16, ' ';load msg line2
				std Y+7, r16;
				std Y+8, r16; 
				std Y+9, r16; 
				std Y+12, r16; 
				std Y+13, r16; 
				ldi r16, '*';
				std Y+10, r16;
				ldi r16, '<'; 
				std Y+11, r16; 
				ldi r16, $02;
                out PORTC, r16;
				ldi YH, high (dsp_buff_3)
				;loads YH pointer line3
                ldi YL, low (dsp_buff_3)
				;loads YL pointer line3
				ldi r16, '0'; load line 3
				std Y+7, r16;
                ldi r16, '2';
                std Y+8, r16;
                ldi r16, '%';
                std Y+9, r16;
				rcall update_lcd_dog;
				jmp main;
red_rebound_up_2: ;jump labels
	jmp red_rebound_up;
red_rebound_down_2:
	jmp red_rebound_down;
blue_rebound_down_2:
	jmp blue_rebound_down;
blue_rebound_up_2:
	jmp blue_rebound_up; 
green_two_percent_down:
				ldi YH, high (dsp_buff_2)
				; loads YH pointer line2
                ldi YL, low (dsp_buff_2)
				;  loads YL pointer line2
				clr r16;
				clr r17;
				ldi r16, '>';load msg line2
				std Y+7, r16;
				ldi r16, '*';
				std Y+10, r16;
				ldi r16, ' '; 
				std Y+11, r16; 
				std Y+12, r16; 
				std Y+13, r16; 
				std Y+7, r16;
				std Y+8, r16; 
				ldi r16, $02;
                out PORTC, r16;
				ldi YH, high (dsp_buff_3)
				;loads YH pointer line3
                ldi YL, low (dsp_buff_3)
				;loads YL pointer line3
				ldi r16, '0'; load line 3
				std Y+7, r16;
                ldi r16, '2';
                std Y+8, r16;
                ldi r16, '%';
                std Y+9, r16;
				rcall update_lcd_dog;
				jmp main;
red_rebound_up: ;jump labels
	jmp red_up;
red_rebound_down:
	jmp red_down;
blue_rebound_down:
	jmp blue_down;
blue_rebound_up:
	jmp blue_up; 
blue:                     
                ldi r16, $40;
                out PORTC, r16
				;load msg 3
				clr r17
				ldi YH, high (dsp_buff_3)
				;loads YH pointer line3
                ldi YL, low (dsp_buff_3)
				;loads YL pointer line3
				ldi r16, '0'
				std Y+7, r16
                ldi r16, '5'
                std Y+8, r16
                ldi r16, '%'
                std Y+9, r16
                rcall update_lcd_dog
                jmp main;
blue_up:
				ldi YH, high (dsp_buff_2)
                ldi YL, low (dsp_buff_2)
				clr r17
				ldi r16, '<' 
				;load msg line2
				std Y+11, r16 
				std Y+12, r16 
				ldi r16, ' '
				std Y+8, r16
				std Y+7, r16
				std Y+9, r16  
				std Y+13, r16 
				std Y+14, r16 
				ldi r16, '*'
				std Y+10, r16
				jmp blue

blue_down:
				ldi YH, high (dsp_buff_2)
				;loads YH pointer line2
                ldi YL, low (dsp_buff_2)
				; loads YL pointer line2
				clr r17;
				ldi r16, '>';  
				std Y+8, r16;   
				std Y+9, r16;  
				;load msg line2
				ldi r16, ' ';
				std Y+10, r16;
				std Y+11, r16 ;
				std Y+12, r16 ;
				std Y+7, r16;  
				std Y+13, r16; 
				ldi r16, '*';
				std Y+10, r16;
				jmp blue


red_up:
				ldi YH, high (dsp_buff_2)
				;loads YH pointer line2
                ldi YL, low (dsp_buff_2)
				;loads YL pointer line2
				ldi r16, '<'
				;load msg line2
				ldi r16, ' ';
				std Y+8, r16;   
				std Y+7, r16;  
				std Y+9, r16;
				ldi r16, '<'
				std Y+11, r16; 
				std Y+12, r16; 
				std Y+13, r16; 
				ldi r16, '*';
				std Y+10, r16;
				jmp red;
red_down:
				ldi YH, high (dsp_buff_2)
				;loads YH pointer line2
                ldi YL, low (dsp_buff_2)
				;loads YL pointer line2
				clr r17;
				ldi r16, '>';
				;load msg line2
				std Y+8, r16;  
				std Y+7, r16;  
				std Y+9, r16;
				ldi r16, ' ';
				std Y+11, r16; 
				std Y+12, r16; 
				std Y+13, r16 ;
				ldi r16, '*';
				std Y+10, r16;
				jmp red;
red:           					
                ldi r16, $80;
                out PORTC, r16;
				ldi YH, high (dsp_buff_3)
				;;loads YH pointer line3
                ldi YL, low (dsp_buff_3)
				;loads YL pointer line3
                ldi r16, '0';
                std Y+7, r16;
                ldi r16, '0';
                std Y+8, r16;
                ldi r16, 'R';
                std Y+9, r16;
                rcall update_lcd_dog;
                jmp main;
			




line1_testmessage: .db 1, "CNTB =", 0 
line2_testmessage: .db 2, "CNTD =", 0  
line3_testmessage: .db 3, "TOL  =", 0   



;*****************************
;*
;* "bin2BCD16" - 16-bit Binary to BCD conversion
;*
;* This subroutine converts
; a 16-bit number (fbinH:fbinL) to a 5-digit 
;* packed BCD number represented
; by 3 bytes (tBCD2:tBCD1:tBCD0).
;* MSD of the 5-digit number is
; placed in the lowermost nibble of tBCD2.
;*  
;* Number of words        :25
;* Number of cycles        :751/768 (Min/Max)
;* Low registers used      :3 (tBCD0,tBCD1,tBCD2) 
;* High registers used  
;:4(fbinL,fbinH,cnt16a,tmp16a)      
;* Pointers used               :Z
;*
;*****************************

;***** Subroutine Register Variables

.equ       AtBCD0 =13  ;address of tBCD0
.equ       AtBCD2 =15   ;address of tBCD1
.def        tBCD0  =r13;BCD value digits 1 and 0
.def        tBCD1  =r14 ;BCD value digits 3 and 2
.def        tBCD2  =r15 ;BCD value digit 4
.def        fbinL  =r16 ;binary value Low byte
.def        fbinH  =r17 ;binary value High byte
.def        cnt16a =r18  ;loop counter
.def        tmp16a =r19   ;temporary value

;***** Code

bin2BCD16:
                ldi cnt16a,16          
                clr tBCD2  
                clr tBCD1                    
                clr tBCD0                    
                clr ZH    
bBCDx_1:lsl        fbinL       ;shift input value
                rol fbinH ;through all bytes
                rol tBCD0 ;
                rol tBCD1
                rol tBCD2
                dec cnt16a ;decrement loop
                brne bBCDx_2  ;if counter 
                ret  ;   return

bBCDx_2:ldi        r30,AtBCD2+1    ;Z points
; to result MSB + 1
bBCDx_3:
                ld            tmp16a,-Z ;get
				; (Z) with pre-decrement
;-------------------
;For AT90Sxx0x, substitute the above line with:
;
;               dec         ZL
;               ld            tmp16a,Z
;
;-------------------
                subi        tmp16a,-$03;add 0x03
                sbrc        tmp16a,3 ;if bit 3
				; not clear
                st            Z,tmp16a ; store back
                ld            tmp16a,Z ;get (Z)
                subi        tmp16a,-$30 ;add 0x30
                sbrc        tmp16a,7 ;if bit 7 not
				; clear
                st            Z,tmp16a  ; store back
                cpi          ZL,AtBCD0    ;done all
				; three?
                brne      bBCDx_3      ;loop again
				; if not
                rjmp      bBCDx_1				
			