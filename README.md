
Scanning Trasfer Cavity Lock implemented in Red Pitaya FPGA 

The signal processing part is based on these two papers:
https://www.semanticscholar.org/paper/Compact-implementation-of-a-scanning-transfer-lock-Burke-Garcia/0964304216c6b3d080ee94ad159c08e6b4b41c5d and 
https://www.semanticscholar.org/paper/Microcontroller-based-scanning-transfer-cavity-lock-Subhankar-Restelli/3400617bde9fcfa05268903d11fe3f83a8ecf6fa

Most of the codes are based on https://github.com/pavel-demin/red-pitaya-notes and https://github.com/apotocnik/redpitaya_guide .

The code in this repo is for 10-bit Red Pitaya, you will need to change the codes for the 14-bit version, e.g. TDATA_REMAP in the subset converter. Hopefully it will be useful for other students doing similar things. 

In my case, 
Red Pitaya ADC inputs: in_ch_1 is photodiode signal; in_ch_2 is the scan trigger signal from the function generator for scanning the cavity piezo. 
Red Pitaya DAC output: out_ch_1 is error signal (which is sent to Toptica DLC Pro Controller for PID control).


To generate the bitstream, follow these steps:

`source /tools/Xilinx/Vitis_HLS/2020.2/settings64.sh ; vivado`

`cd to this repo in the vivdao tcl console`

`source make_cores.tcl`

`source make_project.tcl`

then you can change the code in the block diagram in vivado, e.g. default setpoint value (depends on what laser wavelength you want to lock and their time ratio), negative edge trigger level, time constraints, etc. to match your requirement.

Finally, just click `Generate bitstream` to generate bitstream file. The output file is located in `/stcl_10bit_rp/tmp/your_project_name/your_project_name.runs/impl_1/system_wrapper.bit` 

Then transfer it to the Red Pitaya and run it with `cat your_project.bit > /dev/xdevcfg`

