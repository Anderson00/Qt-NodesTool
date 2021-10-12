#include <iostream>
#include <unicorn/unicorn.h>

// code to be emulated
#define X86_CODE32 "\x41\x4a" // INC ecx; DEC edx

#define ADDRESS 0x1000000

#pragma code_seg(".my_data1")
int soma(int a, int b){
    return a+b;
}


int main(int argc, char *argv[]){

    uc_engine *uc;
    uc_err err;

    err = uc_open(UC_ARCH_X86, UC_MODE_32, &uc);
    if (err != UC_ERR_OK) {
        printf("Failed on uc_open() with error returned: %u\n", err);
        return -1;
    }

    uc_mem_map(uc, ADDRESS, 2 * 1024 * 1024, UC_PROT_ALL);

    // write machine code to be emulated to memory
    if (uc_mem_write(uc, ADDRESS, X86_CODE32, sizeof(X86_CODE32) - 1)) {
        printf("Failed to write emulation code to memory, quit!\n");
        return -1;
    }

    uc_close(uc);

    return 0;
}
