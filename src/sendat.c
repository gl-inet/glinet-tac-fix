#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/file.h>
#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <stdlib.h>
#include <getopt.h>
#include "uart.h"


static int My_read_result(int fd, char *buf, int max_read, int time)
{
    int len = 0;
    char *recv_msg = buf;
    char *ptr = recv_msg;
    int out = 0;
    if (max_read <= 0)
        max_read = 4096;
    while (out < time) {
        int ret = 0;
        if ((ret = MyuartRxExpires(fd, max_read, ptr + len, 500)) > 0) {
            len += ret;
            ret = 0;
            if ((len >= max_read) || ((ptr + len - buf) >= max_read)) {
                recv_msg[max_read - 1] = '\0';
                return len;
            }
            if (strstr(recv_msg, "OK") || strstr(recv_msg, "ERROR")) {
                recv_msg[len] = '\0';
                recv_msg[max_read - 1] = '\0';
                return len;
            } else {
                //ptr=ptr+len;
                usleep(10000);
                continue;
            }
        }
        out++;
    }
    recv_msg[max_read - 1] = '\0';
    return len;
}



int send_command(char *device, char *cmd, char *recv_buf, int max_read)
{

    int len_cmd = 0, time_out = 0, fd = -1, ret = 0;
    len_cmd = strlen(cmd);
    int time = 30;
    cmd[len_cmd] = '\r';
    cmd[len_cmd + 1] = '\n';
    cmd[len_cmd + 2] = '\0';
    len_cmd += 2;
    fd = uartOpen(device, 115200, 0, 100);
    if (fd < 0) {
        return -1;
    }

    while (flock(fd, LOCK_EX | LOCK_NB) != 0) { //get file lock
        if (++time_out > 30) {//time out
            //uartClose();
            MyuartClose(fd);
            return -2;
        }
        usleep(1000);
    }
    //flushIoBuffer();
    MyflushIoBuffer(fd);
    //uartTxNonBlocking(len_cmd,cmd);
    MyuartTxNonBlocking(fd, len_cmd, cmd);
    if (0 == strncmp(cmd, "AT+COPS=?", 9)) {
        time = 30000;
    } else if (0 == strncmp(cmd, "AT+CFUN=1,1", 11)) {
        time = 300;
    }

    ret = My_read_result(fd, recv_buf, max_read, time);
    //uartClose();
    MyuartClose(fd);

    if (ret > 0)
        return 0;
    else
        return -1;
}

int main(int argc, char *argv[])
{
    char *command;
    int i = 0;

    if (argc > 1)
        if (0 == strcmp(argv[1], "-B")) {
            for (i = 1; i < argc; i++) {
                argv[i] = argv[i + 1];
            }
            argc--;
        }

    if (argc > 1)
        if (strstr(argv[1], "1-1") || strstr(argv[1], "2-1")) {
            for (i = 1; i < argc; i++) {
                argv[i] = argv[i + 1];
            }
            argc--;
        }

    if (argc < 4) {
        printf("\nUsage:<sendat> <AT> <device> <command>\n");
        return -1;
    }
    command = argv[1];

    if (0 == strcmp(command, "AT")) {

        char recv[4096] = { 0 };
        char cmd[256] = {0};
        char dev[64] = {0};
        strcpy(cmd, argv[3]);
        strcpy(dev, argv[2]);
        if (0 == send_command(dev, cmd, recv, sizeof(recv))) {
            printf("\n%s", recv);
        }
    } else {
        printf("\nUsage:<sendat> <AT> <device> <command>\n");
    }
    return 0;
}


