//Rana_Odeh_1201750
//alu code 
//defined each operation by its name to make the code clearer
`define ADD 6'h8
`define SUB 6'h9
`define absolute_a  6'h2
`define minus_a 6'hA
`define max 6'hC 
`define min 6'h1
`define avg 6'hD
`define NOT 6'h5
`define OR 6'h4
`define AND 6'hB
`define XOR 6'hF

module alu (opcode, a, b, result);
    input [5:0]  opcode;
    input signed [31:0]  a, b;
    output reg signed [31:0] result;

     always@(opcode)
    begin
        case (opcode) 
            `ADD        : result = a + b;
            `SUB        : result = a - b;
            `absolute_a : if (a < 0) result = -a; else result = a;
            `minus_a    : result = -a;
            `max        : if (a > b) result = a; else result = b;
            `min        : if (a < b) result = a; else result = b;
            `avg        : result = (a + b) /2 ;  
            `NOT        : result = ~a;
            `OR         : result = a | b;
            `AND        : result = a & b;
            `XOR        : result = a ^ b;
            default     : result = 32'h0000; 
        endcase
    end
endmodule
//reg file code
module reg_file (clk, valid_opcode, addr1, addr2, addr3, in , out1, out2);
input clk;
input valid_opcode;
input [4:0] addr1, addr2, addr3;
input signed [31:0] in;
output reg signed [31:0] out1, out2; 
//Initialized values  determined by the second-from-last digit of my ID
reg [31:0] mem [31:0]='{32'h000, 32'h2208, 32'hDB0,32'h2BCC,32'h952,32'hCE4,32'hD12,32'h29E2,32'h2DB4,
32'h1B06,32'h341C,32'h2156,32'h11CE,32'h1FBA,32'h506,32'h1288,32'h10CC,32'h104C,32'h0A6E,32'h3C40,
32'h0930,32'h15FE,32'h396E,32'h1446,32'h1E8C,32'h25F4,32'h303A,32'h3D44,32'h1C8C,32'h14E4,32'h2E9A,32'h000}; 	

always @(posedge clk) 
    begin		
      if (valid_opcode) begin//To check if the operation is among the 11 permitted operations
        out1 <= mem[addr1];	// Read data from memory using addr1
        out2 <= mem[addr2]; // Read data from memory using addr2
        mem[addr3] <= in; // Write input data to memory at addr3
      end
    end
endmodule 
//Machine_instructions code 
module Machine_instructions (clk,instruction,opcode,V_in,addr1, addr2, addr3);
input clk;
input [31:0] instruction;	
output reg [5:0] opcode;
output reg [4:0] addr1, addr2,addr3; 
output reg V_in;
always @(posedge clk ) begin
    opcode <= instruction[5:0];//extract opcode from instruction
    addr1 <= instruction[10:6];	//extract addr1 from instruction
    addr2 <= instruction[15:11];//extract addr2 from instruction
    addr3 <= instruction[20:16];//extract addr3 from instruction 
	// Check if the opcode valid
	if (opcode == 6'h8 || opcode == 6'h9 || opcode == 6'h2 || opcode == 6'hA || opcode == 6'hC || 
		opcode == 6'h1 || opcode == 6'hD || opcode == 6'h5 || opcode == 6'h4 || opcode == 6'hB || opcode == 6'hF)
        V_in = 1'b1;
    else
        V_in = 1'b0;
end
 endmodule	
 //mp_top code
module mp_top (clk, instruction, result);
  input clk;
  input [31:0] instruction;
  output reg [31:0] result; 
  wire [5:0] opc; 
  reg [5:0] opcode;
  wire [4:0] add1, add2, add3;
  wire V_in;
  wire [31:0] out1, out2;

   Machine_instructions C1 (clk, instruction, opc,V_in, add1, add2, add3);
  reg_file C2 (clk, V_in, add1, add2, add3, result, out1, out2); 
  // D-FF is used to delay opcode from entering to alu 
  always @(posedge clk) begin
	   if (V_in)begin
    opcode <= opc;
	 end
  end 
  alu C4 (opcode, out1, out2, result);
endmodule
		   
//test
module Test_Bench;
    reg clk; 
	 // Define an array of 12 32-bit instructions for testing
    reg [31:0] instructions [0:11] = '{32'h119C8,32'h819C9,32'hC19C2,32'hC19CA,32'hB19CC,32'h1C19C1,
	32'h1A19CE,32'hF19CD,32'h1D19C5,32'h1619C4,32'h1719CB,32'h1819CF}; 	
	// Define an array of expected results corresponding to each instruction
    reg [31:0] expected_result [0:11] = '{32'h00003b18,32'h00000200,32'h00001e8c,32'hffffe174,
	32'h00001e8c,32'h00001c8c,32'hxxxxxxxx,32'h00001d8c,32'hffffe173,32'h00001e8c,32'h00001c8c,32'h00000200};
	wire [31:0] result [0:11]; 
	// Define an array of operation names corresponding to each instruction
    string op [0:11] ='{"add","sub","abs","neg","max","min","move","avg","not","and","or","xor"};
    integer index; 											   
    integer test=0;// Variable to track tests pass/fail status
//______________________________________________________________		
genvar i;
generate
     for (i = 0; i < 12; i = i + 1) begin : microprocessor
      mp_top testv (clk, instructions[i], result[i]);
	 end
endgenerate
//______________________________________________________________	
initial begin
	clk = 0;
	repeat(100) #5ns clk = ~clk;
end	 
//______________________________________________________________		 
initial begin
	for (index = 0; index < 12; index = index + 1) begin 
		//Wait 30 seconds for the process to complete
		#30ns
		if (result[index] !== expected_result[index]) begin
			// Display information for failed 
			$display("%-4s r%-2d r%-2d r%-2d | instruction = %h | result = %h | expected_result = %h | fail ",op[index], instructions[index][20:16], instructions[index][15:11], instructions[index][10:6], instructions[index], result[index], expected_result[index]);

			test = 1;//Changed the value of the 'test' flag to 1 to indicate test fails
         end
	else begin 	
		// Display information for passed 
		$display("%-4s r%-2d r%-2d r%-2d | instruction = %h | result = %h | expected_result = %h | pass ",op[index], instructions[index][20:16], instructions[index][15:11], instructions[index][10:6], instructions[index], result[index], expected_result[index]);	
	end
   end
	if (test ==1)begin
		$display("\n______________________________test fails__________________________\n");
		$finish;										  
		end
	else begin
		$display("\n______________________________test passes__________________________\n");
		$finish;
	 end
end
endmodule	  