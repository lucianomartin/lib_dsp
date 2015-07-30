// XMOS DSP Library - Filtering Functions Test Program
// Uses Q24 format

// Include files
#include <stdio.h>
#include <xs1.h>
#include <xmos_dsp_elements.h>

// Define constants

#define Q_M               8
#define Q_N               24

#define FIR_FILTER_LENGTH     30
#define IIR_STATE_LENGTH      4
#define IIR_CASCADE_DEPTH     3
#define SAMPLE_LENGTH         50

void print31( int x ) {if(x >=0) printf("+%f ",F31(x)); else printf("%f ",F31(x));}

// Declare global variables and arrays
int  Src[] = { Q24(.11), Q24(.12), Q24(.13), Q24(.14), Q24(.15), Q24(.16), Q24(.17), Q24(.18), Q24(.19), Q24(.20),
               Q24(.21), Q24(.22), Q24(.23), Q24(.24), Q24(.25), Q24(.26), Q24(.27), Q24(.28), Q24(.29), Q24(.30),
               Q24(.31), Q24(.32), Q24(.33), Q24(.34), Q24(.35), Q24(.36), Q24(.37), Q24(.38), Q24(.39), Q24(.40),
               Q24(.41), Q24(.42), Q24(.43), Q24(.44), Q24(.45), Q24(.46), Q24(.47), Q24(.48), Q24(.49), Q24(.50),
               Q24(.51), Q24(.52), Q24(.53), Q24(.54), Q24(.55), Q24(.56), Q24(.57), Q24(.58), Q24(.59), Q24(.60)};
int           Dst[SAMPLE_LENGTH];

int firCoeffs[] = { Q24(.11), Q24(.12), Q24(.13), Q24(.14), Q24(.15), Q24(.16), Q24(.17), Q24(.18), Q24(.19), Q24(.20),
                    Q24(.21), Q24(.22), Q24(.23), Q24(.24), Q24(.25), Q24(.26), Q24(.27), Q24(.28), Q24(.29), Q24(.30),
                    Q24(.31), Q24(.32), Q24(.33), Q24(.34), Q24(.35), Q24(.36), Q24(.37), Q24(.38), Q24(.39), Q24(.40)};

int iirCoeffs[] = { Q24(.11), Q24(.12), Q24(.13), Q24(.14), Q24(.15),
                    Q24(.21), Q24(.22), Q24(.23), Q24(.24), Q24(.25),
                    Q24(.31), Q24(.32), Q24(.33), Q24(.34), Q24(.35)};

//int filterState[FIR_FILTER_LENGTH];
int filterState[160];

int inter_coeff[161];
int decim_coeff[161];
int decim_input[16];

int main(void)
{
  int i, j, c, r, x, y;
  int xx[] = {Q28(+2.8),Q28(+2.9),Q28(+2.8),Q28(+2.9)};

#if COMMENT
                 // Initiaize FIR filter state array
  for (i = 0; i < FIR_FILTER_LENGTH; i++)
  {
    filterState[i] = 0;
  }

                // Apply FIR filter and store filtered data
  for (i = 0; i < SAMPLE_LENGTH; i++)
  {
    Dst[i] =
      xmos_dsp_filters_fir (Src[i],                 // Input data sample to be filtered
                            firCoeffs,              // Pointer to filter coefficients
                            filterState,            // Pointer to filter state array
                            FIR_FILTER_LENGTH,      // Filter length
                            Q_N);                   // Q Format N
  }

  printf ("FIR Filter Results\n");
  for (i = 0; i < SAMPLE_LENGTH; i++)
  {
      printf ("Dst[%d] = %lf\n", i, F24 (Dst[i]));
  }

                 // Initiaize IIR filter state array
  for (i = 0; i < IIR_STATE_LENGTH; i++)
  {
    filterState[i] = 0;
  }

                // Apply IIR filter and store filtered data
  for (i = 0; i < SAMPLE_LENGTH; i++)
  {
    Dst[i] =
      xmos_dsp_filters_biquad (Src[i],              // Input data sample to be filtered
                               iirCoeffs,           // Pointer to filter coefficients
                               filterState,         // Pointer to filter state array
                               Q_N);                // Q Format N
  }

  printf ("IIR Biquad Filter Results\n");
  for (i = 0; i < SAMPLE_LENGTH; i++)
  {
      printf ("Dst[%d] = %lf\n", i, F24 (Dst[i]));
  }


                 // Initiaize IIR filter state array
  for (i = 0; i < (IIR_CASCADE_DEPTH * IIR_STATE_LENGTH); i++)
  {
    filterState[i] = 0;
  }

                // Apply IIR filter and store filtered data
  for (i = 0; i < SAMPLE_LENGTH; i++)
  {
    Dst[i] =
      xmos_dsp_filters_biquads (Src[i],             // Input data sample to be filtered
                                iirCoeffs,          // Pointer to filter coefficients
                                filterState,        // Pointer to filter state array
                                IIR_CASCADE_DEPTH,  // Number of cascaded sections
                                Q_N);               // Q Format N
  }

  printf ("Cascaded IIR Biquad Filter Results\n");
  for (i = 0; i < SAMPLE_LENGTH; i++)
  {
      printf ("Dst[%d] = %lf\n", i, F24 (Dst[i]));
  }

#endif


  printf ("Interpolation\n");
  for( r = 2; r <= 8; ++r )
  {
    for( c = 8; c <= 8; c++ )
    {
      printf( "INTERP taps=%u L=%u\n", c*r, r );

      i = 0;
      for( y = 0; y < c; ++y )
        for( x = 0; x < r; ++x )
          inter_coeff[x*c+y] = firCoeffs[i++];

      for( i = 0; i < 160; ++i )
        filterState[i] = 0;
      for( i = 0; i < c; ++i )
      {
        xmos_dsp_filters_interpolate( Q31(0.1), inter_coeff, filterState, c*r, r, xx, 31 );
        for( j = 0; j < r; ++j ) print31( xx[j] );
          printf( "\n" );
      }
    }
  }


  printf ("Decimation\n");
  for( int r = 2; r <= 8; ++r )
  {
    for( i = 0; i < 16; ++i )
      decim_input[i] = Q31(0.1);
    printf( "DECIM taps=%02u M=%02u\n", 32, r );
    for( i = 0; i < 160; ++i )
      filterState[i] = 0;
    for( i = 0; i < 32/r; ++i )
    {
      x = xmos_dsp_filters_decimate( decim_input, firCoeffs, filterState, 32, r, 31 );
      print31( x );
      if( (i&7) == 7 )
        printf( "\n" );
    }
    if( (--i&7) != 7 )
      printf( "\n" );
  }

  return (0);
}

