//本代码来自于星之卡比镜之大迷宫反编译工程 include/agb_sram.h
#ifndef GUARD_AGB_SRAM_H
#define GUARD_AGB_SRAM_H

#include "global.h"

#define SRAM 0x0E000000

#ifndef __SRAM_DEBUG
#define SRAM_ADR                0x0e000000     // SRAM Start Address
#define SRAM_SIZE_256K          0x00008000     // 256KSRAM
#define SRAM_SIZE_512K          0x00010000     // 512KSRAM 
#else
#define SRAM_ADR                0x02018000
#define SRAM_SIZE_256K          0x00000400
#define SRAM_SIZE_512K          0x00000800
#endif
#define SRAM_RETRY_MAX          3              // Maximum retry number for the 
                                               // WriteSramEx function

/*------------------------------------------------------------------
The function group in this header file was also used in the old version.
The static variable area of the main unit WRAM is not used, but please 
note that compared to the function group AgbSramFast.h, access to 
SRAM is slower. 
--------------------------------------------------------------------*/

/*------------------------------------------------------------------*/
/*          Read Data                                               */
/*------------------------------------------------------------------*/

extern void ReadSram(const u8 *src, u8 *dst, u32 size) ;

/*   From the SRAM address specified by the argument, read "size" 
     byte of data to area starting from "dst" address in Work.
     <Arguments>
      const u8 *src  : Read source SRAM address (Address on AGB memory map) 
      u8 *dst        : Address of work area where read data is stored
                       (Address on AGB memory map) 
      u32 size       : Read size in bytes
     <Return Values>
      None
*/


/*------------------------------------------------------------------*/
/*          Write Data                                              */
/*------------------------------------------------------------------*/

extern void WriteSram(const u8 *src, u8 *dst, u32 size) ;

/*   From the work area address specified by the argument, write "size" 
     byte data to area starting from 'dst' address in SRAM.
     <Arguments>
      const u8 *src  : Write source work area address
      u8 *dst        : Write destination SRAM address
                       (Address on AGB memory map) 
      u32 size       : Write size in bytes
     <Return Values>
      None
*/
/*------------------------------------------------------------------*/
/*          Verify Data                                             */
/*------------------------------------------------------------------*/

extern u32 VerifySram(const u8 *src, u8 *tgt, u32 size) ;

/*   Verify "size" byte of data from "src" address in the work area
     and "tgt" address in SRAM. 
     If verify ends normally this function returns 0, if a verify error 
     occurs and the address where the error occurred is returned.
     <Arguments>
      const u8 *src  : Pointer to verify source work area address (original data) 
      u8 *tgt        : Pointer to verify target SRAM address
                      (write destination data, address on AGB memory map) 
      u32 size       : Verify size in bytes
     <Return Values>
      u32 errorAdr   : Normal end => 0
                       Verify error => Error address on device side
*/


/*------------------------------------------------------------------*/
/*          Write data & Verify                                     */
/*------------------------------------------------------------------*/

extern u32 WriteSramEx(const u8 *src, u8 *dst, u32 size) ;

/*  This function writes internally using WriteSram and then verifies using VerifySram.
    In case of an error, it retries a maximum of SRAM_RETRY_MAX times (defined by AgbSram.h). 
    
    <Argument> 
     const u8 *src  : Work area address of write source 
     u8 *dst        : SRAM address of write destination (address on AGB memory map)  
     u32 size       : Write size in number of bytes 
    <Return value> 
     u32 errorAdr   : Normal end => 0
                      Verify error => Error address on device side 
*/

#endif // GUARD_AGB_SRAM_H

//本代码来自于星之卡比镜之大迷宫反编译工程 src/agb_sram.c
#include "agb_sram.h"

const char gAgbSramLibVer[] = "NINTENDOSRAM_V113";

static void ReadSram_Core(const u8 *src, u8 *dest, u32 size)
{
    while (--size != -1)
        *dest++ = *src++;
}

void ReadSram(const u8 *src, u8 *dest, u32 size)
{
    const u16 *s;
    u16 *d;
    u16 readSramFast_Work[64];
    u16 size_;
    
    REG_WAITCNT = (REG_WAITCNT & ~3) | 3;
    s = (void *)((uintptr_t)ReadSram_Core);
    s = (void *)((uintptr_t)s & ~1);
    d = readSramFast_Work;
    size_ = ((uintptr_t)ReadSram - (uintptr_t)ReadSram_Core) / 2;
    while (size_ != 0)
    {
        *d++ = *s++;
        --size_;
    }
    ((void (*)(const u8 *, u8 *, u32))readSramFast_Work + 1)(src, dest, size);
}

void WriteSram(const u8 *src, u8 *dest, u32 size)
{
    REG_WAITCNT = (REG_WAITCNT & ~3) | 3;
    while (--size != -1)
        *dest++ = *src++;
}

static u32 VerifySram_Core(const u8 *src, u8 *dest, u32 size)
{
    while (--size != -1)
        if (*dest++ != *src++)
            return (u32)(dest - 1);
    return 0;
}

u32 VerifySram(const u8 *src, u8 *dest, u32 size)
{
    const u16 *s;
    u16 *d;
    u16 verifySramFast_Work[96];
    u16 size_;
    
    REG_WAITCNT = (REG_WAITCNT & ~3) | 3;
    s = (void *)((uintptr_t)VerifySram_Core);
    s = (void *)((uintptr_t)s & ~1);
    d = verifySramFast_Work;
    size_ = ((uintptr_t)VerifySram - (uintptr_t)VerifySram_Core) / 2;
    while (size_ != 0)
    {
        *d++ = *s++;
        --size_;
    }
    return ((u32 (*)(const u8 *, u8 *, u32))verifySramFast_Work + 1)(src, dest, size);
}

u32 WriteSramEx(const u8 *src, u8 *dest, u32 size)
{
    u8 i;
    u32 errorAddr;

    // try writing and verifying the data 3 times
    for (i = 0; i < SRAM_RETRY_MAX; ++i)
    {
        WriteSram(src, dest, size);
        errorAddr = VerifySram(src, dest, size);
        if (errorAddr == 0)
            break;
    }
    return errorAddr;
}
