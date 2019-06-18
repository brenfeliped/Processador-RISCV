`ifndef PARAM
	`include "../Parametros.v"
`endif

//*
// * Bloco de Controle UNICICLO
// *
 

 module Control_UNI(
    input  [31:0] iInstr,
	 input         iExceptionLoad,
	 input         iExceptionStore,
	 input         iOutText,
	 input         iOutData,
	 input         iPcMisaligned,
    output    	 	oOrigAULA, 
	 output 			oOrigBULA, 
	 output			oRegWrite, 
	 output			oMemWrite, 
	 output			oMemRead,
	 output        oPcOrUtvec,   // sinal de controle para escolher PC ou Utvec
	 output        oCSRWrite,    // sinal para escrita no banco de registradores CSR 
	 output [31:0] oUcause,      // valor para ser gravado no Ucause
	 output  [1:0] oSelectNumRegCSR,  // sinal de selecao do numero do registrador csr
	 output  [2:0] oOrigWriteDataCSR, // sinal para selecao do dado a ser excrito em CSR
	 output        oEbreak,
	 output [ 1:0]	oMem2Reg, 
	 output [ 1:0]	oOrigPC,
	 output [ 4:0] oALUControl
`ifdef RV32IMF
	 ,
	 output       oFRegWrite,    // Controla a escrita no FReg
	 output [4:0] oFPALUControl, // Controla a operacao a ser realizda pela FPULA
	 output       oOrigAFPALU,   // Controla se a entrada A da FPULA  float ou int
	 output       oFPALU2Reg,    // Controla a escrita no registrador de inteiros (origem FPULA ou nao?)
	 output       oFWriteData,   // Controla a escrita nos FRegisters (origem FPALU(0) : origem memoria(1)?)
	 output       oWrite2Mem,     // Controla a escrita na memoria (origem Register(0) : FRegister(1))
	 output		  oFPstart			// controla/liga a FPULA
`endif
);


wire [6:0] Opcode = iInstr[ 6: 0];
wire [2:0] Funct3	= iInstr[14:12];
wire [6:0] Funct7	= iInstr[31:25];
wire       immEbreak = iInstr[20];
//`ifdef RV32IMF
wire [4:0] Rs2    = iInstr[24:20]; // Para os converts de ponto flutuante e instrucao URET
//`endif


always @(*)
if(iOutText == 1)
begin
            oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b0;
				oRegWrite	<= 1'b0;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPNULL;
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oPcOrUtvec  <= 1'b1; // *add to CSR registers*
				oCSRWrite   <= 1'b1; // *add to CSR registers*
				oUcause     <= 32'h00000001;  // *add to CSR registers*
				oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*
				oEbreak <= 1'b0;
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
end
else
begin
	if(iPcMisaligned)		   
	begin         // exercao de endereco de instrucao desaliado
		oOrigAULA  	<= 1'b0;
		oOrigBULA 	<= 1'b0;
		oRegWrite	<= 1'b0;
		oMemWrite	<= 1'b0; 
		oMemRead 	<= 1'b0; 
		oALUControl	<= OPNULL;
		oMem2Reg 	<= 2'b00;
		oOrigPC		<= 2'b00;
		oPcOrUtvec  <= 1'b1; // *add to CSR registers*
		oCSRWrite   <= 1'b1; // *add to CSR registers*
		oUcause     <= 32'h00000000;  // *add to CSR registers*
		oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
		oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*
		oEbreak <= 1'b0;
	end
else
begin	
	case(Opcode)
		OPC_CSR:
			begin
			oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
		   oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
			oOrigAULA  	<= 1'b0; 
			oOrigBULA 	<= 1'b0; 
			oRegWrite	<= 1'b0; 
			oMemWrite	<= 1'b0; 
			oMemRead 	<= 1'b0; 
			oALUControl	<= OPNULL;
			oOrigPC		<= 2'b00; 
			oUcause     <= 32'h0000000F; // codigo de instrucao CSR
			oEbreak <= 1'b0;
				case(Funct3)
					FUNCT3_ECALL:
						begin
							if(immEbreak == 1'b1)
							begin
								oEbreak <= 1'b1;
								oPcOrUtvec  <= 1'b0; // *add to CSR registers*
								oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
								oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
								oOrigAULA  	<= 1'b0; 
								oOrigBULA 	<= 1'b0; 
								oRegWrite	<= 1'b0; 
								oMemWrite	<= 1'b0; 
								oMemRead 	<= 1'b0; 
								oALUControl	<= OPNULL;
								oCSRWrite   <= 1'b0; // *add to CSR registers*
								oOrigPC		<= 2'b00; //depende de cada instrucao
								oUcause     <= 32'h00000000;
							end
							else
							begin
								if(Rs2 == 5'b00010) // instrucao URET
								begin
									oPcOrUtvec  <= 1'b1; // *add to CSR registers*
									oSelectNumRegCSR <= 2'b10;      // *add to CSR registers*
									oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
									oOrigAULA  	<= 1'b0; 
									oOrigBULA 	<= 1'b0; 
									oRegWrite	<= 1'b0; 
									oMemWrite	<= 1'b0; 
									oMemRead 	<= 1'b0; 
									oALUControl	<= OPNULL;
									oCSRWrite   <= 1'b0; // *add to CSR registers*
									oOrigPC		<= 2'b00; //depende de cada instrucao
									oUcause     <= 32'h00000000;
								end
								else
								begin
									oPcOrUtvec  <= 1'b1; // *add to CSR registers*
									oRegWrite	<= 1'b0;
									oMem2Reg 	<= 2'b00;
									oCSRWrite   <= 1'b1; // *add to CSR registers*
									oUcause     <= 32'h00000008;  // *add to CSR registers*
									oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
									oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*
								end
							end	
						end
					FUNCT3_CSRRW:
						begin
							oPcOrUtvec  <= 1'b0; // *add to CSR registers*
							oRegWrite	<= 1'b1;
							oMem2Reg 	<= 2'b11;
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oSelectNumRegCSR <= 2'b00;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b011;    // *add to CSR registers*
						end
					FUNCT3_CSRRS:
					    begin
							oPcOrUtvec  <= 1'b0; // *add to CSR registers*
							oRegWrite	<= 1'b1;
							oMem2Reg 	<= 2'b11;
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oSelectNumRegCSR <= 2'b00;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b100;    // *add to CSR registers*
						 end
					FUNCT3_CSRRC:
					    begin
							oPcOrUtvec  <= 1'b0; // *add to CSR registers*
							oRegWrite	<= 1'b1;
							oMem2Reg 	<= 2'b11;
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oSelectNumRegCSR <= 2'b00;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b101;    // *add to CSR registers*
						 end
					FUNCT3_CSRRWI:
					    begin
							oPcOrUtvec  <= 1'b0; // *add to CSR registers*
							oRegWrite	<= 1'b1;
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oSelectNumRegCSR <= 2'b00;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
						 end
					FUNCT3_CSRRSI:
					   begin
							oPcOrUtvec  <= 1'b0; // *add to CSR registers*
							oRegWrite	<= 1'b1;
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oSelectNumRegCSR <= 2'b00;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b110;    // *add to CSR registers*
						end
					FUNCT3_CSRRCI:
					   begin
							oPcOrUtvec  <= 1'b0; // *add to CSR registers*
							oRegWrite	<= 1'b1;
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oSelectNumRegCSR <= 2'b00;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b111;    // *add to CSR registers*
						end
				endcase
			end
		OPC_LOAD:
			begin
				oEbreak <= 1'b0;
				oOrigAULA	<= 1'b0;
				oOrigBULA 	<= 1'b1;
				//oRegWrite	<= 1'b1; depende do aliamento do load
				//oMemWrite	<= 1'b0; depende do aliamento do load 
				//oMemRead 	<= 1'b1; depende do aliamento do load
				oALUControl	<= OPADD;
				oMem2Reg 	<= 2'b10;
				oOrigPC		<= 2'b00;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
				oUcause     <= 32'h00000000;
				if(iOutData != 1)
				begin
				      if(iExceptionLoad != 1)
						begin
						   oRegWrite	<= 1'b1;
							oMemWrite	<= 1'b0;
							oMemRead 	<= 1'b1; 
							oPcOrUtvec  <=  1'b0; 
							oCSRWrite   <=  1'b0;
							oUcause     <= 32'h00000000;
						end
						else
						begin
						   oRegWrite	<= 1'b0;
							oMemWrite	<= 1'b0;
							oMemRead 	<= 1'b0; 
							oPcOrUtvec  <= 1'b1; // *add to CSR registers*
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oUcause     <= 32'h00000004;  // *add to CSR registers*
							oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*
						end
				end
				else
				begin
				      oRegWrite	<= 1'b0;
						oMemWrite	<= 1'b0;
						oMemRead 	<= 1'b0;
						oPcOrUtvec  <= 1'b1; // *add to CSR registers*
				      oCSRWrite   <= 1'b1; // *add to CSR registers*
				      oUcause     <= 32'h00000005;  // *add to CSR registers*
				      oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
				      oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*	
				end
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
		OPC_OPIMM:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b1;
				oRegWrite	<= 1'b1;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0; 
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers* 
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
				case (Funct3)
					FUNCT3_ADD:			oALUControl <= OPADD;
					FUNCT3_SLL:			oALUControl <= OPSLL;
					FUNCT3_SLT:			oALUControl <= OPSLT;
					FUNCT3_SLTU:		oALUControl	<= OPSLTU;
					FUNCT3_XOR:			oALUControl <= OPXOR;
					FUNCT3_SRL,
					FUNCT3_SRA:
						if(Funct7==FUNCT7_SRA)  oALUControl <= OPSRA;
						else 							oALUControl <= OPSRL;
					FUNCT3_OR:			oALUControl <= OPOR;
					FUNCT3_AND:			oALUControl <= OPAND;	
					default: // instrucao invalida
						begin
							oEbreak <= 1'b0;
							oOrigAULA  	<= 1'b0;
							oOrigBULA 	<= 1'b0;
							oRegWrite	<= 1'b0;
							oMemWrite	<= 1'b0; 
							oMemRead 	<= 1'b0; 
							oALUControl	<= OPNULL;
							oMem2Reg 	<= 2'b00;
							oOrigPC		<= 2'b00;
							oPcOrUtvec  <= 1'b1; // *add to CSR registers*
							oCSRWrite   <= 1'b1; // *add to CSR registers*
							oUcause     <= 32'h00000002;  // *add to CSR registers*
							oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
`ifdef RV32IMF
							oFPALU2Reg    <= 1'b0;
							oFPALUControl <= OPNULL;
							oFRegWrite    <= 1'b0;
							oOrigAFPALU   <= 1'b0;
							oFWriteData   <= 1'b0;
							oWrite2Mem    <= 1'b0;
							oFPstart		  <= 1'b0;
`endif
						end				
				endcase
			end
			
		OPC_AUIPC:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b1;
				oOrigBULA 	<= 1'b1;
				oRegWrite	<= 1'b1;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPADD;
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
			
		OPC_STORE:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b1;
				oRegWrite	<= 1'b0;
				oMemWrite	<= 1'b1; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPADD;
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
		      oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
				if(iOutData!= 1)
				begin
					if(iExceptionStore != 1)
					begin
						oPcOrUtvec  <= 1'b0; 
						oCSRWrite   <= 1'b0;
					end
					else
					begin
						oPcOrUtvec  <= 1'b1; // *add to CSR registers*
						oCSRWrite   <= 1'b1; // *add to CSR registers*
						oUcause     <= 32'h00000006;  // *add to CSR registers*
						oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
						oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*
					end
				end
				else
					oPcOrUtvec  <= 1'b1; // *add to CSR registers*
				   oCSRWrite   <= 1'b1; // *add to CSR registers*
				   oUcause     <= 32'h00000007;  // *add to CSR registers*
				   oSelectNumRegCSR <= 2'b01;     // *add to CSR registers*
				   oOrigWriteDataCSR <= 3'b001;    // *add to CSR registers*
				begin
					
				end
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
		
		OPC_RTYPE:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b0;
				oRegWrite	<= 1'b1;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			case (Funct7)
				FUNCT7_ADD,  // ou qualquer outro 7'b0000000
				FUNCT7_SUB:	 // SUB ou SRA			
					case (Funct3)
						FUNCT3_ADD,
						FUNCT3_SUB:
							if(Funct7==FUNCT7_SUB)   oALUControl <= OPSUB;
							else 							 oALUControl <= OPADD;
						FUNCT3_SLL:			oALUControl <= OPSLL;
						FUNCT3_SLT:			oALUControl <= OPSLT;
						FUNCT3_SLTU:		oALUControl	<= OPSLTU;
						FUNCT3_XOR:			oALUControl <= OPXOR;
						FUNCT3_SRL,
						FUNCT3_SRA:
							if(Funct7==FUNCT7_SRA)  oALUControl <= OPSRA;
							else 							oALUControl <= OPSRL;
						FUNCT3_OR:			oALUControl <= OPOR;
						FUNCT3_AND:			oALUControl <= OPAND;
						default: // instrucao invalida
							begin
								oEbreak <= 1'b0;
								oOrigAULA  	<= 1'b0;
								oOrigBULA 	<= 1'b0;
								oRegWrite	<= 1'b0;
								oMemWrite	<= 1'b0; 
								oMemRead 	<= 1'b0; 
								oALUControl	<= OPNULL;
								oMem2Reg 	<= 2'b00;
								oOrigPC		<= 2'b00;
								oPcOrUtvec  <= 1'b1; 
							   oCSRWrite   <= 1'b1;
								oUcause     <= 32'h00000002;  // *add to CSR registers*
								oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							   oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
`ifdef RV32IMF
								oFPALU2Reg    <= 1'b0;
								oFPALUControl <= OPNULL;
								oFRegWrite    <= 1'b0;
								oOrigAFPALU   <= 1'b0;
								oFWriteData   <= 1'b0;
								oWrite2Mem    <= 1'b0;
								oFPstart		  <= 1'b0;
`endif
							end				
					endcase

`ifndef RV32I					
				FUNCT7_MULDIV:	
					case (Funct3)
						FUNCT3_MUL:			oALUControl <= OPMUL;
						FUNCT3_MULH:		oALUControl <= OPMULH;
						FUNCT3_MULHSU:		oALUControl <= OPMULHSU;
						FUNCT3_MULHU:		oALUControl <= OPMULHU;
						FUNCT3_DIV:			oALUControl <= OPDIV;
						FUNCT3_DIVU:		oALUControl <= OPDIVU;
						FUNCT3_REM:			oALUControl <= OPREM;
						FUNCT3_REMU:		oALUControl <= OPREMU;	
						default: // instrucao invalida
							begin
								oEbreak <= 1'b0;
								oOrigAULA  	<= 1'b0;
								oOrigBULA 	<= 1'b0;
								oRegWrite	<= 1'b0;
								oMemWrite	<= 1'b0; 
								oMemRead 	<= 1'b0; 
								oALUControl	<= OPNULL;
								oMem2Reg 	<= 2'b00;
								oOrigPC		<= 2'b00;
								oPcOrUtvec  <= 1'b1; 
							   oCSRWrite   <= 1'b1;
								oUcause     <= 32'h00000002;  // *add to CSR registers*
								oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							   oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
`ifdef RV32IMF
								oFPALU2Reg    <= 1'b0;
								oFPALUControl <= OPNULL;
								oFRegWrite    <= 1'b0;
								oOrigAFPALU   <= 1'b0;
								oFWriteData   <= 1'b0;
								oWrite2Mem    <= 1'b0;
								oFPstart		  <= 1'b0;
`endif
							end				
					endcase
`endif			
				default: // instrucao invalida
					begin
						oEbreak <= 1'b0;
						oOrigAULA  	<= 1'b0;
						oOrigBULA 	<= 1'b0;
						oRegWrite	<= 1'b0;
						oMemWrite	<= 1'b0; 
						oMemRead 	<= 1'b0; 
						oALUControl	<= OPNULL;
						oMem2Reg 	<= 2'b00;
						oOrigPC		<= 2'b00;
						oPcOrUtvec  <= 1'b1; 
						oCSRWrite   <= 1'b1;
						oUcause     <= 32'h00000002;  // *add to CSR registers*
						oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
						oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
`ifdef RV32IMF
						oFPALU2Reg    <= 1'b0;
						oFPALUControl <= OPNULL;
						oFRegWrite    <= 1'b0;
						oOrigAFPALU   <= 1'b0;
						oFWriteData   <= 1'b0;
						oWrite2Mem    <= 1'b0;
						oFPstart		  <= 1'b0;
`endif
					end				
			endcase			
		end
		
		OPC_LUI:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b1;
				oRegWrite	<= 1'b1;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPLUI;
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
			
		OPC_BRANCH:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b0;
				oRegWrite	<= 1'b0;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPADD;
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b01;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
			
		OPC_JALR:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b0;
				oRegWrite	<= 1'b1;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPADD;
				oMem2Reg 	<= 2'b01;
				oOrigPC		<= 2'b11;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
		
		OPC_JAL:
			begin
				oEbreak <= 1'b0;
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b0;
				oRegWrite	<= 1'b1;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPADD;
				oMem2Reg 	<= 2'b01;
				oOrigPC		<= 2'b10;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
			end
			
`ifdef RV32IMF
		OPC_FRTYPE: // OPCODE de todas as intruções tipo R ponto flutuante
			begin
				oEbreak <= 1'b0;
				oOrigAULA   <= 1'b0;   // Importam as entradas da ULA?
				oOrigBULA   <= 1'b0;	  // Importam as entradas da ULA?
				oMemWrite	<= 1'b0;   // Nao escreve na memoria
				oMemRead 	<= 1'b0;   // Nao le da memoria
				oALUControl	<= OPNULL; // Nao realiza operacoes na ULA
				oMem2Reg 	<= 2'b00;  // Nao importa o que sera escrito do mux mem2reg?
				oOrigPC		<= 2'b00;  // PC+4
				oFWriteData <= 1'b0;   // Instrucoes do tipo R sempre escrevem no banco de registradores a partir do resultado da FPALU
				oWrite2Mem  <= 1'b0;   // Instrucoes do tipo R nao escrevem na memoria
				oFPstart		<= 1'b1;		// habilita a FPULA
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
				case(Funct7)
					FUNCT7_FADD_S:
						begin
							oRegWrite     <= 1'b0;   // Nao habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b0;   // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPADD; // Realiza um fadd
							oFRegWrite    <= 1'b1;   // Habilita escrita no registrador de float
							oOrigAFPALU   <= 1'b1;   // Rs1 eh um float 
						end

					FUNCT7_FSUB_S:
						begin
							oRegWrite     <= 1'b0;   // Nao habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b0;   // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPSUB; // Realiza um fsub
							oFRegWrite    <= 1'b1;   // Habilita escrita no registrador de float
							oOrigAFPALU   <= 1'b1;   // Rs1 eh um float 
						end
						
					FUNCT7_FMUL_S:
						begin
							oRegWrite     <= 1'b0;   // Nao habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b0;   // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPMUL; // Realiza um fmul
							oFRegWrite    <= 1'b1;   // Habilita escrita no registrador de float
							oOrigAFPALU   <= 1'b1;   // Rs1 eh um float 
						end
					
					FUNCT7_FDIV_S:
						begin
							oRegWrite     <= 1'b0;   // Nao habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b0;   // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPDIV; // Realiza um fdiv
							oFRegWrite    <= 1'b1;   // Habilita escrita no registrador de float
							oOrigAFPALU   <= 1'b1;   // Rs1 eh um float 
						end
						
					FUNCT7_FSQRT_S: // OBS.: Rs2 nao importa?
						begin
							oRegWrite     <= 1'b0;   // Nao habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b0;   // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPSQRT; // Realiza um fsqrt
							oFRegWrite    <= 1'b1;   // Habilita escrita no registrador de float
							oOrigAFPALU   <= 1'b1;   // Rs1 eh um float 
						end
						
					FUNCT7_FMV_S_X:
						begin
							oRegWrite     <= 1'b0;      // Nao habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b0;      // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPMV;     // Realiza um fmv.s.x
							oFRegWrite    <= 1'b1;      // Habilita escrita no registrador de float
							oOrigAFPALU   <= 1'b0;      // Rs1 eh um int 
						end
						
					FUNCT7_FMV_X_S:
						begin
							oRegWrite     <= 1'b1;      // Habilita escrita em registrador de inteiros 
							oFPALU2Reg    <= 1'b1;      // Nao importa o que escreve em registrador de inteiros
							oFPALUControl <= FOPMV;     // Realiza um fmv.x.s
							oFRegWrite    <= 1'b0;      // Desabilita escrita no registrador de float
							oOrigAFPALU   <= 1'b1;      // Rs1 eh um float 
						end
						
					FUNCT7_FSIGN_INJECT:
						begin
							oRegWrite     <= 1'b0;
							oFPALU2Reg    <= 1'b0;
							oFRegWrite    <= 1'b1;
							oOrigAFPALU   <= 1'b1;
							case (Funct3)
								FUNCT3_FSGNJ_S:  oFPALUControl <= FOPSGNJ;
								FUNCT3_FSGNJN_S: oFPALUControl <= FOPSGNJN;
								FUNCT3_FSGNJX_S: oFPALUControl <= FOPSGNJX;
								default: // instrucao invalida
									begin
										oOrigAULA  	  <= 1'b0;
										oOrigBULA 	  <= 1'b0;
										oRegWrite	  <= 1'b0;
										oMemWrite	  <= 1'b0; 
										oMemRead 	  <= 1'b0; 
										oALUControl	  <= OPNULL;
										oMem2Reg 	  <= 2'b00;
										oOrigPC		  <= 2'b00;
										oFPALU2Reg    <= 1'b0;
										oFPALUControl <= OPNULL;
										oFRegWrite    <= 1'b0;
										oOrigAFPALU   <= 1'b0;
										oFWriteData   <= 1'b0;
										oWrite2Mem    <= 1'b0;
										oPcOrUtvec  <= 1'b1; 
									   oCSRWrite   <= 1'b1;
										oUcause     <= 32'h00000002;  // *add to CSR registers*
										oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							         oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
									end
							endcase
						end
						
					FUNCT7_MAX_MIN_S:
						begin
							oRegWrite     <= 1'b0;
							oFPALU2Reg    <= 1'b0;
							oFRegWrite    <= 1'b1;
							oOrigAFPALU   <= 1'b1;
							case (Funct3)
								FUNCT3_FMAX_S: oFPALUControl <= FOPMAX;
								FUNCT3_FMIN_S: oFPALUControl <= FOPMIN;
								default: // instrucao invalida
									begin
										oOrigAULA  	  <= 1'b0;
										oOrigBULA 	  <= 1'b0;
										oRegWrite	  <= 1'b0;
										oMemWrite	  <= 1'b0; 
										oMemRead 	  <= 1'b0; 
										oALUControl	  <= OPNULL;
										oMem2Reg 	  <= 2'b00;
										oOrigPC		  <= 2'b00;
										oFPALU2Reg    <= 1'b0;
										oFPALUControl <= OPNULL;
										oFRegWrite    <= 1'b0;
										oOrigAFPALU   <= 1'b0;
										oFWriteData   <= 1'b0;
										oWrite2Mem    <= 1'b0;
										oPcOrUtvec  <= 1'b1; 
										oCSRWrite   <= 1'b1;
										oUcause     <= 32'h00000002;  // *add to CSR registers*
										oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							         oOrigWriteDataCSR <= 2'b10;    // *add to CSR registers*
									end
							endcase
						end
						
					FUNCT7_FCOMPARE:
						begin
							oRegWrite     <= 1'b1;
							oFPALU2Reg    <= 1'b1;
							oFRegWrite    <= 1'b0;
							oOrigAFPALU   <= 1'b1;
							case (Funct3)
								FUNCT3_FEQ_S: oFPALUControl <= FOPCEQ;
								FUNCT3_FLE_S: oFPALUControl <= FOPCLE;
								FUNCT3_FLT_S: oFPALUControl <= FOPCLT;
								default: // instrucao invalida
									begin
										oOrigAULA  	  <= 1'b0;
										oOrigBULA 	  <= 1'b0;
										oRegWrite	  <= 1'b0;
										oMemWrite	  <= 1'b0; 
										oMemRead 	  <= 1'b0; 
										oALUControl	  <= OPNULL;
										oMem2Reg 	  <= 2'b00;
										oOrigPC		  <= 2'b00;
										oFPALU2Reg    <= 1'b0;
										oFPALUControl <= OPNULL;
										oFRegWrite    <= 1'b0;
										oOrigAFPALU   <= 1'b0;
										oFWriteData   <= 1'b0;
										oWrite2Mem    <= 1'b0;
										oPcOrUtvec  <= 1'b1; 
										oCSRWrite   <= 1'b1;
										oUcause     <= 32'h00000002;
										oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							         oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
									end
							endcase
						end
						
					FUNCT7_FCVT_S_W_WU:
						begin
							oRegWrite     <= 1'b0;
							oFPALU2Reg    <= 1'b0;
							oFRegWrite    <= 1'b1;
							oOrigAFPALU   <= 1'b0;
							case (Rs2)
								RS2_FCVT_S_W:  oFPALUControl <= FOPCVTSW;
								RS2_FCVT_S_WU: oFPALUControl <= FOPCVTSWU;
								default: // instrucao invalida
									begin
										oOrigAULA  	  <= 1'b0;
										oOrigBULA 	  <= 1'b0;
										oRegWrite	  <= 1'b0;
										oMemWrite	  <= 1'b0; 
										oMemRead 	  <= 1'b0; 
										oALUControl	  <= OPNULL;
										oMem2Reg 	  <= 2'b00;
										oOrigPC		  <= 2'b00;
										oFPALU2Reg    <= 1'b0;
										oFPALUControl <= OPNULL;
										oFRegWrite    <= 1'b0;
										oOrigAFPALU   <= 1'b0;
										oFWriteData   <= 1'b0;
										oWrite2Mem    <= 1'b0;
										oPcOrUtvec  <= 1'b1; 
										oCSRWrite   <= 1'b1;
										oUcause     <= 32'h00000002;
										oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							         oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
									end
							endcase
						end
						
					FUNCT7_FCVT_W_WU_S:
						begin
							oRegWrite     <= 1'b1;
							oFPALU2Reg    <= 1'b1;
							oFRegWrite    <= 1'b0;
							oOrigAFPALU   <= 1'b1;
							case (Rs2)
								RS2_FCVT_W_S:  oFPALUControl <= FOPCVTWS;
								RS2_FCVT_WU_S: oFPALUControl <= FOPCVTWUS;
								default: // instrucao invalida
									begin
										oEbreak <= 1'b0;
										oOrigAULA  	  <= 1'b0;
										oOrigBULA 	  <= 1'b0;
										oRegWrite	  <= 1'b0;
										oMemWrite	  <= 1'b0; 
										oMemRead 	  <= 1'b0; 
										oALUControl	  <= OPNULL;
										oMem2Reg 	  <= 2'b00;
										oOrigPC		  <= 2'b00;
										oFPALU2Reg    <= 1'b0;
										oFPALUControl <= OPNULL;
										oFRegWrite    <= 1'b0;
										oOrigAFPALU   <= 1'b0;
										oFWriteData   <= 1'b0;
										oWrite2Mem    <= 1'b0;
										oPcOrUtvec  <= 1'b1; 
										oCSRWrite   <= 1'b1;
										oUcause     <= 32'h00000002;  // *add to CSR registers*
										oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							         oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
									end
							endcase
						end
						
					default: // instrucao invalida
					  begin
							oEbreak <= 1'b0;
							oOrigAULA  	  <= 1'b0;
							oOrigBULA 	  <= 1'b0;
							oRegWrite	  <= 1'b0;
							oMemWrite	  <= 1'b0; 
							oMemRead 	  <= 1'b0; 
							oALUControl	  <= OPNULL;
							oMem2Reg 	  <= 2'b00;
							oOrigPC		  <= 2'b00;
							oFPALU2Reg    <= 1'b0;
							oFPALUControl <= OPNULL;
							oFRegWrite    <= 1'b0;
							oOrigAFPALU   <= 1'b0;
							oFWriteData   <= 1'b0;
							oWrite2Mem    <= 1'b0;
							oFPstart		  <= 1'b0;
							oPcOrUtvec  <= 1'b1; 
							oCSRWrite   <= 1'b1;
							oUcause     <= 32'h00000002;  // *add to CSR registers*
							oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
							oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
					  end
						
				endcase				
			end
			
		OPC_FLOAD: //OPCODE do FLW
			begin
				// Sinais int
				oOrigAULA	  <= 1'b0;
				oOrigBULA 	  <= 1'b1;
				oRegWrite	  <= 1'b0;
				oMemWrite	  <= 1'b0; 
				oMemRead 	  <= 1'b1; 
				oALUControl	  <= OPADD;
				oMem2Reg 	  <= 2'b10;
				oOrigPC		  <= 2'b00;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
				// Sinais float
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b1;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b1;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
			end
			
		OPC_FSTORE:
			begin
				// Sinais int
				oOrigAULA  	  <= 1'b0;
				oOrigBULA 	  <= 1'b1;
				oRegWrite	  <= 1'b0;
				oMemWrite	  <= 1'b1; 
				oMemRead 	  <= 1'b0; 
				oALUControl	  <= OPADD;
				oMem2Reg 	  <= 2'b00;
				oOrigPC		  <= 2'b00;
				oPcOrUtvec  <= 1'b0; 
				oCSRWrite   <= 1'b0;
				oUcause     <= 32'h00000000;
				oSelectNumRegCSR <= 2'b00;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b000;    // *add to CSR registers*
				// Sinais float
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b1;
				oFPstart		  <= 1'b0;
			end
		
`endif
      
		default: // instrucao invalida
        begin
				oOrigAULA  	<= 1'b0;
				oOrigBULA 	<= 1'b0;
				oRegWrite	<= 1'b0;
				oMemWrite	<= 1'b0; 
				oMemRead 	<= 1'b0; 
				oALUControl	<= OPNULL;
				oMem2Reg 	<= 2'b00;
				oOrigPC		<= 2'b00;
				oPcOrUtvec  <= 1'b1; 
				oCSRWrite   <= 1'b1;
				oUcause     <= 32'h00000002;  // *add to CSR registers*
				oSelectNumRegCSR <= 2'b01;      // *add to CSR registers*
				oOrigWriteDataCSR <= 3'b010;    // *add to CSR registers*
`ifdef RV32IMF
				oFPALU2Reg    <= 1'b0;
				oFPALUControl <= OPNULL;
				oFRegWrite    <= 1'b0;
				oOrigAFPALU   <= 1'b0;
				oFWriteData   <= 1'b0;
				oWrite2Mem    <= 1'b0;
				oFPstart		  <= 1'b0;
`endif
        end
		  
	endcase

end
end
endmodule
