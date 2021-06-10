# OscilloscopeDisplayMeasure

A periodic wave generator test system. Where a potentiometer is used,  
and measurements are taken and displayed onto lcd display using it's driver and an atmega324a.
Using two 8 bit registers and one 16 bit register the counting interval is made identical to the processing speed of the ATmega324a,
measured ot be about one Mhz. This system implements the uses of interrupts on a rising edge. TCNT1H and TCNT1L hold the timer counter,
TCCR1A and TCCR1B are initialized to 0 to operate in normal mode.
The calculations are done and measurements included period and frequency are listed on the lcd due to table lookup.