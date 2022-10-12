/*This source code has a set of support functions for Chipod data reduction process
 * Most of these are MATLAB to C conversion of fit_spectra_to_power_laws_fcs(blk, f, fbounds, fs, Nseg, numFreqencies, Noverlap)
 * Github https://github.com/OceanMixingGroup/flippin-chi-solo/blob/main/reduced/fit_spectra_to_power_laws_fcs_fcs.m
 * written in Matlab by Kenneth Hughes https://kghughes.com/
 * Adapted and written for Arduino to be implemented on Teensy 4.1 
 * Author: Pavan Vutukur <pavan.vutukur@oregonstate.edu>
 * Organization: Ocean Mixing Group / College of Earth, Ocean, and Atmoshperic Sciences (CEOAS)/ Oregon State University
 * Start Date: 29 Sep 2022
 */


#ifdef __cplusplus
extern "C" {
#endif

/*
extern "C" makes a function-name in C++ have C linkage (compiler does not mangle the name) 
so that client C code can link to (use) the function using a C compatible header file that 
contains just the declaration of the function. The function definition is contained in a 
binary format (that was compiled by the C++ compiler) that the client C linker will then 
link to using the C name.
More info here:
https://stackoverflow.com/questions/1041866/what-is-the-effect-of-extern-c-in-c
*/



#ifndef chiDR_h
#define chiDR_h
/*
The construct is just a simple way to prevent problems if ever the user adds 
the #include <ChiDR.h> twice on their code.
More info on the tutorial link below to create this library
https://www.teachmemicro.com/create-arduino-library/
*/


/*
Include ARM MATH functions
These have CMSIS functionality for DSP and FPU computations
More info here:
https://www.keil.com/pack/doc/CMSIS/DSP/html/index.html
*/

#include <arm_math.h>
#include "arm_const_structs.h"
#include <Arduino.h>



/*
These functions input variables use similar naming convention as in ARM CMSIS Routines.
For example:
*pSrc 		Pointer to Source Buffer(s) (Example: pSrcA, pSrcB, pSrcC ...)
*pDst 		Pointer to Destination Buffer(s) (Example: pDstA, pDstB, pDstC..)
*blockSize	Size of Buffer
*blkCnt		Loop Counter position

Majority of functions use pointer's call by reference. A good understanding of C pointers is necessary.
A good resource for understanding pointers in C (referencing and de-referencing)
https://www.youtube.com/watch?v=h-HBipu_1P0


The function and variables naming convention will be changed to lowerCamelCase, not underscore, 
as adopted from Processing.org for readability's sake. More info here: 
https://www.techtarget.com/whatis/definition/CamelCase

However the ARM-CMSIS routines will follow their original naming convention. 
*/

void fitSpectraToPowerLaws(float32_t 	*vData, 
                           float32_t 	*hammWind,
                           float32_t 	*xSeg,
                           float32_t 	*psdSum,
                           float32_t  	*f,
                           float32_t  	normFactor,
                           float32_t  	mDenominator, 
                           uint8_t    	fs,
                           uint16_t   	numSeg,
                           uint16_t   	nfft, 
                           uint8_t    	numOverlap);


void generateHammingWindow(float32_t	*pDst, 
		           uint16_t 	blockSize);


float32_t calculateNormFactorWindow(float32_t 	*pSrc, 
				    uint16_t 	blockSize);
								
float32_t mDenominatorCalculate(float32_t blockSize);

float32_t mNumeratorCalculate(float32_t		*pSrcA, 
			      float32_t 	*pSrcB, 
			      uint16_t 		blockSize);

float32_t calculate_sum_of_array_f32(float32_t 	*pSrc,
				     uint32_t 	blockSize);

void calculateLineOfBestFit(float32_t	*pSrcA, 
                            float32_t 	*pSrcB, 
                            uint16_t 	blockSize,
                            float32_t 	m,
                            float32_t 	b);

void generateEvenSpacedNum(int16_t   	blkCnt_LOW,
                           uint16_t  	blockSize,
                           float32_t   	*pDst);

void removeFreqBeyondNyquist(float32_t		*pSrc,
			     float32_t 		*pDst,
			     uint16_t 		blockSize);

void scalePsdCorrected(float32_t		*pSrc, 
                       uint16_t 		numSubSeg, 
                       float32_t 		normFactor, 
                       uint16_t 		blockSize, 
                       uint8_t 			fSampling);

void fidxCompute(float32_t	*pSrc,
		 bool 		*pDst,
		 uint16_t 	f1, 
		 uint16_t 	f2, 
		 uint16_t 	blockSize);
					
float32_t psiShearFit(float32_t		*pSrcA,
		      bool		*pSrcB,
		      float32_t 	*pSrcC,
		      uint16_t 		blockSize);

float32_t fitPsiTP(float32_t 		*pSrcA, 
                   bool 	   	*pSrcB, 
                   float32_t 		*pSrcC, 
                   uint16_t 		blockSize);
					 
void fallSpdCompute(float32_t 		*pSrc,
		    uint16_t 		blockSize,
		    float32_t 		*pDst);

void numSegmentsCompute(uint16_t 	*pSrc,
			uint16_t 	blockSize);

void diffCompute(float32_t 	*pSrcA, 
                 float32_t 	*pDst,
                 uint16_t   	blockSize,
                 uint16_t  	*pSrcB);

void despikeShearSegment(float32_t 	*pSrc,
			 uint16_t 	blockSize);
						   
void defineFreqFiltRanges(uint16_t   fs,
                          uint16_t   blockSize,
                          float32_t  *pDst);					 

#endif

#ifdef __cplusplus
}
#endif
