`timescale 1ns / 1ps

module my_timer #
(
    parameter DATA_WIDTH = 24 
)
(
    input                          piezo_ramp_trigger,
    input                          peak_trigger,
    input                          clk,
    input                          rst,
    output [DATA_WIDTH-1:0]        m_axis_sm_cycle_tdata,
    output                         m_axis_sm_cycle_tvalid,
    output [DATA_WIDTH-1:0]        m_axis_Mm_cycle_tdata,
    output                         m_axis_Mm_cycle_tvalid
);
    
    reg                            hold = 1'b0 ;
    reg  [1:0]                     peak_number = 2'd0 ;   // 2-bit, 0,1,2,3
    reg  [DATA_WIDTH-1:0]          counter ;              // clock cycle counter, can count as slow as ~ 7.46 Hz
    reg  [DATA_WIDTH-1:0]          clk_cycle_peak_0 ;     // peak m, i.e. first 650nm peak  
    reg  [DATA_WIDTH-1:0]          clk_cycle_peak_1 ;     // peak s, i.e. 493nm peak
    reg  [DATA_WIDTH-1:0]          clk_cycle_peak_2 ;     // peak M, i.e. second 650nm peak
    reg  [DATA_WIDTH-1:0]          s_m_cycle ;  // tau_A
    reg  [DATA_WIDTH-1:0]          M_m_cycle ;  // tau_B
 
    always @(posedge clk) 
    begin
        if ( (hold == 1'b0) && (piezo_ramp_trigger == 1'b1) ) 
        begin
            hold <= 1'b1;        
            counter <= 24'd0; 
            peak_number <= 2'd0;
        end

        else if (hold == 1'b1)
        begin

            if (peak_trigger == 1'b1) 
            begin
                if (peak_number == 2'd0) 
                begin
                    clk_cycle_peak_0 <= counter; 
                    peak_number <= peak_number + 1;
                    counter <= counter + 1; 
                end
                else if (peak_number == 2'd1)
                begin
                    clk_cycle_peak_1 <= counter; 
                    peak_number <= peak_number + 1;
                    counter <= counter + 1; 
                end
                else if (peak_number == 2'd2)
                begin
                    clk_cycle_peak_2 <= counter; 
                    peak_number <= peak_number + 1;
                    counter <= counter + 1; 
                end
                else if (peak_number == 2'd3)
                begin
                    counter <= counter + 1; 
                end
            end

            else 
            begin 
                if (peak_number == 2'd3)   
                begin           
                    hold <= 1'b0; // Clear hold, we are done counting
                    // No need to clear counter, it will be cleared at the start of the timer counter
                    s_m_cycle <= clk_cycle_peak_1 - clk_cycle_peak_0 ;
                    M_m_cycle <= clk_cycle_peak_2 - clk_cycle_peak_0 ;
                    counter <= counter + 1; 
                end
                else 
                begin           
                    counter <= counter + 1; 
                end
            end
        end
    end

    assign m_axis_sm_cycle_tvalid = 1'b1;
    assign m_axis_Mm_cycle_tvalid = 1'b1;

    assign m_axis_sm_cycle_tdata = s_m_cycle ;
    assign m_axis_Mm_cycle_tdata = M_m_cycle ;

endmodule
