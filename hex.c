/*=============================================================================
 *
 * Name: hex.c
 *
 * Created by: Samuel Barton
 *
 * Project: Spider
 *
 * Description: This program opens the file it is passed as an argument, reads
 *              it in 4K at a time, and formats the binary data as hex. It then
 *              writes the hex data out to standard out.
 *
 *===========================================================================*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

int BUFFER_SIZE = 4096;

int main(int ac, char** av)
{
    // Open the file passed as an argument for reading
    int input_file = open(av[1], O_RDONLY);

    // print out the name of the file passed in
    fprintf(stdout, "Opened file: %s", av[1]);

    // create a buffer to read the file's contents in to.
    char buf[BUFFER_SIZE];
    int buf_index = 0;

    // read in the first 4KB into the buffer
    read(input_file, buf, BUFFER_SIZE);

    // create the processing buffer
    unsigned char processor = 0;

    // copy a byte into the processor using the bitwise or operator
    processor = processor | buf[buf_index++];

    fprintf(stdout, "%x", processor);
}
