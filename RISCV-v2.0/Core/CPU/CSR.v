`ifndef PARAM
    `include "../Parametros.v"
`endif

module CSRRegisters(
   input wire iCLK, iRST, iREGWrite,
	input wire  [6:0] 	iNumReg,
	input wire  [31:0] 	iWriteData, iPC,
	input wire  [31:0]   iUcause,
	input  wire [31:0]   iInstr,
	output  wire [31:0]  oCSRInstOut
);

reg [31:0] ustatus,fflags,frm, fcsr, uie,utvec,uscratch, uepc, ucause, utval,uip;
//ustatus(0),
//fflags(1), frm(2), fcsr(3), uie(4), utvect(5), uscratch(64), uepc(65), ucause(66), utval(67), uip(68)


initial 
  begin 
			ustatus = 32'b0;
			fflags  = 32'b0;
			frm     = 32'b0;
			fcsr    = 32'b0;
			uie     = 32'b0;
			utvec   = 32'b0;
			uscratch= 32'b0;
			uepc    = 32'b0;
			ucause  = 32'b0;
			utval   = 32'b0;
			uip     = 32'b0;
  end

always @(*)
case(iNumReg)
					NUMUSTATUS:    oCSRInstOut =ustatus;
					NUMFFLAGS:     oCSRInstOut =fflags;
					NUMFRM:        oCSRInstOut =frm;
					NUMFCSR:       oCSRInstOut =fcsr;
					NUMUIE:        oCSRInstOut =uie;
					NUMUTVEC:      oCSRInstOut =utvec;
					NUMUSCRATCH:   oCSRInstOut =uscratch;
					NUMUEPC:       oCSRInstOut =uepc;
					NUMUCAUSE:     oCSRInstOut =ucause;
					NUMUTVAL:      oCSRInstOut =utval;
					NUMUIP:        oCSRInstOut =uip;
					default:       oCSRInstOut =ustatus;
endcase
// assign oCSRInstOut = registers[iNumReg];
//assign oUTVEC   = utvec; // manda o reg(5) utvec como saida 
 
 
always @(posedge iCLK or posedge iRST)
begin
	if(iRST)
	 begin // reseta o banco de registradores
			ustatus = 32'b0;
			fflags  = 32'b0;
			frm     = 32'b0;
			fcsr    = 32'b0;
			uie     = 32'b0;
			utvec   = 32'b0;
			uscratch= 32'b0;
			uepc    = 32'b0;
			ucause  = 32'b0;
			utval   = 32'b0;
			uip     = 32'b0;
	 end
    else
    begin
       if(iREGWrite != 0)
		 begin 
			if(iUcause ==32'h0000000F) // se for csr instrution
			begin
		      case(iNumReg)
						NUMUSTATUS: ustatus <= iWriteData;
						NUMFFLAGS:  fflags  <= iWriteData;
						NUMFRM:     frm     <= iWriteData;
						NUMFCSR:    fcsr    <= iWriteData;
						NUMUIE:     uie     <= iWriteData;
						NUMUTVEC:   utvec   <= iWriteData;
						NUMUSCRATCH:uscratch <= iWriteData;
						NUMUEPC:    uepc    <= iWriteData;
						NUMUCAUSE:  ucause  <= iWriteData;
						NUMUTVAL:   utval   <= iWriteData;
						NUMUIP:     uip     <=  iWriteData;
						
				endcase
			end
			else // se for alguma exercao
				begin
					ucause <=iUcause;
					uepc <= iPC;    // grava PC no reg(65) uepc
					if(iUcause == 32'h00000002) utval <= iInstr;
					else utval <= iPC;
				end
		  end		
	 end	 
end  
endmodule  