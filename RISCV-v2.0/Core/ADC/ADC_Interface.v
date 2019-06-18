module ADC_Interface(
    input         iCLK_50,
    input         iCLK,
    input         Reset,
    inout         ADC_CS_N,
    output        ADC_DIN,
    input         ADC_DOUT,
    output        ADC_SCLK,
    //  Barramento de IO
    input         wReadEnable, wWriteEnable,
    input  [3:0]  wByteEnable,
    input  [31:0] wAddress, wWriteData,
    output [31:0] wReadData
);

wire [11:0] ch[7:0];

ADC_Controller ADC0(
	.CLOCK(iCLK_50),   
	.RESET(Reset),   
	.CH0(ch[0]),     
	.CH1(ch[1]),     
	.CH2(ch[2]),     
	.CH3(ch[3]),     
	.CH4(ch[4]),     
	.CH5(ch[5]),     
	.CH6(ch[6]),     
	.CH7(ch[7]),     
	.ADC_SCLK(ADC_SCLK),
	.ADC_CS_N(ADC_CS_N),
	.ADC_DOUT(ADC_DOUT),
	.ADC_DIN(ADC_DIN)
);

reg [31:0] r[7:0];

always @(posedge iCLK) begin
  r[0] <= {20'b0,ch[0]};
  r[1] <= {20'b0,ch[1]};
  r[2] <= {20'b0,ch[2]};
  r[3] <= {20'b0,ch[3]};
  r[4] <= {20'b0,ch[4]};
  r[5] <= {20'b0,ch[5]};
  r[6] <= {20'b0,ch[6]};
  r[7] <= {20'b0,ch[7]};
end

always @(*)
begin
  if(wReadEnable)
    case(wAddress)
	   ADC_CH0_ADDRESS: wReadData <= r[0];
		ADC_CH1_ADDRESS: wReadData <= r[1];
		ADC_CH2_ADDRESS: wReadData <= r[2];
		ADC_CH3_ADDRESS: wReadData <= r[3];
	   ADC_CH4_ADDRESS: wReadData <= r[4];
		ADC_CH5_ADDRESS: wReadData <= r[5];
		ADC_CH6_ADDRESS: wReadData <= r[6];
		ADC_CH7_ADDRESS: wReadData <= r[7];
		default: wReadData <= 32'hzzzzzzzz;
	 endcase
  else wReadData <= 32'hzzzzzzzz;
end

endmodule



