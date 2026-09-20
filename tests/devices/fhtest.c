// fhtest <dir>: checks the attribute change that FUSE sends with FATTR_FH, so through the open
// handle instead of the path. It creates <dir>/fh with 100 bytes, keeps it open, unlinks it and
// then truncates it through the descriptor. Without the handle path in the server that fails with
// ENOENT, because the file has no name any more. Only the size goes this way: Linux sets ATTR_FILE
// for ftruncate, while fchmod and futimens always work on the path.
//
// riscv64-linux-gnu-gcc -O2 -static -o fhtest fhtest.c

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char **argv) {
  char path[4096];
  char buffer[100];
  struct stat st;
  int fd;
  int rc;

  if (argc < 2) {
    printf("usage: fhtest <dir>\n");
    return 2;
  }

  snprintf(path, sizeof(path), "%s/fh", argv[1]);
  fd = open(path, O_RDWR | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) {
    printf("open: %s\n", strerror(errno));
    return 1;
  }

  memset(buffer, 'x', sizeof(buffer));
  if (write(fd, buffer, sizeof(buffer)) != (ssize_t)sizeof(buffer)) {
    printf("write: %s\n", strerror(errno));
    close(fd);
    return 1;
  }

  if (unlink(path) != 0) {
    printf("unlink: %s\n", strerror(errno));
    close(fd);
    return 1;
  }

  rc = ftruncate(fd, 10);
  printf("ftruncate: %s\n", rc == 0 ? "ok" : strerror(errno));

  rc = fstat(fd, &st);
  printf("size: %s\n", rc == 0 ? (st.st_size == 10 ? "10" : "wrong") : strerror(errno));

  close(fd);
  return 0;
}
