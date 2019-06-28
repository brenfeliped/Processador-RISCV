`ifndef PARAM
	`include "../Parametros.v"
`endif

//
// Caminho de dados processador RISC-V Multiciclo
//
// 2018-2 Marcus Vinicius Lamar
//
 
module Datapath_MULTI (
    // Inputs e clocks
    input  wire        iCLK, iCLK50, iRST,
    input  wire [31:0] iInitialPC,

    // Para monitoramento
    output wire [31:0] mPC,
    output wire [31:0] mInstr,
	 output wire [31:0] mDebug,
    input  wire [ 4:0] mRegDispSelect,
    output wire [31:0] mRegDisp,
	 output wire [31:0] mFRegDisp,	 
    input  wire [ 4:0] mVGASelect,
    output wire [31:0] mVGARead,
    output wire [31:0] mFVGARead,
	 output wire [31:0] mRead1,
	 output wire [31:0] mRead2,
	 output wire [31:0] mRegWrite,
	 output wire [31:0] mULA,
`ifdef RV32IMF
	 output wire [31:0] mFPALU,       // Fio de monitoramento da FPALU
	 output wire [31:0] mFRead1,      // Monitoramento Rs1 FRegister
	 output wire [31:0] mFRead2,      // Monitoramento Rs2 FRegister
	 output wire [31:0] mOrigAFPALU,  // Monitoramento entrada A da FPULA
	 output wire [31:0] mFWriteData,  // Para verificar o que esta entrando no FRegister
	 output wire        mCFRegWrite,  // Monitoramento do Enable do FRegister
`endif	 
	 
	// Sinais do Controle
	output wire	[31:0] wInstr,
	input  wire			 wCEscreveIR,
	input  wire			 wCEscrevePC,
	input  wire			 wCEscrevePCCond,
	input  wire			 wCEscrevePCBack,
   input  wire	[ 1:0] wCOrigAULA,
   input  wire	[ 1:0] wCOrigBULA,	 
   input  wire	[ 2:0] wCMem2Reg,
	input  wire	[ 1:0] wCOrigPC,
	input  wire			 wCIouD,
   input  wire			 wCRegWrite,
   input  wire			 wCMemWrite,
	input  wire			 wCMemRead,
	input  wire	[ 4:0] wCALUControl,
	// sinais de  controle exercao e instrucoes CSR
	input  wire [31:0] wCUcause,
	input  wire        wCCSRWrite,
   input  wire        wCEscreveCRSOut,
   input  wire [2:0]  wCOrigWriteDataCSR,
   input  wire [1:0]	 WCSelectNumRegCSR,
`ifdef RV32IMF
	output wire			 wFPALUReady,
	input  wire        wCFRegWrite,
	input  wire [ 4:0] wCFPALUControl,
	input  wire        wCOrigAFPALU,
	input  wire        wCFPALUStart,
	input  wire        wCFWriteData,
	input  wire        wCWrite2Mem,
`endif

    //  Barramento
   output wire        DwReadEnable, DwWriteEnable,
   output wire [ 3:0] DwByteEnable,
   output wire [31:0] DwAddress, DwWriteData,
   input  wire [31:0] DwReadData,
	// sinais output para execao
	 output wire oOutText,
	 output wire oOutData,
	 output wire oPCMisaligned,
	 output wire oExceptionLoad,
	 output wire oExceptionStore
);



// Sinais de monitoramento e Debug
wire [31:0] wRegDisp, wFRegDisp, wVGARead, wFVGARead;
wire [ 4:0] wRegDispSelect, wVGASelect;

assign mPC					= PC; 
assign mInstr				= IR;
assign mRead1				= A;
assign mRead2				= B;
assign mRegWrite			= wRegWrite;
assign mULA					= ALUOut;
assign mDebug				= wCSRDataout;     // 32'h000ACE10;	// Ligar onde for preciso	
assign wRegDispSelect 	= mRegDispSelect;
assign wVGASelect 		= mVGASelect;
assign mRegDisp			= wRegDisp;
assign mVGARead			= wVGARead;

`ifdef RV32IMF
assign mFRegDisp			= wFRegDisp;
assign mFVGARead			= wFVGARead;
`else
assign mFRegDisp			= ZERO;
assign mFVGARead			= ZERO;
`endif


`ifdef RV32IMF
assign mFPALU				= wFPALUResult;
assign mFRead1          = FA;
assign mFRead2          = FB;
assign mOrigAFPALU      = wOrigAFPALU;
assign mFWriteData      = wFWriteData;
assign mCFRegWrite      = wCFRegWrite;
`endif


// ****************************************************** 
// Instanciação e Inicializacao dos registradores		  						 

reg 	[31:0] PC, PCBack, IR, MDR, A, B, ALUOut,CSROut;
`ifdef RV32IMF
reg   [31:0] FA, FB, FPALUOut;
`endif

assign wInstr = IR;


initial
begin
	PC			<= BEGINNING_TEXT;
	PCBack 	<= BEGINNING_TEXT;
	IR			<= ZERO;
	ALUOut	<= ZERO;
	MDR 		<= ZERO;
	A 			<= ZERO;
	B 			<= ZERO;
`ifdef RV32IMF
	FA       <= ZERO;
	FB       <= ZERO;
	FPALUOut	<= ZERO;
`endif
end


// ****************************************************** 
// Instanciacao das estruturas 	 		  						 
 						 

wire [ 4:0] wRs1			= IR[19:15];
wire [ 4:0] wRs2			= IR[24:20];
wire [ 4:0] wRd			= IR[11:7];
wire [ 2:0] wFunct3		= IR[14:12];


// Unidade de controle de escrita 
wire [31:0] wMemDataWrite;
wire [ 3:0] wMemEnable;
MemStore MEMSTORE0 (
    .iAlignment(wMemAddress[1:0]),
    .iFunct3(wFunct3),
`ifndef RV32IMF
    .iData(B),                       // Dado de escrita
`else
	 .iData(wWrite2Mem),
`endif
    .oData(wMemDataWrite),
    .oByteEnable(wMemEnable),
    .oException(oExceptionStore)
	);
	

// Barramento da memoria 
assign DwReadEnable     = wCMemRead;
assign DwWriteEnable    = wCMemWrite;
assign DwByteEnable     = wMemEnable;
assign DwAddress        = wMemAddress;
assign DwWriteData      = wMemDataWrite;
wire 	 [31:0] wReadData = DwReadData;


// Unidade de controle de leitura 
wire [31:0] wMemLoad;

MemLoad MEMLOAD0 (
    .iAlignment(wMemAddress[1:0]),
    .iFunct3(wFunct3),
    .iData(wReadData),
    .oData(wMemLoad),
    .oException(oExceptionLoad)
	);
	
	

//Banco de registradores CSR
wire [31:0] wCSRDataout;
CSRRegisters CSR0(
	.iCLK(iCLK),
	.iRST(iRST),
	.iREGWrite(wCCSRWrite),
	.iNumReg(wNumReg),
	.iWriteData(wWriteDataCSR),
	.iPC(PCBack),
	.iUcause(wCUcause),
	.iInstr(wInstr),
	.oCSRInstOut(wCSRDataout)
);
// Banco de Registradores 
wire [31:0] wRead1, wRead2;

Registers REGISTERS0 (
    .iCLK(iCLK),
    .iRST(iRST),
    .iReadRegister1(wRs1),
    .iReadRegister2(wRs2),
    .iWriteRegister(wRd),
    .iWriteData(wRegWrite),
    .iRegWrite(wCRegWrite),
    .oReadData1(wRead1),
    .oReadData2(wRead2),
	 
    .iRegDispSelect(wRegDispSelect),    // seleção para display
    .oRegDisp(wRegDisp),                // Reg display
    .iVGASelect(wVGASelect),            // para mostrar Regs na tela
    .oVGARead(wVGARead)                 // para mostrar Regs na tela
	);
	
	
`ifdef RV32IMF
wire [31:0] wFRead1;
wire [31:0] wFRead2;

FRegisters REGISTERS1 (
    .iCLK(iCLK),
    .iRST(iRST),
    .iReadRegister1(wRs1),
    .iReadRegister2(wRs2),     
    .iWriteRegister(wRd),      
    .iWriteData(wFWriteData),  
    .iRegWrite(wCFRegWrite),   
    .oReadData1(wFRead1),      
    .oReadData2(wFRead2),     
	 
    .iRegDispSelect(wRegDispSelect),    // seleÃ§Ã£o para display
    .oRegDisp(wFRegDisp),                // Reg display colocar fregdisp
    .iVGASelect(wVGASelect),            // para mostrar Regs na tela
    .oVGARead(wFVGARead)                 // para mostrar Regs na tela colocar wfvgaread
	);

`endif

	
// Unidade de controle de Branches 
wire 	wBranch;

BranchControl BC0 (
    .iFunct3(wFunct3),
    .iA(A), 
	 .iB(B),
    .oBranch(wBranch)
);


// Unidade geradora do imediato 
wire [31:0] wImmediate;

ImmGen IMMGEN0 (
    .iInstrucao(IR),
    .oImm(wImmediate)
);


// ALU - Unidade Lógica Aritmética
wire [31:0] wALUresult;

ALU ALU0 (
    .iControl(wCALUControl),
    .iA(wOrigAULA),
    .iB(wOrigBULA),
    .oResult(wALUresult),
    .oZero()
	);


`ifdef RV32IMF
//FPALU
//wire        wFPALUReady;
wire [31:0] wFPALUResult;

FPALU FPALU0 (
    .iclock(iCLK),
    .icontrol(wCFPALUControl),
    .idataa(wOrigAFPALU),
    .idatab(FB),                    // Registrador B entra direto na FPULA
	 .istart(wCFPALUStart),            // Sinal de reset (start) que sera enviado pela controladora
	 .oready(wFPALUReady),           // Output que sinaliza a controladora que a FPULA terminou a operacao
    .oresult(wFPALUResult)
	);

`endif


// Sinais de exerção
always @(*)
if(PC[0]==0 && PC[1]==0)
	begin
	  oPCMisaligned= 1'b0;
	end
else
	begin
	  oPCMisaligned= 1'b1;
	end
always @(*)
if(PC>=BEGINNING_TEXT && PC<=END_TEXT)
begin
   oOutText= 1'b0;
end
else
begin
	oOutText= 1'b1;
end
always @(*)
if(wCOrigAULA==2'b10 && wCOrigBULA==2'b00)
begin
	if((ALUOut>=BEGINNING_DATA && ALUOut<=BEGINNING_DATA)  || ALUOut >= BEGINNING_IODEVICES)
	begin
		oOutData= 1'b0;
	end
	else
	begin
		oOutData = 1'b1;
	end
end
	else
begin
	oOutData= 1'b0;
end
// ****************************************************** 
// multiplexadores							  						 


wire [6:0] wNumReg;
always @(*)
		case(WCSelectNumRegCSR)
			2'b00: wNumReg <= wImmediate[6:0];// NUmero do registrador CSR
		   2'b01:  wNumReg <= NUMUTVEC; // Numero do resgitrador utvec(5)
			2'b10:  wNumReg <= NUMUEPC;// Numero do resgitrador uepc(65)
			default: wNumReg <= NUMUTVEC;	
		endcase
		
wire [31:0] wWriteDataCSR;
always @(*)
	case(wCOrigWriteDataCSR)
		3'b000: wWriteDataCSR <= {27'b0,wRs1}; // Imediato das instrucoes CSR, CSR= zImm
		3'b001: wWriteDataCSR <=  A;     // CSR = R[rs1]
		3'b010: wWriteDataCSR <= wCSRDataout |  A;
		3'b011: wWriteDataCSR <= wCSRDataout & ~A;
		3'b100: wWriteDataCSR <= wCSRDataout | {27'b0,wRs1};
		3'b101: wWriteDataCSR <= wCSRDataout & ~{27'b0,wRs1};
		default: wWriteDataCSR <= ZERO;
	endcase

wire [31:0] wOrigAULA;
always @(*)
    case(wCOrigAULA)
        2'b00:    wOrigAULA <= A;
		  2'b01:		wOrigAULA <= PC;
		  2'b10:		wOrigAULA <= PCBack;
		  default:	wOrigAULA <= ZERO;
    endcase

	 
wire [31:0] wOrigBULA;	 
always @(*)
    case(wCOrigBULA)
        2'b00:    wOrigBULA <= B;
        2'b01:    wOrigBULA <= 32'h4;
		  2'b10:		wOrigBULA <= wImmediate;
		  default:	wOrigBULA <= ZERO;
    endcase	 
	 
	 
wire [31:0] wRegWrite;	 
always @(*)
    case(wCMem2Reg)
        3'b000:    wRegWrite <= ALUOut;
        3'b001:    wRegWrite <= PC;
        3'b010:    wRegWrite <= MDR;
`ifdef RV32IMF                                        //RV32IMF
		  3'b011:    wRegWrite <= FPALUOut; // Uma entrada a mais no multiplexador de escrita no registrador de inteiros
`endif
		  3'b100:    wRegWrite <= CSROut;
        default:  wRegWrite <= ZERO;
    endcase

	 
wire [31:0] wiPC;	 
always @(*)
	case(wCOrigPC)
		2'b00:     wiPC <= wALUresult;				// PC+4
      2'b01:     wiPC <= ALUOut;						// Branches e jal
		2'b10:	  wiPC <= wALUresult & ~(32'h1);	// jalr
		2'b11:	  wiPC <= CSROut;                // exercao ou URET
	endcase
	
	
wire [31:0] wMemAddress;	
always @(*)
	case(wCIouD)
		1'b0:		wMemAddress <= PC;
		1'b1:		wMemAddress <= ALUOut;
		default:	wMemAddress <= ZERO;
	endcase

	
`ifdef RV32IMF
wire [31:0] wOrigAFPALU;
always @(*)
    case(wCOrigAFPALU) // Multiplexador que controla a origem A da FPULA
        1'b0:      wOrigAFPALU <= A;
        1'b1:      wOrigAFPALU <= FA;
		  default:	 wOrigAFPALU <= ZERO;
    endcase

	 
wire [31:0] wFWriteData;
always @(*)
    case(wCFWriteData) // Multiplexador que controla o que vai ser escrito em um registrador de ponto flutuante (origem memoria ou FPALU?)
        1'b0:      wFWriteData <= MDR;      // Registrador de dado de memoria (para o flw)
        1'b1:      wFWriteData <= FPALUOut; // Registrador da saida da FPULA
		  default:	 wFWriteData <= ZERO;
    endcase

	 
wire [31:0] wWrite2Mem;	 
always @(*)
    case(wCWrite2Mem) // Multiplexador que controla o que vai ser escrito na memoria (vem do Register(0) ou do FRegister(1)?)
        1'b0:      wWrite2Mem <= B;
        1'b1:      wWrite2Mem <= FB;
		  default:	 wWrite2Mem <= ZERO;
    endcase
`endif
		

		


// ****************************************************** 
// A cada ciclo de clock					  						 

always @(posedge iCLK or posedge iRST)
	if (iRST)
	  begin
		PC			<= BEGINNING_TEXT;
		PCBack 	<= BEGINNING_TEXT;
		IR			<= ZERO;
		ALUOut	<= ZERO;
		MDR 		<= ZERO;
		A 			<= ZERO;
		B 			<= ZERO;
		CSROut   <= ZERO;
`ifdef RV32IMF
	   FA       <= ZERO;
	   FB       <= ZERO;
		FPALUOut <= ZERO;
`endif
	  end
	else
	  begin
		// Unconditional 
		ALUOut	<= wALUresult;
		A			<= wRead1;
		B			<= wRead2;
		MDR		<= wMemLoad;
`ifdef RV32IMF
		FPALUOut <= wFPALUResult;
		FA       <= wFRead1;
		FB       <= wFRead2;
`endif

		// Conditional

			
		if (wCEscreveIR)
			IR	<= wReadData;
			
		if (wCEscrevePCBack)
			PCBack <= PC;
		
		if(wCEscreveCRSOut)
			CSROut <= wCSRDataout;	
			
		if (wCEscrevePC || wBranch & wCEscrevePCCond)
			PC	<= wiPC;	

	  end



endmodule 
