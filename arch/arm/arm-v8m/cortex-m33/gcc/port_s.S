#include "tos_config.h"

    .global port_int_disable
    .global port_int_enable

    .global port_cpsr_save
    .global port_cpsr_restore

    .global port_sched_start
    .global port_context_switch
    .global port_irq_context_switch

    .global port_clz

    .global PendSV_Handler

#if TOS_CFG_TRUSTZONE_EN > 0u
	.global port_secure_ctx_alloc
	.global port_secure_ctx_free
	.global port_secure_ctx_free_curr
	.global port_secure_ctx_init
	.global SVC_Handler
#endif

    .extern k_curr_task
    .extern k_next_task


.equ SCB_VTOR,              0xE000ED08
.equ NVIC_INT_CTRL,         0xE000ED04
.equ NVIC_SYSPRI14,         0xE000ED22
.equ NVIC_PENDSV_PRI,       0xFF
.equ NVIC_PENDSVSET,        0x10000000

#if TOS_CFG_TRUSTZONE_EN > 0u
.equ PORT_SVC_SECURE_CTX_ALLOC, 0
.equ PORT_SVC_SECURE_CTX_FREE,  1
.equ PORT_SVC_SECURE_CTX_INIT,	2
.equ K_SECURE_CTX_INVALID_ID, 0
#endif



   .text
   .align 2
   .thumb
   .syntax unified


.type port_int_disable, %function
port_int_disable:
    CPSID   I
    BX      LR


.type port_int_enable, %function
port_int_enable:
    CPSIE   I
    BX      LR


.type port_cpsr_save, %function
port_cpsr_save:
    MRS     R0, PRIMASK
    CPSID   I
    BX      LR


.type port_cpsr_restore, %function
port_cpsr_restore:
    MSR     PRIMASK, R0
    BX      LR


.type port_clz, %function
port_clz:
    CLZ     R0, R0
    BX      LR


.thumb_func
.type port_sched_start, %function
port_sched_start:
    CPSID   I

    @ set pendsv priority lowest
    @ otherwise trigger pendsv in port_irq_context_switch will cause a context switch in irq
    @ that would be a disaster
    MOVW    R0, #:lower16:NVIC_SYSPRI14
    MOVT    R0, #:upper16:NVIC_SYSPRI14

    MOVW    R1, #:lower16:NVIC_PENDSV_PRI
    MOVT    R1, #:upper16:NVIC_PENDSV_PRI
    STRB    R1, [R0]

    MOVW    R0, #:lower16:SCB_VTOR
    MOVT    R0, #:upper16:SCB_VTOR
    LDR     R0, [R0]
    LDR     R0, [R0]
    MSR     MSP, R0

    MOVW    R0, #:lower16:k_curr_task
    MOVT    R0, #:upper16:k_curr_task

    @ k_curr_task = k_next_task;
    MOVW    R1, #:lower16:k_next_task
    MOVT    R1, #:upper16:k_next_task
    LDR     R2, [R1]
    STR     R2, [R0]

    @ sp = k_next_task->sp
    LDR     R0, [R2]
    @ PSP = sp
    MSR     PSP, R0

    MRS     R0, CONTROL
    ORR     R0, R0, #2
    MSR     CONTROL, R0

    ISB

	#if TOS_CFG_TRUSTZONE_EN > 0u
	LDMFD	SP!, {R0 - R2}
	@ ignore task's secure context, should be 0
	MSR		PSPLIM, R1
	@ ignore EXC_RETURN
	#endif

    @ restore r4-11 from new process stack
    LDMFD    SP!, {R4 - R11}

    #if (defined(__VFP_FP__) && !defined(__SOFTFP__)) && (TOS_CFG_TRUSTZONE_EN == 0u)
    @ ignore EXC_RETURN the first switch
    LDMFD   SP!, {R0}
    #endif

    @ restore r0, r3
    LDMFD    SP!, {R0 - R3}
    @ load R12 and LR
    LDMFD    SP!, {R12, LR}    
    @ load PC and discard xPSR
    LDMFD    SP!, {R1, R2}

    CPSIE    I
    BX       R1


.thumb_func
.type port_context_switch, %function
port_context_switch:
    LDR     R0, =NVIC_INT_CTRL
    LDR     R1, =NVIC_PENDSVSET
    STR     R1, [R0]
    BX      LR


.thumb_func
.type port_irq_context_switch, %function
port_irq_context_switch:
    LDR     R0, =NVIC_INT_CTRL
    LDR     R1, =NVIC_PENDSVSET
    STR     R1, [R0]
    BX      LR


.thumb_func
.type PendSV_Handler, %function
PendSV_Handler:
    CPSID   I

    #if TOS_CFG_TRUSTZONE_EN > 0u
    @ R0 contains k_curr_secure_ctx
	MOVW    R3, #:lower16:k_curr_secure_ctx
    MOVT    R3, #:upper16:k_curr_secure_ctx
    LDR		R0, [R3]
	MOVW    R3, #:lower16:k_curr_task
    MOVT    R3, #:upper16:k_curr_task
    @ R1 contains k_curr_task
    LDR		R1, [R3]
	MRS		R2, PSP
	@ k_curr_secure_ctx = 0, no secure context to save
	CBZ		R0, _context_save_ns
	PUSH	{R0 - R2, LR}
	BL		secure_ctx_save
	POP		{R0 - R3}
	MOV		LR, R3
	@ test bit[6] of EXC_RETURN, determine whether non-secure stack is used
	LSLS	R1, R3, #25
	@ non-secure stack is used, save NS context
	BPL		_context_save_ns
	@ secure stack is used, only save PSPLIM, PSP, LR
	MOVW    R5, #:lower16:k_curr_task
    MOVT    R5, #:upper16:k_curr_task
    LDR		R1, [R5]
	SUBS	R2, R2, #12
	STR		R2, [R1]
	MRS		R1, PSPLIM
	STMIA	R2!, {R0, R1, R3}
	B		_context_restore

_context_save_ns:
    #endif

    MRS     R0, PSP

_context_save:
    @ R0-R3, R12, LR, PC, xPSR is saved automatically here
    #if (defined(__VFP_FP__) && !defined(__SOFTFP__))
    @ is it extended frame?
    TST     LR, #0x10
    IT      EQ
    VSTMDBEQ  R0!, {S16 - S31}
    @ S0 - S16, FPSCR saved automatically here

	#if TOS_CFG_TRUSTZONE_EN == 0u
    @ save EXC_RETURN
    STMFD   R0!, {LR}
    #endif
    #endif

    @ save remaining regs r4 - 11 on process stack
    STMFD   R0!, {R4 - R11}
    #if TOS_CFG_TRUSTZONE_EN > 0u
	MOVW    R3, #:lower16:k_curr_secure_ctx
    MOVT    R3, #:upper16:k_curr_secure_ctx
    LDR		R1, [R3]
    MRS 	R2, PSPLIM
	STMFD	R0!, {R1, R2, LR}
    #endif

    @ k_curr_task->sp = PSP;
    MOVW    R5, #:lower16:k_curr_task
    MOVT    R5, #:upper16:k_curr_task
    LDR     R6, [R5]
    @ R0 is SP of process being switched out
    STR     R0, [R6]

_context_restore:
    @ k_curr_task = k_next_task;
    MOVW    R1, #:lower16:k_next_task
    MOVT    R1, #:upper16:k_next_task
    LDR     R2, [R1]
    STR     R2, [R5]

  	#if TOS_CFG_TRUSTZONE_EN > 0u
  	@ R3 contains PSP
	LDR		R3, [R2]
	@ R0 = task's secure context, R1 = PSPLIM, R4 = LR
	LDMIA	R3!, {R0, R1, R4}
	MSR 	PSPLIM, R1
	MOVW    R5, #:lower16:k_curr_secure_ctx
    MOVT    R5, #:upper16:k_curr_secure_ctx
    STR		R0, [R5]
    CBZ		R0, _context_restore_ns
    @ R1 = k_next_task
    MOV		R1, R2
    PUSH	{R2 - R4}
    BL		secure_ctx_load
    POP		{R2 - R4}
    MOV		LR, R4
	LSLS	R1, R4, #25
	BPL		_context_restore_ns
	MSR		PSP, R3
	CPSIE   I
	BX		LR

_context_restore_ns:
  	#endif

    @ R0 = k_next_task->sp
    LDR     R0, [R2]
    #if TOS_CFG_TRUSTZONE_EN > 0u
    ADDS    R0, R0, #12
    MOV		LR, R4
    #endif

    @ restore R4 - R11
    LDMFD   R0!, {R4 - R11}

    #if (defined(__VFP_FP__) && !defined(__SOFTFP__))
    #if TOS_CFG_TRUSTZONE_EN == 0u
    @ restore EXC_RETURN
    LDMFD   R0!, {LR}
    #endif
    @ is it extended frame?
    TST     LR, #0x10
    IT      EQ
    VLDMIAEQ    R0!, {S16 - S31}
    #endif

    @ Load PSP with new process SP
    MSR     PSP, R0
    
    CPSIE   I

    @ R0-R3, R12, LR, PC, xPSR restored automatically here
    @ S0 - S16, FPSCR restored automatically here if FPCA = 1
    BX      LR


#if TOS_CFG_TRUSTZONE_EN > 0u

.type port_secure_ctx_alloc, %function
port_secure_ctx_alloc:
    SVC     #PORT_SVC_SECURE_CTX_ALLOC
    BX      LR


.type port_secure_ctx_free, %function
port_secure_ctx_free:
	@ R2 contains the task's top of stack
	LDR		R2, [R0]
	@ R1 contains the task's k_secure_ctx
	LDR		R1, [R2]
	CMP		R1, #K_SECURE_CTX_INVALID_ID
	IT		NE
    SVCNE	#PORT_SVC_SECURE_CTX_FREE
    BX      LR

.type port_secure_ctx_free_curr, %function
port_secure_ctx_free_curr:
	MOVW    R2, #:lower16:k_curr_secure_ctx
    MOVT    R2, #:upper16:k_curr_secure_ctx
	LDR		R1, [R2]
	CMP		R1, #K_SECURE_CTX_INVALID_ID
	IT		NE
    SVCNE	#PORT_SVC_SECURE_CTX_FREE
    BX      LR

.type port_secure_ctx_init, %function
port_secure_ctx_init:
	SVC		#PORT_SVC_SECURE_CTX_INIT
	BX		LR

.type SVC_Handler, %function
SVC_Handler:

	TST		LR, #4
	ITE		EQ
	MRSEQ	R0, MSP
	MRSNE	R0, PSP
    MOVW    R1, #:lower16:port_svc_handler_c
    MOVT    R1, #:upper16:port_svc_handler_c
	BX 		R1


#endif

.end

