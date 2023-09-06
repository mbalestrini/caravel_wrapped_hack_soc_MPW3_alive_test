`timescale 1ns/10ps

module rom_M23LC1024 (SI_SIO0, SO_SIO1, SCK, CS_N, SIO2, HOLD_N_SIO3, RESET);

   inout                SI_SIO0;                        // serial data input/output
   input                SCK;                            // serial data clock

   input                CS_N;                           // chip select - active low

   inout                SIO2;                           // serial data input/output 		
   
   inout                HOLD_N_SIO3;                    // interface suspend - active low/
                                                        //   serial data input/output

   input                RESET;                          // model reset/power-on reset

   inout                SO_SIO1;                        // serial data input/output

endmodule
