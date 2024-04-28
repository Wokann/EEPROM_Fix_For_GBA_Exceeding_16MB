.gba
.create "./SD_Gundam_G_Generation_Advance_chs_1.4_eepromfix.gba",0x08000000
.close
.open "./SD_Gundam_G_Generation_Advance_chs_1.4.gba","./SD_Gundam_G_Generation_Advance_chs_1.4_eepromfix.gba",0x08000000

gEEPROMConfig               equ 0x030044E4
EEPROM_SaveAddress          equ 0x0DFFFF00

EEPROM_Type                 equ 0x08FCD61C
EEPROM_Config512            equ EEPROM_Type + 0xC
EEPROM_Config8k             equ EEPROM_Config512 + 0xC

EEPROMConfigure             equ 0x08084CC8 //nothing to hack
DMA3Transfer                equ 0x08084D10 //nothing to hack
EEPROMRead                  equ 0x08084D90 //need to hack
EEPROMWrite1                equ 0x08084E40 //nothing to hack
EEPROMWrite                 equ 0x08084E54 //need to hack
EEPROMCompare               equ 0x08084FB4 //nothing to hack
EEPROMWrite1_check          equ 0x0808500C //nothing to hack

Hack_Address                equ 0x09218380

;.org 0x080000A0
;   .asciiz "CRAFTSWORD HB3CJ"
;.org EEPROM_Type
;    .asciiz "EEPROM_V126" ;不做修改，会影响gbarunner2的自动存档补丁识别
;.org EEPROM_Config512
;    .dw 0x200  :: .dh 0x40  :: .dh 0x300 :: .db 0x6 :: .db 0,0,0
;.org EEPROM_Config8k
;    .dw 0x2000 :: .dh 0x400 :: .dh 0x300 :: .db 0xE :: .db 0,0,0

.org EEPROMRead + 0x10
    add sp,0x88            ;避开前0x10字节，是因为gbarunner2通过识别eeprom函数前0x10字节并替换sram补丁
    mov r1,r5              ;为兼容gbarunner2运行，留出这部分数据不做改动，否则会白屏无法运行
    mov r0,r3              ;ezode的auto模式为通过文件头0xA0的game code识别clean rom的存档格式，故必须强制切换eeprom8k或sram才可运行（也可将game code改为铸剑3、蜡笔食都等32MB eeprom）
    pop r4-r6              ;到此处为止的代码为将数据还原回初始输入的r0、r1和堆栈（除lr）
    push r0-r2             ;r0用作跳转地址，r1用作读写标记
    mov r1,0               ;读取存档
    ldr r0,=Save_Fix
    mov pc,r0              ;跳至修复代码
 .pool
.func SRAMRead_hack
   pop r0-r2   ;push lr
   lsl r0,r0,0x10
   mov r2,r1
   lsr r0,r0,0xD
   mov r1,0xE0
   lsl r1,r1,0x14
   add r1,r0,r1
   add r1,7
   mov r3,0
 @@Loop1:
   ldrb r0,[r1,0]
   strb r0,[r2,0]
   add r3,1
   add r2,1
   sub r1,1
   cmp r3,7
   bls @@Loop1
   mov r0,0
   pop {r1}
   bx r1
.endfunc

.org EEPROMWrite + 0x10
    add sp,0xB0            ;避开前0x10字节，是因为gbarunner2通过识别eeprom函数前0x10字节并替换sram补丁
    mov r0,r1              ;为兼容gbarunner2运行，留出这部分数据不做改动，否则会白屏无法运行
    mov r1,r5              ;ezode的auto模式为通过文件头0xA0的game code识别clean rom的存档格式，故必须强制切换eeprom8k或sram才可运行（也可将game code改为铸剑3、蜡笔食都等32MB eeprom）
    mov r2,r7
    pop r4-r7              ;到此处为止的代码为将数据还原回初始输入的r0、r1和堆栈（除lr）
    push r0-r2             ;r0用作跳转地址，r1记录读写类别
    mov r1,1               ;写入存档
    ldr r0,=Save_Fix
    mov pc,r0              ;跳至修复代码
 .pool
.func SRAMWrite_hack
   pop r0-r2   ;push lr
   lsl r0,r0,0x10
   mov r2,r1
   lsr r0,r0,0xD
   mov r1,0xE0
   lsl r1,r1,0x14
   add r1,r0,r1
   add r1,7
   mov r3,0
 @@Loop1:
   ldrb r0,[r2,0]
   strb r0,[r1,0]
   add r3,1
   add r2,1
   sub r1,1
   cmp r3,7
   bls @@Loop1
   mov r0,0
   pop {r1}
   bx r1
.endfunc

.org Hack_Address
.func Save_Fix
   push r1
   ldr r0,=0x0203FFFC
   ldr r0,[r0]
   lsl r0,r0,8
   lsr r0,r0,8
   cmp r0,0
   bne @@RamCanNotBeUsed

 @@RamCanBeUsed:
   ldr r0,=0x0203FFFC
   ldrb r0,[r0,3]
   mov r1,1
   and r0,r1
   cmp r0,1
   beq @@SkipHardware_Check
 @@DoHardware_Check:
   bl SaveHardware_Check
   lsl r0,r0,1
   add r0,1
   ldr r1,=0x0203FFFC
   strb r0,[r1,3]
 @@SkipHardware_Check:
   ldr r1,=0x0203FFFC
   ldrb r0,[r1,3]
   lsr r0,r0,1
   b @@CheckResult
 .pool

 @@RamCanNotBeUsed:
   bl SaveHardware_Check   ;检查0x0203FFFC-0x0203FFFF是否被使用，若无用则用于存储检查结果，以减少重复计算，
                           ;若已被使用，则每次均进行硬件检查。
                           ;检查硬件的结果若存入内存，则检查结果左移1位，将bit0设为1用作已经检查的标志位，再存入内存
                           ;后续计算需右移1位恢复检查结果的实际值                      
                           ;0b00(0x0):NoSaveHardware 0b01(0x1):HaveEEPROM
                           ;0b10(0x2):HaveSRAM       0b11(0x3):HaveEEPROM_SRAM
                           ;目前设置除了1，3固定使用eeprom外，其余都使用sram格式
 @@CheckResult:
   pop r1
   lsl r1,r1,0x1F
   lsr r1,r1,0x1F
   lsl r0,r0,0x1E
   lsr r0,r0,0x1E          ;获取硬件检查结果
   cmp r1,0                ;确认0-读取或1-写入存档
   bne @@SaveWrite
 @@SaveRead:
   cmp r0,1
   beq @@SaveType_EEPROMRead
   cmp r0,3
   beq @@SaveType_EEPROMRead
   b @@SaveType_SRAMRead
 @@SaveWrite:
   cmp r0,1
   beq @@SaveType_EEPROMWrite
   cmp r0,3
   beq @@SaveType_EEPROMWrite
   b @@SaveType_SRAMWrite

 @@SaveType_EEPROMRead:
   pop r0-r2
   bl EEPROMRead_hack
   b @@End
 @@SaveType_EEPROMWrite:
   pop r0-r2
   bl EEPROMWrite_hack
   b @@End
 @@SaveType_SRAMRead:
   ldr r0,=SRAMRead_hack
   mov pc,r0
 .pool
 @@SaveType_SRAMWrite:
   ldr r0,=SRAMWrite_hack
   mov pc,r0
 .pool

 @@End:
   pop r1
   bx r1
.endfunc

.func SaveHardware_Check
   push r3-r4,lr        ;bit0用作是否检查过的标志位，存放于0x0203FFFF
   mov r4,0b00         ;用于记录存档硬件情况，bit1(1-haveEEPROM),bit2(1-haveSRAM)
                        ;0b00(0x0):NoSaveHardware 0b01(0x1):HaveEEPROM
                        ;0b10(0x2):HaveSRAM       0b11(0x3):HaveEEPROM_SRAM
 @@SRAM_check:
   mov r1,0xE0
   lsl r1,r1,0x14       ;SRAM存档地址
 @@BackUpSRAM:
   ldrb r3,[r1]         ;备份该地址上第一个字节
   mov r0,0x55
   cmp r0,r3
   bne @@TestWriteSRAM
   mov r0,0xAA
 @@TestWriteSRAM:
   strb r0,[r1]         ;向该地址写入一字节0x1
   ldrb r2,[r1]         ;再向该地址读取一字节，
   cmp r2,r0            ;确认读写是否一致，以判断sram是否正常,对比至少2次，此处为第1次。
   bne @@EEPROM_check   ;sram异常，跳至检查eeprom
 @@HaveSRAM:
   strb r3,[r1]         ;sram正常，将备份的原字节还原
   add r4,0b10          ;记录SRAM标记
   b @@EEPROM_check

 @@EEPROM_check:
   sub sp,0x10
 @@BackUpEEPROM:
   mov r0,0
   add r1,sp,8
   bl EEPROMRead_hack
   ldr r0,[sp,0x8]                     ;检查备份的8字节是否与校验8字节相同
   ldr r1,=Strings_For_EEPROM_check
   ldr r1,[r1]
   cmp r0,r1
   bne @@UseStrings1
   ldr r0,[sp,0xC]
   ldr r1,=(Strings_For_EEPROM_check+4)
   ldr r1,[r1]
   cmp r0,r1
   beq @@UseStrings2
 @@UseStrings1:
   ldr r1,=Strings_For_EEPROM_check
   b @@TestWriteEEPROM
 @@UseStrings2:
   ldr r1,=(Strings_For_EEPROM_check+8)

 @@TestWriteEEPROM:
   push r1                             ;暂存用于校验的字符地址
   mov r0,0
   mov r2,1
   bl EEPROMWrite_hack                 ;写入校验8字节
   mov r0,0
   add r1,sp,4
   bl EEPROMRead_hack                  ;读取8字节
   pop r1
   ldr r1,[r1]
   ldr r0,[sp]
   cmp r0,r1                           ;对比字节
   bne @@End

 @@HaveEEPROM:
   mov r0,0
   add r1,sp,8
   mov r2,1
   bl EEPROMWrite_hack                 ;还原备份字节
   add r4,0b01

 @@End:
   add sp,0x10
   mov r0,r4
   pop r3-r4
   pop r1
   bx r1
 .pool
.endfunc

.align 4
.func Strings_For_EEPROM_check
   .byte 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07
   .byte 0x0F,0x0E,0x0D,0x0C,0x0B,0x0A,0x09,0x08
.endfunc

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

.func EEPROMRead_hack         ;u16 address, u16* data 
    push {r4, r5, r6, lr}
    sub sp, #0x88             ;u16 buffer[0x44]
    add r5, r1, #0            ;r5=data
    lsl r0, r0, #0x10
    lsr r3, r0, #0x10         ;r3=address
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrh r0, [r0, #4]         ;r0=gEEPROMConfig->size
    cmp r3, r0
    bcc @@InRange             ;if (address >= gEEPROMConfig->size)
    ldr r0, =0x80FF           ;return EEPROM_OUT_OF_RANGE;
    b @@End
 .pool
 @@InRange:
    ldr r1, =gEEPROMConfig
    ldr r0, [r1]
    ldrb r0, [r0, #8]
    lsl r0, r0, #1            ;r0=(gEEPROMConfig->address_width << 1)
    mov r4, sp                ;r4=&buffer
    add r2, r0, r4            ;r2=u16 ptr
    add r2, #2                ;r2=(gEEPROMConfig->address_width << 1)+&buffer+2
    mov r0, #0
    strh r0, [r2, #2]         ;ptr[1]=0
    strh r0, [r2]             ;ptr[0]=0
    mov r4, #0                ;r4=t1=0
    ldr r0, [r1]
    ldrb r0, [r0, #8]         ;r0=gEEPROMConfig->address_width
    cmp r4, r0
    bcs @@Batch1              ;for (t1 = 0; t1 < gEEPROMConfig->address_width; t1++)
    mov r6, #1
 @@Loop1:
    add r0, r3, #0            ;r0=address
    and r0, r6
    strh r0, [r2]             ;ptr[0]=1 & address
    sub r2, #2                ;r2=ptr-2
    lsr r3, r3, #1            ;r3=address/2
    add r0, r4, #1            
    lsl r0, r0, #0x18
    lsr r4, r0, #0x18         ;r4=t1++
    ldr r0, [r1]
    ldrb r0, [r0, #8]         ;r0=gEEPROMConfig->address_width
    cmp r4, r0                ;for (t1 = 0; t1 < gEEPROMConfig->address_width; t1++)
    bcc @@Loop1
 @@Batch1:
    mov r0, #1
    strh r0, [r2]             ;ptr[0]=1
    sub r2, #2                ;r2=ptr-2
    strh r0, [r2]             ;ptr[0]=1
    ldr r4, =EEPROM_SaveAddress
    ldr r0, =gEEPROMConfig
    ldr r0, [r0]
    ldrb r2, [r0, #8]
    add r2, #3                ;r2=gEEPROMConfig->address_width + 3
    mov r0, sp                ;r0=&buffer
    add r1, r4, #0            ;r1=0x0DFFFF00
    bl DMA3Transfer_copy      ;DMA3Transfer(buffer, (u16*)0xdffff00, gEEPROMConfig->address_width + 3)
    add r0, r4, #0            ;r0=0x0DFFFF00
    mov r1, sp                ;r1=&buffer
    mov r2, #0x44             ;r2=0x44
    bl DMA3Transfer_copy      ;DMA3Transfer((u16*)0xdffff00, buffer, 0x44)
    add r2, sp, #8            ;r2=u16* ptr=&buffer+2*4
    add r5, #6                ;r5=u16 data+2*3
    mov r4, #0                ;r4=t1=0
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
    push {r4, r5, r6, r7, lr}
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




;EndHack:
;    .fill (0x0A000000 - EndHack),0x00

.close