/*=============================================================================
 *
 * Name: temper.c
 *
 * Written by: unknown
 *
 * Project: Temperature sensor
 *
 * Description: This program gets data from the temperature sensors and prints
 *              it to stdout in a CSV format.
 *
 ============================================================================*/

#include <stddef.h>
#include <stdio.h>
#include <time.h>

/*
 pcsensor.h adds:
  <usb.h>
  <string.h>
  <errno.h>
  <float.h>
 along with 3 methods:
  void pcsensor_open(usb_dev_handle *lvr_winsub[10], uint8_t location[10]);
  void pcsensor_close(usb_dev_handle* lvr_winusb);
  float pcsensor_get_temperature(usb_dev_handle* lvr_winusb);
*/
#include "pcsensor.h"

/* Calibration adjustments
 * See http://www.pitt-pladdy.com/blog/_20110824-191017_0100_TEMPer_under_Linux_perl_with_Cacti/ */
static float scale = 1.0287; // 1.029 on that above site
static float offset = -0.85; // 1.0 on that site

int main()
{
    /* ---- VARIABLES ----
     * int i is for for loops iteration
     * int results is for tracking not NULL lvr_winusb[i] count
     *  & then looping through just "results"-many printf statements.
     * float tempc[10] will store temperature results for non-NULL usb openings
     * usb_dev_handle* lvr_winusb[10] is an array of 10 pointers to usb_dev_handle structures
     *  the array to be referenced is lvr_winusb, but usb_dev_handle is what will be
     *  passed to pcsensor_open, pcsensor_get_temperature, &
     *  pcsensor_close (of which do what the names imply)
     * uint8_t location[10] is basically an array of 8 bit-length unsigned integers.
     *  this is being used (instead of unsigned int or something)
     *  because it helps with cross platform interactions.
    */
    int i;
    int results = 0;
    float tempc[10];
    usb_dev_handle* lvr_winusb[10];
    uint8_t location[10];
    /* Each lvr_winusb item and location item are initially undefined.
     * this loop just defines them as NULL and 0 so they can be accessed without errors, warnings. */
    for(i = 0; i < 10; i++)
    {
        lvr_winusb[i] = NULL;
        location[i] = 0;
    }
    /* pcsensor_open is sent the two size 10 arrays, where it has a complicated
     *  method, that for all explanatory purposes of this file, simply
     *  opens each file descriptor & assigns to lvr_winusb[i] & location[i]
     *  some might be null, which is tested in the next loop */
    pcsensor_open(lvr_winusb, location);

    /* loops through and tests each of the 10 arrays status. != NULL means opened successfully
     *  are in order: a NULL lvr_winusb[i] will have i>j for non-null lvr_winusb[j]... at least
     *  in theory, as the next for loop goes through sequentially the minimum number of times. */
    for(i = 0; i < 10; i++)
    {
        if (lvr_winusb[i] != NULL)
        {
            // stores the temperature (in deg C), then closes the connection, & increments results count
            tempc[i] = pcsensor_get_temperature(lvr_winusb[i]);
            pcsensor_close(lvr_winusb[i]);
            results++;
        }
    }
    // only loop through as many times as there are results, and sequentially
    for(i = 0; i < results; i++){
        // int i are synced as each of the printf variables rely on tempc[i] & location[i]
        float tempcout = (tempc[i] * scale) + offset;
        printf("%f%s%u\n", tempcout,",", location[i]);
    }
    // simply forces out any printf statements that have not yet been printed for whatever reason
    fflush(stdout);
    // "return 0" exits the program explicitly (optional)
    return 0; // could set it to some other integer if we wanted to, but default for C/Linux is 0 for "OK"
}
