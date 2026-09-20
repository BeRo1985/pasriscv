// kvmtest: minimal KVM user space for RISC-V without libc. Runs a small guest in VS-mode and
// reports every exit: MMIO writes, SBI legacy console output and the final SBI shutdown.
#include <linux/kvm.h>

#define SYS_openat 56
#define SYS_ioctl 29
#define SYS_mmap 222
#define SYS_write 64
#define SYS_exit 93

static long sc(long n,long a,long b,long c,long d,long e,long f){
 register long a0 asm("a0")=a; register long a1 asm("a1")=b; register long a2 asm("a2")=c;
 register long a3 asm("a3")=d; register long a4 asm("a4")=e; register long a5 asm("a5")=f;
 register long a7 asm("a7")=n;
 asm volatile("ecall":"+r"(a0):"r"(a1),"r"(a2),"r"(a3),"r"(a4),"r"(a5),"r"(a7):"memory");
 return a0;
}
static void out(const char *s){ long n=0; while(s[n]) n++; sc(SYS_write,1,(long)s,n,0,0,0); }
static void hex(unsigned long v){ char b[19]; b[0]='0'; b[1]='x'; for(int i=0;i<16;i++){ int d=(v>>((15-i)*4))&15; b[2+i]=d<10?'0'+d:'a'+d-10; } b[18]=0; out(b); }
static void fail(const char *s,long r){ out("FAIL "); out(s); out(" "); hex(r); out("\n"); sc(SYS_exit,1,0,0,0,0,0); }

extern const unsigned char guest_start[],guest_end[];
asm(".section .rodata\n"
    ".balign 4\n"
    ".globl guest_start\n"
    "guest_start:\n"
    " li t0, 0\n"
    " li t1, 1\n"
    " li t2, 101\n"
    "1: add t0, t0, t1\n"
    " addi t1, t1, 1\n"
    " bne t1, t2, 1b\n"
    " li t3, 0x10000000\n"
    " sd t0, 0(t3)\n"                 // MMIO exit: 5050
    " auipc t4, 0\n"
    " li t5, 0x8000\n"
    " add t4, t4, t5\n"
    " li t6, 0x1234\n"
    " sd t6, 0(t4)\n"                 // a page KVM has not mapped yet: G-stage fault in KVM
    " ld a0, 0(t4)\n"
    " sd a0, 8(t3)\n"                 // MMIO exit: 0x1234
    " lla t0, 3f\n"
    " csrw stvec, t0\n"
    " li t0, 0x20\n"
    " csrs sie, t0\n"                 // STIE (the VS timer)
    " rdtime t1\n"
    " li t2, 100000\n"
    " add t1, t1, t2\n"
    " csrw 0x14d, t1\n"                // stimecmp, which is vstimecmp in the guest
    " csrsi sstatus, 2\n"
    "4: wfi\n"
    " j 4b\n"
    " .balign 4\n"
    "3: csrr t0, scause\n"
    " li t3, 0x10000000\n"
    " sd t0, 16(t3)\n"                // MMIO exit: scause of the timer interrupt
    " li t0, -1\n"
    " csrw 0x14d, t0\n"
    " li a7, 1\n"
    " li a0, 'O'\n"
    " ecall\n"                        // SBI legacy console putchar
    " li a0, 'K'\n"
    " ecall\n"
    " li a0, 10\n"
    " ecall\n"
    " li a7, 0x53525354\n"
    " li a6, 0\n"
    " li a0, 0\n"
    " li a1, 0\n"
    " ecall\n"                        // SBI SRST: shutdown
    "2: j 2b\n"
    ".globl guest_end\n"
    "guest_end:\n"
    ".text\n");

void _start(void){
 long kvm=sc(SYS_openat,-100,(long)"/dev/kvm",2,0,0,0);
 if(kvm<0) fail("open",kvm);
 long vm=sc(SYS_ioctl,kvm,KVM_CREATE_VM,0,0,0,0);
 if(vm<0) fail("KVM_CREATE_VM",vm);
 unsigned char *mem=(unsigned char*)sc(SYS_mmap,0,0x10000,3,0x22,-1,0);
 if((long)mem<0) fail("mmap",(long)mem);
 for(long i=0;i<guest_end-guest_start;i++) mem[i]=guest_start[i];
 struct kvm_userspace_memory_region region={0,0,0x80000000UL,0x10000,(unsigned long)mem};
 long r=sc(SYS_ioctl,vm,KVM_SET_USER_MEMORY_REGION,(long)&region,0,0,0);
 if(r<0) fail("KVM_SET_USER_MEMORY_REGION",r);
 long vcpu=sc(SYS_ioctl,vm,KVM_CREATE_VCPU,0,0,0,0);
 if(vcpu<0) fail("KVM_CREATE_VCPU",vcpu);
 long size=sc(SYS_ioctl,kvm,KVM_GET_VCPU_MMAP_SIZE,0,0,0,0);
 struct kvm_run *run=(struct kvm_run*)sc(SYS_mmap,0,size,3,1,vcpu,0);
 if((long)run<0) fail("mmap run",(long)run);
 unsigned long pc=0x80000000UL;
 struct kvm_one_reg reg={KVM_REG_RISCV|KVM_REG_SIZE_U64|KVM_REG_RISCV_CORE|(__builtin_offsetof(struct kvm_riscv_core,regs.pc)/8),(unsigned long)&pc};
 r=sc(SYS_ioctl,vcpu,KVM_SET_ONE_REG,(long)&reg,0,0,0);
 if(r<0) fail("KVM_SET_ONE_REG pc",r);
 for(int i=0;i<100;i++){
  r=sc(SYS_ioctl,vcpu,KVM_RUN,0,0,0,0);
  if(r<0) fail("KVM_RUN",r);
  switch(run->exit_reason){
   case KVM_EXIT_MMIO:{
    unsigned long v=0;
    for(int j=0;j<(int)run->mmio.len;j++) v|=(unsigned long)run->mmio.data[j]<<(j*8);
    out(run->mmio.is_write?"MMIO write ":"MMIO read "); hex(run->mmio.phys_addr); out(" "); hex(v); out("\n");
    break;
   }
   case KVM_EXIT_RISCV_SBI:{
    if(run->riscv_sbi.extension_id==1){ char c=(char)run->riscv_sbi.args[0]; sc(SYS_write,1,(long)&c,1,0,0,0); }
    else { out("SBI "); hex(run->riscv_sbi.extension_id); out("\n"); }
    run->riscv_sbi.ret[0]=0; run->riscv_sbi.ret[1]=0;
    break;
   }
   case KVM_EXIT_SYSTEM_EVENT:
    out("SYSTEM_EVENT "); hex(run->system_event.type); out("\nKVMTEST PASSED\n");
    sc(SYS_exit,0,0,0,0,0,0);
   default:
    out("exit reason "); hex(run->exit_reason); out("\n");
    sc(SYS_exit,2,0,0,0,0,0);
  }
 }
 fail("too many exits",0);
}
