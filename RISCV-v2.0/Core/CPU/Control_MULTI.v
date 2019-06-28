`ifndef PARAM
	`include "../Parametros.v"
`endif

// *
// * Bloco de Controle MULTICICLO
// *
	
module Control_MULTI (

	input  			 iCLK, iRST,
	input		[31:0] iInstr,
	// inputs para exercao
	input           iOutText,
	input           iOutData,
	input           iPCMisaligned,
	input           iExceptionLoad,
	input           iExceptionStore,
	
	// outputs para excercao e instrucoes csr
	output   [31:0] oUcause,  // valor para ser gravado no Ucause
	output          oCSRWrite, // sinal para escrita no banco de registradores CSR
	output          oEscreveCRSOut, // habilita escrita no registrador CSROut
	output  [2:0]   oOrigWriteDataCSR, // sinal para selecao do dado a ser excrito em CSR
	output  [1:0]   oSelectNumRegCSR,  // sinal de selecao do numero do registrador csr
	output          oEbreak,           // sinal da instrução ebreak
	
	output 			 oEscreveIR,
	output 			 oEscrevePC,
	output 			 oEscrevePCCond,
	output 			 oEscrevePCBack,
   output 	[ 1:0] oOrigAULA,
   output 	[ 1:0] oOrigBULA,	 
   output 	[ 2:0] oMem2Reg,
	output 	[ 1:0] oOrigPC,
	output 			 oIouD,
   output 			 oRegWrite,
   output 			 oMemWrite,
	output 			 oMemRead,
	output 	[ 4:0] oALUControl,
	output   [ 5:0] oState
`ifdef RV32IMF
	,
	input           iFPALUReady,
	output          oFRegWrite,
	output   [ 4:0] oFPALUControl,
	output          oOrigAFPALU,
	output          oFPALUStart,
	output          oFWriteData,
	output          oWrite2Mem
`endif
	);


reg 	[ 5:0]  pr_state;		// present state
wire  [ 5:0]  nx_state;		// next state

wire [6:0] Opcode = iInstr[ 6: 0];
wire [2:0] Funct3	= iInstr[14:12];
wire [6:0] Funct7	= iInstr[31:25];
wire [4:0] Rs2    = iInstr[24:20]; // Para os converts de ponto flutuante e para reconhecer o URET


assign	oState	= pr_state;

reg [4:0] contador;

initial
	begin
		pr_state	<= ST_FETCH;
		contador <= 5'd0;
	end



// a cada ciclo de Clock
always @(posedge iCLK or posedge iRST)
	begin
		if (iRST)
			begin
				pr_state	<= ST_FETCH;
				contador <= 5'd0;
			end
		else
			begin
				pr_state	<= nx_state;
				if (nx_state == ST_DIVREM)
					contador <= contador + 5'd1;
				else
					contador <= 5'd0;
			end
	end



always @(*)
	case (pr_state)
		ST_FETCH:
			begin
			   oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b1;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
				
				nx_state 		<= ST_FETCH1;
			end

		ST_FETCH1:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b1;
				oEscrevePC 		<= 1'b1;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b1;
				oOrigAULA 		<= 2'b01;
				oOrigBULA 		<= 2'b01;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b1;
				oALUControl 	<= OPADD;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
				
				if(iOutText!=1 && iPCMisaligned!=1)
				begin
					nx_state <= ST_DECODE;
				end
				else
				begin
					nx_state <= ST_PCEXCEPTION;
				end
			end

		ST_PCEXCEPTION:
			begin
				if(iOutText)
				begin
					oUcause        <= 32'h00000001;
				end
				else
				begin
					oUcause        <= 32'h00000000;
				end
				oCSRWrite      <= 1'b1;
				oEscreveCRSOut <=  1'b1;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b01;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif				
				nx_state <= ST_ENDEXCEPTION;
			end
			
      ST_ENDEXCEPTION:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b1;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b11;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif
				nx_state <= ST_FETCH;
			end
			

		ST_ECALL:
			begin
				oUcause        <= 32'h00000008;
				oCSRWrite      <= 1'b1;
				oEscreveCRSOut <=  1'b1;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b01;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

				
				nx_state			<= ST_ENDEXCEPTION;	
			end
		ST_URET:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b1;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b10;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif
				nx_state			<= ST_ENDEXCEPTION;
			end
		ST_EBREAK:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b1;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif
				nx_state <= ST_FETCH; // nao era necessario definir proximo estado
			end
			
		ST_CSR:
		begin
				oUcause        <= 32'h0000000F;
				oCSRWrite      <= 1'b1;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
				case(Funct3)
					FUNCT3_CSRRW: oOrigWriteDataCSR <= 3'b001;
					FUNCT3_CSRRS: oOrigWriteDataCSR <= 3'b010;
					FUNCT3_CSRRC: oOrigWriteDataCSR <= 3'b011;
					FUNCT3_CSRRWI: oOrigWriteDataCSR <= 3'b000;
					FUNCT3_CSRRSI: oOrigWriteDataCSR <= 3'b100;
					FUNCT3_CSRRCI: oOrigWriteDataCSR <= 3'b101;
					default: oOrigWriteDataCSR <= 3'b001;
				endcase
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b100;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b1;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
				nx_state <= ST_ULAREGWRITE;
		end
		
		ST_DECODE:
			begin
				 
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b10;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPADD;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
				
				case (Opcode)
					OPC_LOAD,
					OPC_STORE:	nx_state 		<= ST_LWSW;
					OPC_RTYPE:	nx_state 		<= ST_RTYPE;
					OPC_OPIMM:	nx_state 		<= ST_IMMTYPE;
					OPC_LUI:		nx_state 		<= ST_LUI;
					OPC_AUIPC:	nx_state 		<= ST_AUIPC;
					OPC_BRANCH:	nx_state 		<= ST_BRANCH;					
					OPC_JALR:	nx_state 		<= ST_JALR;
					OPC_JAL:		nx_state 		<= ST_JAL;
					OPC_SYS:		nx_state 		<= ST_SYS;
					OPC_CSR: // CSR inst ou URET ou ECALL
						begin
							if(Funct3==3'b000) 
							begin
								 if(Funct7==FUNCT7_ECALL)
								 begin
										case(Rs2)
											RS2_ECALL: nx_state <= ST_ECALL;
											RS2_URET: nx_state <= ST_URET;
											RS2_EBREAK:nx_state <= ST_EBREAK;
											default: nx_state <= ST_ILEGALINSTRUCTION;
										endcase
								 end
								 else
								 begin
										nx_state <= ST_ILEGALINSTRUCTION;
								 end
							end
							else // CSR inst
							begin
								oCSRWrite      <= 1'b0;
								oEscreveCRSOut <=  1'b1;
								oEbreak        <=  1'b0;
								oSelectNumRegCSR<= 2'b00;
								nx_state <= ST_CSR;
							end
						end
`ifdef RV32IMF
					OPC_FRTYPE: nx_state       <= ST_FRTYPE;
					OPC_FLOAD:  nx_state       <= ST_LWSW;
					OPC_FSTORE: nx_state       <= ST_LWSW;
`endif
					default:
									nx_state 		<= ST_ILEGALINSTRUCTION;
				endcase		
			end	
		ST_EXCEPTIONLW:
			begin
				if(iOutData)
				begin
					oUcause        <= 32'h00000005;
				end
				else
				begin
					oUcause        <= 32'h00000004;
				end
				oCSRWrite      <= 1'b1;
				oEscreveCRSOut <=  1'b1;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b01;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

				
				nx_state			<= ST_ENDEXCEPTION;
			end
		ST_LWSW:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPADD;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			
				
				case (Opcode)
					OPC_LOAD:	nx_state 		<= ST_LW;
					OPC_STORE:	nx_state 		<= ST_SW;
`ifdef RV32IMF
					OPC_FLOAD:  nx_state       <= ST_FLW;
					OPC_FSTORE: nx_state       <= ST_FSW;
`endif
					default:
									nx_state 		<= ST_ILEGALINSTRUCTION;
				endcase		
			end	
	

		ST_LW:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				if(iOutData!=1)
				begin
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b1;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b1;
				oALUControl 	<= OPADD;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			

				nx_state 		<= ST_LW1;
				end
				else
				begin
					nx_state <= ST_EXCEPTIONLW;
				end
			end

		ST_LW1:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				if(iExceptionLoad != 1)
				begin
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b1;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b1;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			

				nx_state 		<= ST_LW2;
				end
				else
				begin
					nx_state <= ST_EXCEPTIONLW;
				end
			end			
			
		ST_LW2:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b010;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b1;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
				nx_state 		<= ST_FETCH;
			end
		
		ST_EXCEPTIONSW:
		begin
			if(iOutData)
				begin
					oUcause        <= 32'h00000007;
				end
				else
				begin
					oUcause        <= 32'h00000006;
				end
				oCSRWrite      <= 1'b1;
				oEscreveCRSOut <=  1'b1;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b01;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

				
				nx_state			<= ST_ENDEXCEPTION;
		end
		
		ST_SW:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				if(iOutData!=1)
				begin
					oEscreveIR 		<= 1'b0;
					oEscrevePC 		<= 1'b0;
					oEscrevePCCond <= 1'b0;
					oEscrevePCBack <= 1'b0;
					oOrigAULA 		<= 2'b00;
					oOrigBULA 		<= 2'b00;	 
					oMem2Reg 		<= 3'b000;
					oOrigPC 			<= 2'b00;
					oIouD 			<= 1'b1;
					oRegWrite 		<= 1'b0;
					oMemWrite 		<= 1'b1;
					oMemRead 		<= 1'b0;
					oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
					oFRegWrite     <= 1'b0;
					oFPALUControl  <= OPNULL;
					oOrigAFPALU    <= 1'b0;
					oFPALUStart    <= 1'b0;
					oFWriteData    <= 1'b0;
					oWrite2Mem     <= 1'b0;
`endif	
			nx_state 		<= ST_SW1;
			end
			else
			begin
				nx_state <= ST_EXCEPTIONSW;
			end
		end

		ST_SW1:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				if(iExceptionStore != 1)
				begin
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			

				nx_state 		<= ST_FETCH;
				end
				else
				begin
					nx_state <= ST_EXCEPTIONSW;
				end
			end			

		ST_RTYPE:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

						
				nx_state 		<= ST_ULAREGWRITE;
				
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
						default:// instrucao invalida
							begin 
								oALUControl 	<= OPNULL;		
								nx_state			<= ST_ILEGALINSTRUCTION;
							end			
					endcase
`ifndef RV32I										
				FUNCT7_MULDIV:
					case (Funct3)
						FUNCT3_MUL:			 oALUControl <= OPMUL; 
						FUNCT3_MULH:		 oALUControl <= OPMULH;    
						FUNCT3_MULHSU:		 oALUControl <= OPMULHSU; 
						FUNCT3_MULHU:		 oALUControl <= OPMULHU;
						FUNCT3_DIV:		begin	 oALUControl <= OPDIV;  nx_state <= ST_DIVREM; end
						FUNCT3_DIVU:	begin	 oALUControl <= OPDIVU;	nx_state <= ST_DIVREM; end
						FUNCT3_REM:		begin	 oALUControl <= OPREM;	nx_state <= ST_DIVREM; end
						FUNCT3_REMU:	begin	 oALUControl <= OPREMU;	nx_state <= ST_DIVREM; end
						default: // instrucao invalida
							begin 
								oALUControl 	<= OPNULL;		
								nx_state			<= ST_ILEGALINSTRUCTION;
							end	
					endcase				
`endif					
				default: // instrucao invalida
					begin 
						oALUControl 	<= OPNULL;		
						nx_state			<= ST_ILEGALINSTRUCTION;
					end					
			endcase
		end			


		ST_DIVREM:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			
				case (Funct3)
						FUNCT3_DIV:		oALUControl <= OPDIV;
						FUNCT3_DIVU:	oALUControl <= OPDIVU;
						FUNCT3_REM:		oALUControl <= OPREM;
						FUNCT3_REMU:	oALUControl <= OPREMU;
						default: // instrucao invalida
							begin 
								oALUControl 	<= OPNULL;		
								nx_state			<= ST_ILEGALINSTRUCTION;
							end	
				endcase			
				if(contador == 5'd6)
						nx_state 	<= ST_ULAREGWRITE;
				else
						nx_state 	<= ST_DIVREM;
			
			end
	
		ST_IMMTYPE:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

						
				nx_state 		<= ST_ULAREGWRITE;
				
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
							oALUControl 	<= OPNULL;		
							nx_state			<=ST_ILEGALINSTRUCTION;
						end				
				endcase
			end


	
		ST_ULAREGWRITE:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;
				if(Opcode==OPC_CSR) // CSR instr
				begin
					oMem2Reg 		<= 3'b100;
				end
				else
				begin
					oMem2Reg 		<= 3'b000;
				end
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b1;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	


				nx_state 		<= ST_FETCH;
			end		

		ST_LUI:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPLUI;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

						
				nx_state 		<= ST_ULAREGWRITE;
			end			
	
		ST_AUIPC:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b10;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPADD;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	


				nx_state 		<= ST_ULAREGWRITE;
			end
	
		ST_BRANCH:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b1;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b01;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			

				nx_state 		<= ST_FETCH;
			end

		ST_JAL:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b1;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;
				oMem2Reg 		<= 3'b001;
				oOrigPC 			<= 2'b01;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b1;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			

				nx_state 		<= ST_FETCH;
			end


		ST_JALR:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b1;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b10;	 
				oMem2Reg 		<= 3'b001;
				oOrigPC 			<= 2'b10;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b1;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPADD;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	
			

				nx_state 		<= ST_FETCH;
			end			

			
		
		ST_ILEGALINSTRUCTION:  // ST_ERRO: // instrucao invalida 
			begin
				oUcause        <= 32'h00000002;
				oCSRWrite      <= 1'b1;
				oEscreveCRSOut <=  1'b1;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b01;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

				
				nx_state			<= ST_ENDEXCEPTION;	// Descarta instrucoes invalidas
			end
`ifdef RV32IMF
		ST_FLW:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;     // Desabilita escrita no IR
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;     // Desabilita escrita no PCBack
				oOrigAULA 		<= 2'b00;    // OrigAULA = A (para addi)
				oOrigBULA 		<= 2'b10;	 // OrigBULA = imediato
				oMem2Reg 		<= 3'b000;    // Mem2Reg = don't care, ja que nada vai ser escrito no registrador de inteiros
				oOrigPC 			<= 2'b00;    // PC + 4
				oIouD 			<= 1'b1;     // Endereco que entra na memoria vem da ULA, nao de PC
				oRegWrite 		<= 1'b0;     // Escrita no registrador de inteiros desabilitada nesse estado, pois esse ainda eh o estado de calculo de endereco
				oMemWrite 		<= 1'b0;     // Load nao escreve na memoria
				oMemRead 		<= 1'b1;     // Habilita leitura da memoria
				oALUControl 	<= OPADD;    // Mantem o endereco
				// Sinais float
				oFRegWrite     <= 1'b0;     // Nao escreve ainda no registrador, pois ainda eh a etapa de leitura da memoria
				oFPALUControl  <= OPNULL;   // FPULA nao executa operacao no FLW
				oOrigAFPALU    <= 1'b0;     // Origem A da FPULA nao importa
				oFPALUStart    <= 1'b0;     // FPALU nao realiza operacao
				oFWriteData    <= 1'b1;     // Nessa fase ainda nao eh escrito nada no FReg
				oWrite2Mem     <= 1'b0;     // Nao importa o que sera escrito na memoria
			
				nx_state 		<= ST_FLW1;
			end
		ST_FLW1:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;     // Desabilita escrita no IR
				oEscrevePC 		<= 1'b0; 
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;    // Eh um don't care(?)
				oOrigBULA 		<= 2'b00;	 // Eh um don't care(?)
				oMem2Reg 		<= 3'b000;    // Eh um don't care(?)
				oOrigPC 			<= 2'b00;    // PC+4
				oIouD 			<= 1'b1;     // Endereco que entra na memoria vem da ULA, nao de PC
				oRegWrite 		<= 1'b0;     // Nao escreve em registrador de inteiro
				oMemWrite 		<= 1'b0;     // Nao escreve na memoria
				oMemRead 		<= 1'b1;     // Habilita leitura da memoria
				oALUControl 	<= OPNULL;   // Ja terminou de calcular o endereco
				// ControleFPULA
				oFRegWrite     <= 1'b0;     // Nessa etapa ainda nao estamos escrevendo no FReg
				oFPALUControl  <= OPNULL;   // FPULA nao realiza operacao
				oOrigAFPALU    <= 1'b0;     // Don't care
				oFPALUStart    <= 1'b0;     // FPULA nao faz nada
				oFWriteData    <= 1'b0;     // Don't care
				oWrite2Mem     <= 1'b0;	    // Don't care
			

				nx_state 		<= ST_FLW2;
			end
			
		ST_FLW2:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;   // Desabilita escrita no registrador de instrucoes
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;  // Don't care
				oOrigBULA 		<= 2'b00;  // Don't care	 
				oMem2Reg 		<= 3'b010;  // Don't care
				oOrigPC 			<= 2'b00;  // PC+4
				oIouD 			<= 1'b0;   // Volta a ler o endereco de PC
				oRegWrite 		<= 1'b0;   // Nao escreve no registrador de inteiros
				oMemWrite 		<= 1'b0;   // Nao escreve na memoria
				oMemRead 		<= 1'b0;   // Ja leu da memoria
				oALUControl 	<= OPNULL; // Nao realiza operacao na ULA
            // Controle Float
				oFRegWrite     <= 1'b1;   // Escreve no banco de registradores de ponto flutuante
				oFPALUControl  <= OPNULL; // Nao realiza opercao
				oOrigAFPALU    <= 1'b0;   // Don't care
				oFPALUStart    <= 1'b0;   // FPULA nao realiza operacao
				oFWriteData    <= 1'b0;   // Dados vem da memoria, entao eh selecionado MDR(0)
				oWrite2Mem     <= 1'b0;   // Don't care (nao escreve na memoria)		

				nx_state 		<= ST_FETCH;
			end
			
		ST_FSW:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;   // Nao habilita escrita no registrador de instrucao
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;  // Don't care
				oOrigBULA 		<= 2'b00;  // Don't care	 
				oMem2Reg 		<= 3'b000;  // Don't care
				oOrigPC 			<= 2'b00;  // PC+4
				oIouD 			<= 1'b1;   // Endereco de escrita vem de ALUOut
				oRegWrite 		<= 1'b0;   // Desabilita escrita em registrador de inteiro
				oMemWrite 		<= 1'b1;   // Habilita escrcita na memoria
				oMemRead 		<= 1'b0;   // Desabilita leitura da memoria
				oALUControl 	<= OPNULL; // Endereco ja foi calculado
            //Sinais float
				oFRegWrite     <= 1'b0;   // Nao escreve em registrador de ponto flutuante
				oFPALUControl  <= OPNULL; // FPULA nao realiza operacao
				oOrigAFPALU    <= 1'b0;   // don't care
				oFPALUStart    <= 1'b0;   // FPULA nao realiza operacao
				oFWriteData    <= 1'b0;   // don't care
				oWrite2Mem     <= 1'b1;	  // Conteudo de escrita da memoria vem do FB(1)

				nx_state 		<= ST_FSW1;
			end
		
		ST_FSW1:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;   // Nao habilita escrita no registrador de instrucao
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0; 
				oOrigAULA 		<= 2'b00;  // Don't care
				oOrigBULA 		<= 2'b00;  // Don't care	 
				oMem2Reg 		<= 3'b000;  // Don't care
				oOrigPC 			<= 2'b00;  // PC+4
				oIouD 			<= 1'b0;   // Endereco vem de PC
				oRegWrite 		<= 1'b0;   // Nao escreve em banco de registrador de inteiros
				oMemWrite 		<= 1'b0;   // Ja escreveu na memoria no estado anterior
				oMemRead 		<= 1'b0;   // Nao le da memoria
				oALUControl 	<= OPNULL; // ULA nao realiza operaco
				// Sinais FPALU
				oFRegWrite     <= 1'b0;   // Nao escreve em registrador de ponto flutuante
				oFPALUControl  <= OPNULL; // Nao realiza operacao
				oOrigAFPALU    <= 1'b0;   // Don't care
				oFPALUStart    <= 1'b0;   // Nao reseta FPULA
				oFWriteData    <= 1'b0;   // Don't care
				oWrite2Mem     <= 1'b1;   // Don't care

				nx_state 		<= ST_FETCH;
			end
			
		ST_FRTYPE:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;    // Nao habilita escrita em Registrador de instrucao
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0; 
				oOrigAULA 		<= 2'b00;   // Don't care  
				oOrigBULA 		<= 2'b00;   // Don't care
				oMem2Reg 		<= 3'b011;   // Se escrever em registrador de inteiro, eh pra escrever a saida da FPULA(11)  
				oOrigPC 			<= 2'b00;   // PC+4
				oIouD 			<= 1'b0;    // O endereco de entrada na memoria sempre vai vir de PC   
				oRegWrite 		<= 1'b0;    // Nao escreve em registrador de inteiro (nesse estado, mas depois pode escrever)   
				oMemWrite 		<= 1'b0;    // Nao habilita escrita na memoria
				oMemRead 		<= 1'b0;    // Nao habilita leitura da memoria   
				oALUControl 	<= OPNULL;  // ULA nao realiza nenhuma operacao
				// Sinais FPALU
				oFRegWrite     <= 1'b0;    // Nao escreve no banco de registradores (nessa etapa, mas depois pode escrever)
				//oOrigAFPALU definidos nos cases abaixo
				//oFPALUControl definido nos cases abaixo
				oFPALUStart    <= 1'b0;    // Start so sera dado no proximo estado
				oFWriteData    <= 1'b1;    // Escrita em registrador de ponto flutuante ainda nao habilitada   
				oWrite2Mem     <= 1'b0;    // Nao vai escrever na memoria   

				nx_state 		<= ST_FPSTART;
				
				case (Funct7)
					FUNCT7_FADD_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPADD;
						end
					FUNCT7_FSUB_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSUB;
						end
					FUNCT7_FMUL_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMUL;
						end						
					FUNCT7_FDIV_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPDIV;
						end						
					FUNCT7_FSQRT_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSQRT;
						end						
					FUNCT7_FMV_S_X:
						begin
							oOrigAFPALU    <= 1'b0; //A
							oFPALUControl <= FOPMV;
						end
					FUNCT7_FMV_X_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMV;
						end
					
					FUNCT7_FSIGN_INJECT:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FSGNJ_S:  oFPALUControl <= FOPSGNJ;
								FUNCT3_FSGNJN_S: oFPALUControl <= FOPSGNJN;
								FUNCT3_FSGNJX_S: oFPALUControl <= FOPSGNJX;
								default: // instruçao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
					
					FUNCT7_MAX_MIN_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FMAX_S: oFPALUControl <= FOPMAX;
								FUNCT3_FMIN_S: oFPALUControl <= FOPMIN;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCOMPARE:
						begin
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Funct3)
								FUNCT3_FEQ_S: oFPALUControl <= FOPCEQ;
								FUNCT3_FLE_S: oFPALUControl <= FOPCLE;
								FUNCT3_FLT_S: oFPALUControl <= FOPCLT;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_S_W_WU:
						begin
							oOrigAFPALU    <= 1'b0; //A
						
							case(Rs2)
								RS2_FCVT_S_W:  oFPALUControl <= FOPCVTSW;
								RS2_FCVT_S_WU: oFPALUControl <= FOPCVTSWU;
								default: // intrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_W_WU_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Rs2)
								RS2_FCVT_W_S:  oFPALUControl <= FOPCVTWS;
								RS2_FCVT_WU_S: oFPALUControl <= FOPCVTWUS;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					default: // instrucao invalida
						begin
							oEscreveIR 		<= 1'b0;
							oEscrevePC 		<= 1'b0;
							oEscrevePCCond <= 1'b0;
							oEscrevePCBack <= 1'b0;
							oOrigAULA 		<= 2'b00;
							oOrigBULA 		<= 2'b00;	 
							oMem2Reg 		<= 3'b000;
							oOrigPC 			<= 2'b00;
							oIouD 			<= 1'b0;
							oRegWrite 		<= 1'b0;
							oMemWrite 		<= 1'b0;
							oMemRead 		<= 1'b0;
							oALUControl 	<= OPNULL;
							oFRegWrite     <= 1'b0;
							oFPALUControl  <= OPNULL;
							oOrigAFPALU    <= 1'b0;
							oFPALUStart    <= 1'b0;
							oFWriteData    <= 1'b0;
							oWrite2Mem     <= 1'b0;
							
							nx_state 		<= ST_ILEGALINSTRUCTION;
						end
				endcase
			end
			
		ST_FPSTART:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00; // Don't care
				oOrigBULA 		<= 2'b00; // Don't care	 
				oMem2Reg 		<= 3'b011; 
				oOrigPC 			<= 2'b00; // PC+4
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
				oFRegWrite     <= 1'b0;
				//oFPALUControl  <= OPNULL;
				//oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b1;
				oFWriteData    <= 1'b1;
				oWrite2Mem     <= 1'b0;
				
				nx_state 		<= ST_FPWAIT;
				
				case (Funct7)
					FUNCT7_FADD_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPADD;
						end
					FUNCT7_FSUB_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSUB;
						end
					FUNCT7_FMUL_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMUL;
						end						
					FUNCT7_FDIV_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPDIV;
						end						
					FUNCT7_FSQRT_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSQRT;
						end						
					FUNCT7_FMV_S_X:
						begin
							oOrigAFPALU    <= 1'b0; //A
							oFPALUControl <= FOPMV;
						end
					FUNCT7_FMV_X_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMV;
						end
					
					FUNCT7_FSIGN_INJECT:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FSGNJ_S:  oFPALUControl <= FOPSGNJ;
								FUNCT3_FSGNJN_S: oFPALUControl <= FOPSGNJN;
								FUNCT3_FSGNJX_S: oFPALUControl <= FOPSGNJX;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
					
					FUNCT7_MAX_MIN_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FMAX_S: oFPALUControl <= FOPMAX;
								FUNCT3_FMIN_S: oFPALUControl <= FOPMIN;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCOMPARE:
						begin
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Funct3)
								FUNCT3_FEQ_S: oFPALUControl <= FOPCEQ;
								FUNCT3_FLE_S: oFPALUControl <= FOPCLE;
								FUNCT3_FLT_S: oFPALUControl <= FOPCLT;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_S_W_WU:
						begin
							oOrigAFPALU    <= 1'b0; //A
						
							case(Rs2)
								RS2_FCVT_S_W:  oFPALUControl <= FOPCVTSW;
								RS2_FCVT_S_WU: oFPALUControl <= FOPCVTSWU;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_W_WU_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Rs2)
								RS2_FCVT_W_S:  oFPALUControl <= FOPCVTWS;
								RS2_FCVT_WU_S: oFPALUControl <= FOPCVTWUS;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					default: // instrucap invalida
						begin
							oEscreveIR 		<= 1'b0;
							oEscrevePC 		<= 1'b0;
							oEscrevePCCond <= 1'b0;
							oEscrevePCBack <= 1'b0;
							oOrigAULA 		<= 2'b00;
							oOrigBULA 		<= 2'b00;	 
							oMem2Reg 		<= 3'b000;
							oOrigPC 			<= 2'b00;
							oIouD 			<= 1'b0;
							oRegWrite 		<= 1'b0;
							oMemWrite 		<= 1'b0;
							oMemRead 		<= 1'b0;
							oALUControl 	<= OPNULL;
							oFRegWrite     <= 1'b0;
							oFPALUControl  <= OPNULL;
							oOrigAFPALU    <= 1'b0;
							oFPALUStart    <= 1'b0;
							oFWriteData    <= 1'b0;
							oWrite2Mem     <= 1'b0;
							
							nx_state 		<= ST_ILEGALINSTRUCTION;
						end
				endcase
			end
			
		ST_FPWAIT:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00; // Don't care
				oOrigBULA 		<= 2'b00; // Don't care	 
				oMem2Reg 		<= 3'b011; 
				oOrigPC 			<= 2'b00; // PC+4
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
				oFRegWrite     <= 1'b0;
				//oFPALUControl  definido nos cases abaixo;
				//oOrigAFPALU    definido nos cases abaixo;
				oFPALUStart    <= 1'b1;	// fica start durante o tempo todo (como no uniciclo)
				oFWriteData    <= 1'b1;
				oWrite2Mem     <= 1'b0;
				
				if (iFPALUReady)
					nx_state <= ST_FPALUREGWRITE;
				else
					nx_state <= ST_FPWAIT;
					
				case (Funct7)
					FUNCT7_FADD_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPADD;
						end
					FUNCT7_FSUB_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSUB;
						end
					FUNCT7_FMUL_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMUL;
						end						
					FUNCT7_FDIV_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPDIV;
						end						
					FUNCT7_FSQRT_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSQRT;
						end						
					FUNCT7_FMV_S_X:
						begin
							oOrigAFPALU    <= 1'b0; //A
							oFPALUControl <= FOPMV;
						end
					FUNCT7_FMV_X_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMV;
						end
					
					FUNCT7_FSIGN_INJECT:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FSGNJ_S:  oFPALUControl <= FOPSGNJ;
								FUNCT3_FSGNJN_S: oFPALUControl <= FOPSGNJN;
								FUNCT3_FSGNJX_S: oFPALUControl <= FOPSGNJX;
								default:
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
					
					FUNCT7_MAX_MIN_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FMAX_S: oFPALUControl <= FOPMAX;
								FUNCT3_FMIN_S: oFPALUControl <= FOPMIN;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCOMPARE:
						begin
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Funct3)
								FUNCT3_FEQ_S: oFPALUControl <= FOPCEQ;
								FUNCT3_FLE_S: oFPALUControl <= FOPCLE;
								FUNCT3_FLT_S: oFPALUControl <= FOPCLT;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_S_W_WU:
						begin
							oOrigAFPALU    <= 1'b0; //A
						
							case(Rs2)
								RS2_FCVT_S_W:  oFPALUControl <= FOPCVTSW;
								RS2_FCVT_S_WU: oFPALUControl <= FOPCVTSWU;
								default:
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_W_WU_S:
						begin
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Rs2)
								RS2_FCVT_W_S:  oFPALUControl <= FOPCVTWS;
								RS2_FCVT_WU_S: oFPALUControl <= FOPCVTWUS;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					default: // instrucao invalida
						begin
							oEscreveIR 		<= 1'b0;
							oEscrevePC 		<= 1'b0;
							oEscrevePCCond <= 1'b0;
							oEscrevePCBack <= 1'b0;
							oOrigAULA 		<= 2'b00;
							oOrigBULA 		<= 2'b00;	 
							oMem2Reg 		<= 3'b000;
							oOrigPC 			<= 2'b00;
							oIouD 			<= 1'b0;
							oRegWrite 		<= 1'b0;
							oMemWrite 		<= 1'b0;
							oMemRead 		<= 1'b0;
							oALUControl 	<= OPNULL;
							oFRegWrite     <= 1'b0;
							oFPALUControl  <= OPNULL;
							oOrigAFPALU    <= 1'b0;
							oFPALUStart    <= 1'b0;
							oFWriteData    <= 1'b0;
							oWrite2Mem     <= 1'b0;
							
							nx_state 		<= ST_ILEGALINSTRUCTION;
						end
				endcase
			end
			
		ST_FPALUREGWRITE:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;  // Don't care
				oOrigBULA 		<= 2'b00;  // Don't care	 
				oMem2Reg 		<= 3'b011;  // Se for escrever nos registradores de inteiro, a selecao eh da saida da FPULA
				oOrigPC 			<= 2'b00;  // PC+4
				oIouD 			<= 1'b0;
				//oRegWrite definido abaixo
				oMemWrite 		<= 1'b0;   // Nao escreve na memoria
				oMemRead 		<= 1'b0;   // Nao le da memoria
				oALUControl 	<= OPNULL; // ULA nao realiza nenhuma operacao
				//oFRegWrite definido abaixo
				//oFPALUControl definido abaixo
				oFPALUStart    <= 1'b1;	 // fica em start ainda (pra não perder o valor?)
				oFWriteData    <= 1'b1; // Dado de escrita vem da FPALU
				oWrite2Mem     <= 1'b0; // Nao habilita escrita na memoria
				
				nx_state <=  ST_FETCH;
			
			
				case (Funct7)
					FUNCT7_FADD_S:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPADD;
						end
					FUNCT7_FSUB_S:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSUB;
						end
					FUNCT7_FMUL_S:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMUL;
						end						
					FUNCT7_FDIV_S:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPDIV;
						end						
					FUNCT7_FSQRT_S:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPSQRT;
						end						
					FUNCT7_FMV_S_X:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b0; //A
							oFPALUControl <= FOPMV;
						end
					FUNCT7_FMV_X_S:
						begin
							oFRegWrite     <= 1'b0;
							oRegWrite 		<= 1'b1;
							oOrigAFPALU    <= 1'b1; //FA
							oFPALUControl <= FOPMV;
						end
					
					FUNCT7_FSIGN_INJECT:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FSGNJ_S:  oFPALUControl <= FOPSGNJ;
								FUNCT3_FSGNJN_S: oFPALUControl <= FOPSGNJN;
								FUNCT3_FSGNJX_S: oFPALUControl <= FOPSGNJX;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
					
					FUNCT7_MAX_MIN_S:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b1; //FA
							
							case(Funct3)
								FUNCT3_FMAX_S: oFPALUControl <= FOPMAX;
								FUNCT3_FMIN_S: oFPALUControl <= FOPMIN;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCOMPARE:
						begin
							oFRegWrite     <= 1'b0;
							oRegWrite 		<= 1'b1;
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Funct3)
								FUNCT3_FEQ_S: oFPALUControl <= FOPCEQ;
								FUNCT3_FLE_S: oFPALUControl <= FOPCLE;
								FUNCT3_FLT_S: oFPALUControl <= FOPCLT;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_S_W_WU:
						begin
							oFRegWrite     <= 1'b1;
							oRegWrite 		<= 1'b0;
							oOrigAFPALU    <= 1'b0; //A
						
							case(Rs2)
								RS2_FCVT_S_W:  oFPALUControl <= FOPCVTSW;
								RS2_FCVT_S_WU: oFPALUControl <= FOPCVTSWU;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
						
					FUNCT7_FCVT_W_WU_S:
						begin
							oFRegWrite     <= 1'b0;
							oRegWrite 		<= 1'b1;
							oOrigAFPALU    <= 1'b1; //FA
						
							case(Rs2)
								RS2_FCVT_W_S:  oFPALUControl <= FOPCVTWS;
								RS2_FCVT_WU_S: oFPALUControl <= FOPCVTWUS;
								default: // instrucao invalida
									begin
										oEscreveIR 		<= 1'b0;
										oEscrevePC 		<= 1'b0;
										oEscrevePCCond <= 1'b0;
										oEscrevePCBack <= 1'b0;
										oOrigAULA 		<= 2'b00;
										oOrigBULA 		<= 2'b00;	 
										oMem2Reg 		<= 3'b000;
										oOrigPC 			<= 2'b00;
										oIouD 			<= 1'b0;
										oRegWrite 		<= 1'b0;
										oMemWrite 		<= 1'b0;
										oMemRead 		<= 1'b0;
										oALUControl 	<= OPNULL;
										oFRegWrite     <= 1'b0;
										oFPALUControl  <= OPNULL;
										oOrigAFPALU    <= 1'b0;
										oFPALUStart    <= 1'b0;
										oFWriteData    <= 1'b0;
										oWrite2Mem     <= 1'b0;
										
										nx_state 		<= ST_ILEGALINSTRUCTION;
									end
							endcase
						end
					default: // instrucao invalida
						begin
							oUcause        <= 32'b0;
							oCSRWrite      <= 1'b0;
							oEscreveCRSOut <=  1'b0;
							oEbreak        <=  1'b0;
							oSelectNumRegCSR<= 2'b00;
							oOrigWriteDataCSR <= 3'b000;
							
							oEscreveIR 		<= 1'b0;
							oEscrevePC 		<= 1'b0;
							oEscrevePCCond <= 1'b0;
							oEscrevePCBack <= 1'b0;
							oOrigAULA 		<= 2'b00;
							oOrigBULA 		<= 2'b00;	 
							oMem2Reg 		<= 3'b000;
							oOrigPC 			<= 2'b00;
							oIouD 			<= 1'b0;
							oRegWrite 		<= 1'b0;
							oMemWrite 		<= 1'b0;
							oMemRead 		<= 1'b0;
							oALUControl 	<= OPNULL;
							oFRegWrite     <= 1'b0;
							oFPALUControl  <= OPNULL;
							oOrigAFPALU    <= 1'b0;
							oFPALUStart    <= 1'b0;
							oFWriteData    <= 1'b0;
							oWrite2Mem     <= 1'b0;
							
							nx_state 		<= ST_ILEGALINSTRUCTION;
						end
				endcase
			end
`endif

		// Instrucao invalida
		default:
			begin
				oUcause        <= 32'h00000000;
				oCSRWrite      <= 1'b0;
				oEscreveCRSOut <=  1'b0;
				oEbreak        <=  1'b0;
				oSelectNumRegCSR<= 2'b00;
            oOrigWriteDataCSR <= 3'b000;
				
				oEscreveIR 		<= 1'b0;
				oEscrevePC 		<= 1'b0;
				oEscrevePCCond <= 1'b0;
				oEscrevePCBack <= 1'b0;
				oOrigAULA 		<= 2'b00;
				oOrigBULA 		<= 2'b00;	 
				oMem2Reg 		<= 3'b000;
				oOrigPC 			<= 2'b00;
				oIouD 			<= 1'b0;
				oRegWrite 		<= 1'b0;
				oMemWrite 		<= 1'b0;
				oMemRead 		<= 1'b0;
				oALUControl 	<= OPNULL;
`ifdef RV32IMF                                                 //RV32IMF
				oFRegWrite     <= 1'b0;
				oFPALUControl  <= OPNULL;
				oOrigAFPALU    <= 1'b0;
				oFPALUStart    <= 1'b0;
				oFWriteData    <= 1'b0;
				oWrite2Mem     <= 1'b0;
`endif	

				
				nx_state 		<= ST_ILEGALINSTRUCTION;
			end
		
	endcase


endmodule
