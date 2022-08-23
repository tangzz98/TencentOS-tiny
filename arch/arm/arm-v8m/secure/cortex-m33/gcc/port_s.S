    .global port_clz


   .text
   .align 2
   .thumb
   .syntax unified


.type port_clz, %function
port_clz:
    CLZ     R0, R0
    BX      LR

.end

