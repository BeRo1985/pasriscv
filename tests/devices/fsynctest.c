/*
 * fsynctest: small static helper for the guest-side checks of the virtio-fs and
 * 9P fixes. It issues raw RISC-V syscalls and does not link against a libc.
 *
 *   fsynctest <path>...     opens every path read-only, fsyncs it and prints
 *                           "<path>: 0" or "<path>: -<errno>"
 *
 *   fsynctest -lock <file>  takes a write lock with F_SETLK, queries it with
 *                           F_GETLK and releases it again, printing the result
 *                           of each step and the l_type that F_GETLK reported
 *
 * Build (-ffreestanding keeps gcc from turning the loop in put_string() into a
 * call to strlen(), which is not there to link against):
 *
 *   riscv64-linux-gnu-gcc -nostdlib -nostartfiles -static -ffreestanding \
 *       -fno-builtin -O2 -march=rv64gc -mabi=lp64d -o fsynctest fsynctest.c
 */

#define SYS_fcntl  25
#define SYS_openat 56
#define SYS_close  57
#define SYS_write  64
#define SYS_fsync  82
#define SYS_exit   93

#define AT_FDCWD (-100)

#define O_RDONLY 0
#define O_RDWR   2

#define F_GETLK 5
#define F_SETLK 6

#define F_RDLCK 0
#define F_WRLCK 1
#define F_UNLCK 2

#define SEEK_SET 0

#define STDOUT_FILENO 1

struct flock64 {
  short l_type;
  short l_whence;
  long  l_start;
  long  l_len;
  int   l_pid;
};

static long syscall5(long number, long a, long b, long c, long d) {
  register long a0 asm("a0") = a;
  register long a1 asm("a1") = b;
  register long a2 asm("a2") = c;
  register long a3 asm("a3") = d;
  register long a7 asm("a7") = number;

  asm volatile ("ecall"
                : "+r" (a0)
                : "r" (a1), "r" (a2), "r" (a3), "r" (a7)
                : "memory");

  return a0;
}

static void put_string(const char *text) {
  long length = 0;

  while (text[length] != '\0') {
    length++;
  }

  syscall5(SYS_write, STDOUT_FILENO, (long) text, length, 0);
}

static void put_number(long value) {
  char buffer[24];
  int index = (int) sizeof(buffer) - 1;
  int negative = value < 0;
  unsigned long magnitude = negative ? -(unsigned long) value : (unsigned long) value;

  buffer[index] = '\0';
  do {
    buffer[--index] = (char) ('0' + (magnitude % 10));
    magnitude /= 10;
  } while (magnitude != 0);

  if (negative) {
    buffer[--index] = '-';
  }

  put_string(&buffer[index]);
}

static void test_lock(const char *path) {
  /* l_start 0 and l_len 0 mean the whole file. */
  struct flock64 lock = { F_WRLCK, SEEK_SET, 0, 0, 0 };
  struct flock64 query = { F_WRLCK, SEEK_SET, 0, 0, 0 };
  struct flock64 unlock = { F_UNLCK, SEEK_SET, 0, 0, 0 };
  long fd;

  fd = syscall5(SYS_openat, AT_FDCWD, (long) path, O_RDWR, 0);
  put_string("open: ");
  put_number(fd);
  put_string("\n");

  if (fd < 0) {
    return;
  }

  put_string("setlk: ");
  put_number(syscall5(SYS_fcntl, fd, F_SETLK, (long) &lock, 0));
  put_string("\n");

  put_string("getlk: ");
  put_number(syscall5(SYS_fcntl, fd, F_GETLK, (long) &query, 0));
  put_string(" type ");
  put_number(query.l_type);
  put_string("\n");

  put_string("unlock: ");
  put_number(syscall5(SYS_fcntl, fd, F_SETLK, (long) &unlock, 0));
  put_string("\n");

  syscall5(SYS_close, fd, 0, 0, 0);
}

static void test_fsync(const char *path) {
  long fd;
  long result;

  fd = syscall5(SYS_openat, AT_FDCWD, (long) path, O_RDONLY, 0);
  if (fd < 0) {
    result = fd;
  } else {
    result = syscall5(SYS_fsync, fd, 0, 0, 0);
    syscall5(SYS_close, fd, 0, 0, 0);
  }

  put_string(path);
  put_string(": ");
  put_number(result);
  put_string("\n");
}

void main2(long argc, char **argv) {
  long i;

  if ((argc >= 3) && (argv[1][0] == '-') && (argv[1][1] == 'l')) {
    test_lock(argv[2]);
    syscall5(SYS_exit, 0, 0, 0, 0);
  }

  for (i = 1; i < argc; i++) {
    test_fsync(argv[i]);
  }

  syscall5(SYS_exit, 0, 0, 0, 0);
}

asm(".globl _start\n"
    "_start:\n"
    "    ld   a0, 0(sp)\n"
    "    addi a1, sp, 8\n"
    "    call main2\n");
