/* usbreset -- send a USB port reset to a USB device */

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <string.h>
#include <stdlib.h>

#include <linux/usbdevice_fs.h>


int main(int argc, char **argv)
{
    const char *filename;
    int fd;
    int rc;
    char* toFree = 0;

    if (argc < 2 || strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
        fprintf(stderr, "Usage: usb-reset device-filename\n      or\n       usb-reset bus vendor");
        return 1;
    }
    filename = argv[1];

    if (argc == 3) {
        const char* prefix = "/dev/bus/usb";
        char* resolved = (char *)malloc(strlen(prefix) + strlen(argv[1]) + strlen(argv[2]) + 10);
        sprintf(resolved, "%s/%s/%s", prefix, argv[1], argv[2]);
        toFree = resolved;
        filename = resolved;
    }

    fd = open(filename, O_WRONLY);
    if (fd < 0) {
        char * error = (char *)malloc(32 + strlen(filename));
        sprintf(error, "Error opening output file: %s", filename);
        perror(error);
        free(error);
        return 1;
    }

    printf("Resetting USB device %s\n", filename);
    rc = ioctl(fd, USBDEVFS_RESET, 0);
    if (rc < 0) {
        perror("Error in ioctl");
        if (toFree) {
            free(toFree);
        }
        return 1;
    }
    printf("Reset successful\n");

    close(fd);
    if (toFree) {
        free(toFree);
    }
    return 0;
}
