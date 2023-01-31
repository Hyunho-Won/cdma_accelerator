#include "xparameters.h"
#include <stdio.h>
#include "xuartps.h"	// if PS uart is used
#include "xscutimer.h"  // if PS Timer is used
#include "xaxicdma.h"	// if CDMA is used
#include "xscugic.h" 	// if PS GIC is used
#include "xil_exception.h"	// if interrupt is used
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "xil_io.h"
#include "xtime_l.h"  // To measure of processing time
#include <assert.h>
#include <stdlib.h>

#define WRITE 1
#define CORE_RUN 2
#define READ 3
#define AXI_DATA_BYTE 4
 
#define IDLE 1
#define RUN 1 << 1
#define DONE 1 << 2

#define CTRL_REG 0
#define STATUS_REG 1
#define RESULT_0_REG 3
#define RESULT_1_REG 4
#define RESULT_2_REG 5
#define RESULT_3_REG 6
#define RESULT_4_REG 7
#define RESULT_5_REG 8
#define RESULT_6_REG 9
#define RESULT_7_REG 10

#define MEM_DEPTH 4096
#define NUM_CORE 8
//

#define RESET_LOOP_COUNT	10	// Number of times to check reset is done
#define LENGTH 32768 // source and destination buffers lengths in number of bytes
#define PROCESSOR_BRAM_MEMORY 0x80000000 // BRAM Port A mapped through 1st BRAM Controller accessed by CPU
#define CDMA_BRAM_MEMORY_0 0xC0000000 // BRAM Port B mapped through 2nd BRAM Controller accessed by CDMA
#define CDMA_BRAM_MEMORY_1 0xC2000000
#define DDR_MEMORY_0 0x01000000
#define DDR_MEMORY_1 0x02000000
#define TIMER_DEVICE_ID	XPAR_SCUTIMER_DEVICE_ID
#define TIMER_LOAD_VALUE 0xFFFFFFFF
#define INTC_DEVICE_INT_ID XPAR_SCUGIC_SINGLE_DEVICE_ID

volatile static int Done = 0;	/* Dma transfer is done */
volatile static int Error = 0;	/* Dma Bus Error occurs */

XUartPs Uart_PS;		/* Instance of the UART Device */
XScuTimer Timer;		/* Cortex A9 SCU Private Timer Instance */
XScuGic Gic;			/* PS GIC */

static void Example_CallBack(void *CallBackRef, u32 IrqMask, int *IgnorePtr)
{

	if (IrqMask & XAXICDMA_XR_IRQ_ERROR_MASK) {
		Error = 1;
	}

	if (IrqMask & XAXICDMA_XR_IRQ_IOC_MASK) {
		Done = 1;
	}

}

int SetupIntrSystem(XScuGic *GicPtr, XAxiCdma  *DmaPtr)
{
	int Status;

	Xil_ExceptionInit();

	// Connect the interrupt controller interrupt handler to the hardware
	// interrupt handling logic in the processor.
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
			     (Xil_ExceptionHandler)XScuGic_InterruptHandler,
			     GicPtr);

	// Connect a device driver handler that will be called when an interrupt
	// for the device occurs, the device driver handler performs the specific
	// interrupt processing for the device

	Status = XScuGic_Connect(GicPtr,
			XPAR_FABRIC_AXI_CDMA_0_CDMA_INTROUT_INTR,
				 (Xil_InterruptHandler)XAxiCdma_IntrHandler,
				 (void *)DmaPtr);
	if (Status != XST_SUCCESS)
		return XST_FAILURE;

	// Enable the interrupt for the device
	XScuGic_Enable(GicPtr, XPAR_FABRIC_AXI_CDMA_0_CDMA_INTROUT_INTR);

	return XST_SUCCESS;
}

int menu(void)
{
	int select_1;
	printf("1. From DDR3 to BRAM transfer \n");
	printf("2. DATA Mover BRAM RUN (CTRL) \n");
	printf("3. read from BRAM1 (REG) \n");
	printf("4. Exit \n");

	scanf("%d", &select_1);

	return(select_1);
}

int main (void) {
	//matbi
    int read_data;
    XTime tStart, tEnd;
	int ii;
	int data;
	int *write_buf;
	write_buf = (int *) malloc(sizeof(int) * MEM_DEPTH);
	//
	unsigned int  OT_RSLT_SW[NUM_CORE] = {0,}; // 32b init 0
	unsigned int  OT_RSLT_HW[NUM_CORE] = {0,};
	unsigned char IN_NODE[NUM_CORE]; // 8b
	unsigned char IN_WEGT[NUM_CORE]; // 8b
	int core;

	uint8_t select;
	int i;
	//int CDMA_Status;
    int numofbytes;
    int num_cnt = 2;
    u8 * source_0, * source_1;
    u8 * cdma_memory_source, * cdma_memory_destination_0, * cdma_memory_destination_1;
    // int32_t software_cycles, interrupt_cycles, polled_cycles;
    int test_done = 0;

	// UART related definitions
    int Status;
	XUartPs_Config *Config;

	// PS Timer related definitions
	//volatile u32 CntValue1;
	XScuTimer_Config *ConfigPtr;
	XScuTimer *TimerInstancePtr = &Timer;

    // CDMA related definitions
	XAxiCdma xcdma;
    XAxiCdma_Config * CdmaCfgPtr;

	// PS Interrupt related definitions
	XScuGic_Config *GicConfig;

	// Initialize UART
	// Look up the configuration in the config table, then initialize it.
	Config = XUartPs_LookupConfig(XPAR_PS7_UART_0_DEVICE_ID);
	if (NULL == Config) {
		return XST_FAILURE;
	}

	Status = XUartPs_CfgInitialize(&Uart_PS, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Initialize timer counter
	ConfigPtr = XScuTimer_LookupConfig(TIMER_DEVICE_ID);

	Status = XScuTimer_CfgInitialize(TimerInstancePtr, ConfigPtr,
				 ConfigPtr->BaseAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Initialize GIC
	GicConfig = XScuGic_LookupConfig(INTC_DEVICE_INT_ID);
	if (NULL == GicConfig) {
		xil_printf("XScuGic_LookupConfig(%d) failed\r\n",
				INTC_DEVICE_INT_ID);
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(&Gic, GicConfig,
				       GicConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("XScuGic_CfgInitialize failed\r\n");
		return XST_FAILURE;
	}

	// Disable DCache
	Xil_DCacheDisable();

	// Set options for timer/counter 0
	// Load the timer counter register.
	XScuTimer_LoadTimer(TimerInstancePtr, TIMER_LOAD_VALUE);

	// Start the Scu Private Timer device.
	XScuTimer_Start(TimerInstancePtr);

    print("-- Simple DMA Design Example --\r\n");

	// Get a snapshot of the timer counter value before it's started
	//CntValue1 = XScuTimer_GetCounterValue(TimerInstancePtr);

	//xil_printf("Above message printing took %d clock cycles\r\n", TIMER_LOAD_VALUE-CntValue1);

	// Setup DMA Controller
    CdmaCfgPtr = XAxiCdma_LookupConfig(XPAR_AXI_CDMA_0_DEVICE_ID);
   	if (!CdmaCfgPtr) {
   		return XST_FAILURE;
   	}

   	Status = XAxiCdma_CfgInitialize(&xcdma , CdmaCfgPtr, CdmaCfgPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
		xil_printf("Status=%x\r\n",Status);
	}

	print("Central DMA Initialized\r\n");

	print("Setting up interrupt system\r\n");
	Status = SetupIntrSystem(&Gic, &xcdma);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Xil_ExceptionEnable();

	print("Enter number of words you want to transfer between 1 and 8192\r\n");

	scanf("%d", &numofbytes);
	printf("%d \n",numofbytes);

    select = menu();
	source_0 = (u8 *)DDR_MEMORY_0;
	source_1 = (u8 *)DDR_MEMORY_1;
	//cdma_memory_source = (u8 *)DDR_MEMORY;
	//destination = (u8 *)PROCESSOR_BRAM_MEMORY;
	cdma_memory_destination_0 = (u8 *)CDMA_BRAM_MEMORY_0; // for CDMA to access the memory
	cdma_memory_destination_1 = (u8 *)CDMA_BRAM_MEMORY_1;

    test_done = 0;

    while(test_done==0)
       {
   		if(select == 1){
   			// Initialize src memory
			for (ii=0; ii<numofbytes; ii++){
				*(source_0+ii) = ii;
				//printf("address: %p, value: %d \n", &source_0[ii], source_0[ii]);
			}
			for (ii=0; ii<numofbytes; ii++){
				*(source_1+ii) = ii;
				//printf("address: %p, value: %d \n", &source_1[ii], source_1[ii]);
			}
			// setting up for interrupt driven DMA
			Error = 0;
			Done = 0;

			print("DMA in interrupt mode\r\n");
			print("DDR to BRAM Transfer start\r\n");
			//시간 측정
			XTime_GetTime(&tStart);
			//ddr to bram0
			XAxiCdma_IntrEnable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
			Status = XAxiCdma_SimpleTransfer(&xcdma, (u32)source_0, (u32) cdma_memory_destination_0, numofbytes, Example_CallBack, (void *) &xcdma);
			//ddr to bram1
			XAxiCdma_IntrEnable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
			Status = XAxiCdma_SimpleTransfer(&xcdma, (u32)source_1, (u32) cdma_memory_destination_1, numofbytes, Example_CallBack, (void *) &xcdma);

			XTime_GetTime(&tEnd);

			//while ((Done==0) & (Error==0));

			if (Error != 0x0) {
				xil_printf("Error Code = %x\r\n",XAxiCdma_GetError(&xcdma));
				XAxiCdma_Reset(&xcdma);
			}
			else {
				printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
				printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
				print("DDR to BRAM Transfer finish\r\n");
				Error = 0; // reset for interrupt mode transfer
			}
			Error = 0;
			Done = 0;

   		} else if (select == 2){

   			XTime_GetTime(&tStart);
   			Xil_Out32((XPAR_ACCELERATOR_0_BASEADDR) + (CTRL_REG*4), (u32)(0x00000000)); // Clear
			// check IDLE
			do{
				read_data = Xil_In64((XPAR_ACCELERATOR_0_BASEADDR) + (STATUS_REG*4));
			} while( (read_data & IDLE) != IDLE);
			// start core
			printf("Accelerator Start\n");
			Xil_Out32((XPAR_ACCELERATOR_0_BASEADDR) + (CTRL_REG*4), (u32)(numofbytes | 0x80000000)); // MSB run //num_cnt 1로해서 한번만 돌게함 numofbyte에서 바꿈.
			// wait donee
			do{
				read_data = Xil_In64((XPAR_ACCELERATOR_0_BASEADDR) + (STATUS_REG*4));
			} while( (read_data & DONE) != DONE );
			printf("Accelerator Done\n");

			OT_RSLT_HW[0] = Xil_In64((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_0_REG*AXI_DATA_BYTE));
    		OT_RSLT_HW[1] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_1_REG*AXI_DATA_BYTE));
    		OT_RSLT_HW[2] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_2_REG*AXI_DATA_BYTE));
    		OT_RSLT_HW[3] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_3_REG*AXI_DATA_BYTE));
			OT_RSLT_HW[4] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_4_REG*AXI_DATA_BYTE));
    		OT_RSLT_HW[5] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_5_REG*AXI_DATA_BYTE));
    		OT_RSLT_HW[6] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_6_REG*AXI_DATA_BYTE));
    		OT_RSLT_HW[7] = Xil_In32((XPAR_ACCELERATOR_0_BASEADDR) + (RESULT_7_REG*AXI_DATA_BYTE));

    		XTime_GetTime(&tEnd);
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));

    		for (ii=0; ii<8; ii++){
    						printf("%d \n", OT_RSLT_HW[ii]);
    		}


   		} else if (select == 3){

			printf("SW test\n");
    		XTime_GetTime(&tStart);
    		for(i=0; i< 1 ; i++){

//    			OT_RSLT_SW[i] = 0; // init
    			// Data Loading
    			IN_NODE[0] = *(source_0+0);
    			IN_NODE[1] = *(source_0+1);
    			IN_NODE[2] = *(source_0+2);
    			IN_NODE[3] = *(source_0+3);
    			IN_NODE[4] = *(source_0+4);
    			IN_NODE[5] = *(source_0+5);
    			IN_NODE[6] = *(source_0+6);
    			IN_NODE[7] = *(source_0+7);
    			IN_WEGT[0] = *(source_1+0);
    			IN_WEGT[1] = *(source_1+1);
    			IN_WEGT[2] = *(source_1+2);
    			IN_WEGT[3] = *(source_1+3);
    			IN_WEGT[4] = *(source_1+4);
    			IN_WEGT[5] = *(source_1+5);
    			IN_WEGT[6] = *(source_1+6);
    			IN_WEGT[7] = *(source_1+7);
    			// Cal
    			for(core = 0; core < 8; core ++){
    				OT_RSLT_SW[core] = IN_NODE[core] * IN_WEGT[core];
					printf("%d \n", OT_RSLT_SW[core]);
    			}
    		}
    		XTime_GetTime(&tEnd);
    		printf("LAB22_MATBI_0 SW Done\n");
    		printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    		printf("Output took %.2f us.\n",
    		       1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));


   		} else if (select == 4){

   				test_done = 1;

   		} else {


   		}
		if(test_done)
			break;

		select = menu();
    }
    print("-- Exiting main() --\r\n");
    return 0;
}
