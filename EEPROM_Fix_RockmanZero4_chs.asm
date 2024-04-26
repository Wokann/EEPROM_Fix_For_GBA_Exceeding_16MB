.gba
.create "./RockmanZero4_chs_eepromfix.gba",0x08000000
.close
.open "./RockmanZero4_chs.gba","./RockmanZero4_chs_eepromfix.gba",0x08000000

gEEPROMConfig               equ 0x0203D7B0 //RockmanZero4
EEPROM_SaveAddress          equ 0x0DFFFF00

EEPROM_Type                 equ 0x0882AF68 //RockmanZero4
EEPROM_Config512            equ EEPROM_Type + 0xC
EEPROM_Config8k             equ EEPROM_Config512 + 0xC

EEPROMConfigure             equ 0x08128BF8 //nothing to hack
DMA3Transfer                equ 0x08128C40 //nothing to hack
EEPROMRead                  equ 0x08128CC0 //need to hack
EEPROMWrite1                equ 0x08128D70 //nothing to hack
EEPROMWrite                 equ 0x08128D84 //need to hack
EEPROMCompare               equ 0x08128EE4 //nothing to hack
EEPROMWrite1_check          equ 0x08128F3C //nothing to hack

Hack_Address                equ 0x09060000


;.org EEPROM_Type
;    .asciiz "EEPROM_V126"
;.org EEPROM_Config512
;    .dw 0x200  :: .dh 0x40  :: .dh 0x300 :: .db 0x6 :: .db 0,0,0
;.org EEPROM_Config8k
;    .dw 0x2000 :: .dh 0x400 :: .dh 0x300 :: .db 0xE :: .db 0,0,0
/*
.org EEPROMRead + 0x52
    ldr r0,=EEPROMRead_hack
    mov pc,r0
.pool

.org EEPROMWrite + 0x86
    ldr r0,=EEPROMWrite_hack
    mov pc,r0
.pool

.org Hack_Address

.func EEPROMRead_hack
    ldr r4,=0x0DFFFF00
    ldr r0,=gEEPROMConfig
    ldr r0,[r0,0]
    ldrb r2,[r0,8]
@@Back:
    ldr r0,=(EEPROMRead + 0x52 + 0xA)
    mov pc,r0
.pool
.endfunc

.func EEPROMWrite_hack
    ldr r4,=0x0DFFFF00
    ldr r0,=gEEPROMConfig
    ldr r0,[r0,0]
    ldrb r2,[r0,8]
@@Back:
    ldr r0,=(EEPROMWrite + 0x86 + 0xA)
    mov pc,r0
.pool
.endfunc
*/
.org EEPROMRead + 0x2
    ldr r5,=EEPROMRead_hack
    mov pc,r5
.pool

.org EEPROMWrite + 0x2
    ldr r5,=EEPROMWrite_hack
    mov pc,r5
.pool

.org Hack_Address
.func DMA3Transfer_copy
    push {r4, r5, r6, lr}
    lsl r2, r2, #0x10
    lsr r2, r2, #0x10
    ldr r4, =0x04000208
    ldrh r3, [r4]
    add r6, r3, #0
    mov r3, #0
    strh r3, [r4]
    ldr r5, =0x04000204
    ldrh r4, [r5]
    ldr r3, =0xF8FF
    and r4, r3
    ldr r3, =gEEPROMConfig
    ldr r3, [r3]
    ldrh r3, [r3, #6]
    orr r4, r3
    strh r4, [r5]
    ldr r3, =0x040000D4
    str r0, [r3]
    ldr r0, =0x040000D8
    str r1, [r0]
    ldr r1, =0x040000DC
    mov r0, #0x80
    lsl r0, r0, #0x18
    orr r2, r0
    str r2, [r1]
    add r1, #2
    mov r2, #0x80
    lsl r2, r2, #8
    add r0, r2, #0
    ldrh r1, [r1]
    and r0, r1
    cmp r0, #0
    beq @@End
    ldr r2, =0x040000DE
    mov r0, #0x80
    lsl r0, r0, #8
    add r1, r0, #0
 @@Loop1:
    ldrh r0, [r2]
    and r0, r1
    cmp r0, #0
    bne @@Loop1
 @@End:
    ldr r0, =0x04000208
    strh r6, [r0]
    pop {r4, r5, r6}
    pop {r0}
    bx r0
 .pool
.endfunc

.func EEPROMRead_hack
    nop    ;push {r4, r5, r6, lr}
    sub sp, #0x88
    add r5, r1, #0
    lsl r0, r0, #0x10
    lsr r3, r0, #0x10
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrh r0, [r0, #4]
    cmp r3, r0
    bcc @@InRange
    ldr r0, =0x80FF
    b @@End
 .pool
 @@InRange:
    ldr r1, =gEEPROMConfig
    ldr r0, [r1]
    ldrb r0, [r0, #8]
    lsl r0, r0, #1
    mov r4, sp
    add r2, r0, r4
    add r2, #2
    mov r0, #0
    strh r0, [r2, #2]
    strh r0, [r2]
    mov r4, #0
    ldr r0, [r1]
    ldrb r0, [r0, #8]
    cmp r4, r0
    bcs @@Batch1
    mov r6, #1
 @@Loop1:
    add r0, r3, #0
    and r0, r6
    strh r0, [r2]
    sub r2, #2
    lsr r3, r3, #1
    add r0, r4, #1
    lsl r0, r0, #0x18
    lsr r4, r0, #0x18
    ldr r0, [r1]
    ldrb r0, [r0, #8]
    cmp r4, r0
    bcc @@Loop1
 @@Batch1:
    mov r0, #1
    strh r0, [r2]
    sub r2, #2
    strh r0, [r2]
    ldr r4, =EEPROM_SaveAddress
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrb r2, [r0, #8]
    add r2, #3
    mov r0, sp
    add r1, r4, #0
    bl DMA3Transfer_copy
    add r0, r4, #0
    mov r1, sp
    mov r2, #0x44
    bl DMA3Transfer_copy
    add r2, sp, #8
    add r5, #6
    mov r4, #0
    mov r6, #1
 @@Loop2:
    mov r1, #0
    mov r3, #0
 @@Loop3:
    lsl r1, r1, #0x11
    ldrh r0, [r2]
    and r0, r6
    lsr r1, r1, #0x10
    orr r1, r0
    add r2, #2
    add r0, r3, #1
    lsl r0, r0, #0x18
    lsr r3, r0, #0x18
    cmp r3, #0xf
    bls @@Loop3
    strh r1, [r5]
    sub r5, #2
    add r0, r4, #1
    lsl r0, r0, #0x18
    lsr r4, r0, #0x18
    cmp r4, #3
    bls @@Loop2
    mov r0, #0
 @@End:
    add sp, #0x88
    pop {r4, r5, r6}
    pop {r1}
    bx r1
 .pool
.endfunc

.func EEPROMWrite_hack
    nop    ;push {r4, r5, r6, r7, lr}
    mov r7, r8
    push {r7}
    sub sp, #0xb0
    add r6, r1, #0
    lsl r0, r0, #0x10
    lsr r5, r0, #0x10
    lsl r2, r2, #0x18
    lsr r2, r2, #0x18
    mov r8, r2
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrh r0, [r0, #4]
    cmp r5, r0
    bcc @@InRange
    ldr r0, =0x80FF
    b @@End1
 .pool
 @@InRange:
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrb r0, [r0, #8]
    lsl r0, r0, #1
    mov r1, sp
    add r3, r0, r1
    add r3, #0x84
    mov r0, #0
    strh r0, [r3]
    sub r3, #2
    mov r4, #0
    mov r7, #1
 @@Loop1:
    ldrh r2, [r6]
    add r6, #2
    mov r1, #0
 @@Loop2:
    add r0, r2, #0
    and r0, r7
    strh r0, [r3]
    sub r3, #2
    lsr r2, r2, #1
    add r0, r1, #1
    lsl r0, r0, #0x18
    lsr r1, r0, #0x18
    cmp r1, #0xf
    bls @@Loop2
    add r0, r4, #1
    lsl r0, r0, #0x18
    lsr r4, r0, #0x18
    cmp r4, #3
    bls @@Loop1
    mov r4, #0
    ldr r0, =gEEPROMConfig
    add r1, r0, #0
    ldr r0, [r0]
    ldrb r0, [r0, #8]
    cmp r4, r0
    bcs @@Batch1
    mov r2, #1
 @@Loop3:
    add r0, r5, #0
    and r0, r2
    strh r0, [r3]
    sub r3, #2
    lsr r5, r5, #1
    add r0, r4, #1
    lsl r0, r0, #0x18
    lsr r4, r0, #0x18
    ldr r0, [r1]
    ldrb r0, [r0, #8]
    cmp r4, r0
    bcc @@Loop3
 @@Batch1:
    mov r0, #0
    strh r0, [r3]
    sub r3, #2
    mov r6, #1
    strh r6, [r3]
    ldr r4, =EEPROM_SaveAddress
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrb r2, [r0, #8]
    add r2, #0x43
    mov r0, sp
    add r1, r4, #0
    bl DMA3Transfer_copy
    mov r5, #0
    add r2, sp, #0xa4
    strh r5, [r2]
    mov r1, sp
    add r1, #0xa6
    ldr r0, =0x04000006
    ldrh r0, [r0]
    strh r0, [r1]
    add r0, sp, #0xac
    str r5, [r0]
    ldrh r0, [r2]
    cmp r0, #0
    bne @@Batch2
    ldrh r0, [r4]
    and r0, r6
    cmp r0, #0
    beq @@Batch2
    ldrh r0, [r2]
    add r0, #1
    strh r0, [r2]
    mov r0, r8
    cmp r0, #0
    beq @@End2
 @@Batch2:
    add r3, sp, #0xa8
    ldr r0, =0x04000006
    ldrh r0, [r0]
    strh r0, [r3]
    mov r4, sp
    add r4, #0xa6
    ldrh r1, [r3]
    ldrh r0, [r4]
    cmp r1, r0
    beq @@Batch3
    ldrh r1, [r3]
    ldrh r0, [r4]
    cmp r1, r0
    bls @@Batch4
    add r2, sp, #0xac
    ldrh r1, [r3]
    ldrh r0, [r4]
    sub r1, r1, r0
    ldr r0, [r2]
    add r1, r1, r0
    str r1, [r2]
    b @@Batch5
 .pool
 @@Batch4:
    add r2, sp, #0xac
    add r0, sp, #0xa8
    ldrh r0, [r0]
    add r0, #0xe4
    mov r1, sp
    add r1, #0xa6
    ldrh r1, [r1]
    sub r0, r0, r1
    ldr r1, [r2]
    add r0, r0, r1
    str r0, [r2]
 @@Batch5:
    add r0, sp, #0xac
    ldr r0, [r0]
    cmp r0, #0x88
    bls @@Batch6
    add r0, sp, #0xa4
    ldrh r0, [r0]
    cmp r0, #0
    bne @@End2
    ldr r0, =EEPROM_SaveAddress
    ldrh r0, [r0]
    mov r1, #1
    and r0, r1
    cmp r0, #0
    bne @@End2
    ldr r5, =0xC001
    b @@End2
 .pool
 @@Batch6:
    mov r0, sp
    add r0, #0xa6
    add r1, sp, #0xa8
    ldrh r1, [r1]
    strh r1, [r0]
 @@Batch3:
    add r2, sp, #0xa4
    ldrh r0, [r2]
    cmp r0, #0
    bne @@Batch2
    ldr r0, [pc, #0x24]
    mov r1, #1
    ldrh r0, [r0]
    and r1, r0
    cmp r1, #0
    beq @@Batch2
    ldrh r0, [r2]
    add r0, #1
    strh r0, [r2]
    mov r1, r8
    cmp r1, #0
    bne @@Batch2
 @@End2:
    add r0, r5, #0
 @@End1:
    add sp, #0xb0
    pop {r3}
    mov r8, r3
    pop {r4, r5, r6, r7}
    pop {r1}
    bx r1
 .pool
.endfunc

EndHack:
    .fill (0x0A000000 - EndHack),0x00

.close