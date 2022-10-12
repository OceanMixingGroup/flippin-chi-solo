
#include <chiDR.h>

/*See chiDR.h for more docmentation about this code
* Author: Pavan Vutukur <pavan.vutukur@oregonstate.edu>*/

/*****************************************************************************************/

void fitSpectraToPowerLaws(float32_t *vData, 
                           float32_t *hammWind,
                           float32_t *xSeg,
                           float32_t *psdSum,
                           float32_t  *f,
                           float32_t  normFactor,
                           float32_t  mDenominator, 
                           uint8_t    fs,
                           uint16_t   numSeg,
                           uint16_t   numFreqencies, 
                           uint8_t    numOverlap)
{
	//float32_t mNumerator = mNumeratorCalculate(&xSeg[0],&vData[0],numSeg);
											/*Calculates the numerator part of the fit equation*/
  float32_t m = mNumeratorCalculate(&xSeg[0],&vData[0],numSeg)/mDenominator;		/*Calculates the ratio*/
  float32_t b = ((calculate_sum_of_array_f32(&vData[0],numSeg))/numSeg)-(0.5*m);        	
											/*calculates b in y = mx +b equation*/
  float32_t windowedY[numFreqencies],
	    testInput[numFreqencies], 
	    testConj[numSeg],
	    fftOutput[numSeg],
	    psdBuf[numFreqencies]; 							/*Local variables*/
  
  uint16_t numSubSeg = (2*numSeg/numFreqencies) - 1;  					/*Number of half-overlapping segments 
											(=3 for N_seg=512, N_fft=256)*/
  
  calculateLineOfBestFit(&vData[0], 
		         &xSeg[0], 
			 numSeg, m, b);
  
  uint16_t idxLow[3] = {0, (uint16_t)(numFreqencies/2), numFreqencies}; 		/* start_inds = [0, N_fft/2, N_fft];*/

  arm_fill_f32(0,&psdBuf[0],numFreqencies); 						/*prefill local variables with zero*/
  arm_fill_f32(0,&testConj[0],numSeg);
  arm_fill_f32(0,&fftOutput[0],numSeg);
  arm_fill_f32(0,&windowedY[0],numFreqencies);

  
  for (uint8_t ii = 0; ii < 3; ii++)
  {                                                               			/*calculate running sum of 3 psds in the loop*/  
      arm_rfft_fast_instance_f32 rfft_inst;                       			/*Initialize ARM CMSIS FFT Instance*/
      
      arm_rfft_fast_init_f32(&rfft_inst, numFreqencies);                		/*Process the data through the CFFT/CIFFT module */
     
      arm_fill_f32(0,&testInput[0],numFreqencies);                      		/*Pre-fill array with zeros */
      
      arm_copy_f32(&vData[idxLow[ii]], &testInput[0], numFreqencies); 			/*Copy data to buffer*/
      
      arm_mult_f32(&testInput[0], &hammWind[0], &testInput[0], numFreqencies);		/*Apply Hamming window to the signal*/ 
      
      arm_rfft_fast_f32(&rfft_inst, &testInput[0], &fftOutput[0], 0);   		/*compute Fast FFT and store result in fftOutput array*/
      
      arm_cmplx_conj_f32(&fftOutput[0], &testConj[0], numFreqencies);			/*calculate complex conjugate of fftOutput and 
									      		store in testConj array*/
      arm_cmplx_mult_cmplx_f32(&fftOutput[0], &testConj[0], &fftOutput[0], numFreqencies);
	  										/*complex to complex number array multiplication 
											(multiply complex with conj) store in testBuffer*/
      arm_cmplx_mag_f32(&fftOutput[0], &testInput[0], numFreqencies);			/* magnitude of testBuffer and store it in testInput. 
											This may not be required*/
      arm_add_f32(&psdBuf[0], &testInput[0], &psdBuf[0], numFreqencies);		/*Increment psdSum array in the loop. */
  }

  removeFreqBeyondNyquist(&psdBuf[0], &psdSum[0], 1+(numFreqencies/2));			/*Remove frequencies beyond Nyquist 
			    								(sometimes considered the negative frequencies)*/
  scalePsdCorrected(&psdSum[0], numSubSeg, normFactor, 1+(numFreqencies/2), fs); 	/* Scale PSD corrected i.e Normalization*/    
}

/*****************************************************************************************/

void generateHammingWindow(float32_t *pDst, uint16_t blockSize)
{
  /*     
 * @brief Hamming Window Calculation Function.                    
 * @param[out]      *pDst points to the output vector        
 * @param[in]       blockSize number of samples in each vector        
 * @return none.        
 */
  uint16_t blkCnt = 0;                 							/*Set Loop Counter to Zero*/
  /*Since half of windowed output is mirror image of other half, we compute for half to save processing time*/
  while(blkCnt < blockSize/2)              
  {
    *(pDst+blkCnt) = 0.54 - (0.46 * arm_cos_f32(2 * PI * blkCnt / ((float32_t)(blockSize - 1))));
    *(pDst+blockSize - (blkCnt+1)) = *(pDst+blkCnt); 					/*Copy the first half to the last half*/
    blkCnt++;                             						/*Increment the counter*/
  }
}


/*****************************************************************************************/

float32_t calculateNormFactorWindow(float32_t *pSrc, uint16_t blockSize)
{
  /*     
 * @brief Normalization Factor Calculation.                    
 * @param[out]      *pSrc points to the input vector   (Window Array)     
 * @param[in]       blockSize number of samples in each vector        
 * @return normFactor.        
 * window_norm = sum(wind.^2);
   norm_factor = 2/window_norm  % = 0.01973488 for N_fft = 256
 */
  float32_t normFactor = 0.0f;                    					/* Function output .. Norm Factor */
  float32_t sumOfSquares = 0.0f;                 					/* Sum of Squares */
  arm_dot_prod_f32(&pSrc[0],&pSrc[0],blockSize,&sumOfSquares);   
  normFactor = 2/sumOfSquares;  
											/*window_norm = sum(wind.^2);
											norm_factor = 2/window_norm = 0.01973488 
											for N_fft = 256*/
  return(normFactor);
}


/*****************************************************************************************/

float32_t mDenominatorCalculate(float32_t blockSize)
{
  /*     
 * @brief Calculates mDenominator value.                    
 * 
 * @param[in]       blockSize number of samples in each vector        
 * @return mDenom.        
 */
  float32_t mDenom = blockSize*((blockSize*blockSize) -1)/6;;  				/*output value*/
  return(mDenom);
}


/*****************************************************************************************/

float32_t mNumeratorCalculate(float32_t *pSrcA, float32_t *pSrcB, uint16_t blockSize)
{
   /*     
 * @brief Normalization Factor Calculation.                    
 * @param[in]      *pSrcA points to the input vector      x
 * @param[in ]      *pSrcB points to the input vector     y  
 * @param[in]       blockSize number of samples in each vector         
 * @return mNumerator       
 * m_numerator = 2*sum(x.*y) -  sum(y);
 */
  float32_t mNumerator = 0;
  float32_t dotProduct = {0};
  arm_dot_prod_f32(&pSrcA[0],&pSrcB[0],blockSize,&dotProduct);   			/* sum(x.*y) */
  mNumerator = (2*dotProduct) - calculate_sum_of_array_f32(&pSrcB[0],blockSize);	/* mNumerator = 2*sum(x.*y) -  sum(y) */
  return (mNumerator);
}

/*****************************************************************************************/

float32_t calculate_sum_of_array_f32(float32_t * pSrc, uint32_t blockSize)
/*
Adaptation of existing arm CMSIS code for calculating sum of elements in an array
* @param[in]      *pSrc points to the input vector      
* @param[in ]     blockSize number of samples in each vector

*/

{
  float32_t sum = 0.0f;                          					/* Temporary result storage */
  uint32_t blkCnt;                               					/* loop counter */

  											/* Run the below code for Cortex-M4 and Cortex-M3 */
  float32_t in1, in2, in3, in4;

  											/*loop Unrolling for faster processing*/
  blkCnt = blockSize >> 2u;

  /* First part of the processing with loop unrolling.  Compute 4 outputs at a time.    
   ** a second loop below computes the remaining 1 to 3 samples. */
  while(blkCnt > 0u)
  {
    /* C = (A[0] + A[1] + A[2] + ... + A[blockSize-1]) */
    in1 = *pSrc++;
    in2 = *pSrc++;
    in3 = *pSrc++;
    in4 = *pSrc++;

    sum += in1;
    sum += in2;
    sum += in3;
    sum += in4;

    /* Decrement the loop counter */
    blkCnt--;
  }
  return(sum);
}


/*****************************************************************************************/
void calculateLineOfBestFit(float32_t 	*pSrcA, 
                            float32_t 	*pSrcB, 
                            uint16_t 	blockSize,
                            float32_t 	m,
                            float32_t 	b)
{
     /*     
 * @brief Calculates Line of Best Fit y = m x + b using least squares                    
 * @param[in]      *pSrcA points to the input vectorA      
 * @param[in ]     *pSrcB points to the input vectorB     
 * @param[in]       blockSize number of samples in each vector        
 * @param[in]       m ratio of numerator and denominator m_numerator/m_denominator
 * @param[in]       b =  sum(y)/N_seg - m/2
 * @return          None       
 * y(ii) = y(ii) - (m*x(ii) + b);
 */

  uint16_t blkCnt = 0;
  while(blkCnt < blockSize)
  {
    *(pSrcA + blkCnt) -= (m*(*(pSrcB + blkCnt)) + b);
    blkCnt++;
  }
}

/*****************************************************************************************/
void generateEvenSpacedNum(int16_t   	blkCnt_LOW,
                              uint16_t  	blockSize,
                              float32_t   	*pDst)
{
 /* 
 * @brief Generates even spaced numbers      
 * This is Matlab eq (-N_seg/2+1):(N_seg/2)  (ie -255, -254, ..., 256 for N_seg = 512)  
 * @param[out]     *pDst points to the output vector     
 * @param[in]       blockSize number of samples in each vector        
 * @param[in]       blkCnt_LOW Lowest starting point *signed integer)
 * @return          None  
  
 */
  uint16_t blkCnt = 0;
  while (blkCnt < blockSize)
  {
    *(pDst+blkCnt) = (float32_t)(blkCnt_LOW + blkCnt);
    blkCnt++;
  }
   
}


/*****************************************************************************************/
void removeFreqBeyondNyquist(float32_t *pSrc, float32_t *pDst, uint16_t blockSize)
{
/* 
 * @brief Remove frequencies beyond Nyquist (sometimes considered the negative frequencies)  
 * @param[out]      pDst points to the output vector     
 * @param[in]       pSrc points to the input vector
 * @param[in]       blockSize number of samples in each vector        
*/
  uint16_t blkCnt = 0;

  while(blkCnt < blockSize)
  {
    *(pDst + blkCnt) = *(pSrc + blkCnt);
    blkCnt++;
  }
}


/*****************************************************************************************/
void scalePsdCorrected(float32_t *pSrc, 
                         uint16_t numSubSeg, 
                         float32_t normFactor, 
                         uint16_t blockSize, 
                         uint8_t fSampling)
{
  uint16_t blkCnt = 0;
  float32_t corrFactor = normFactor/((float32_t)(fSampling*numSubSeg));
  //Serial.println("PSD Begin");
  while (blkCnt < blockSize)
  {
    *(pSrc + blkCnt) = (*(pSrc + blkCnt))*corrFactor;
    //Serial.println(*(pSrc + blkCnt),10);
    blkCnt++;
  }
  //Serial.println("PSD END");
}

/*****************************************************************************************/
void fidxCompute(float32_t *pSrc, bool *pDst,uint16_t f1, uint16_t f2, uint16_t blockSize)
{
  uint16_t blkCnt = 0;
  while (blkCnt < blockSize)
  {
    if(*(pSrc + blkCnt) >= f1 && *(pSrc + blkCnt) <= f2)
    {
      *(pDst + blkCnt) = true;
    }
    else
    {
      *(pDst + blkCnt) = false;
    }
    //Serial.println(*(pDst + blkCnt));
    blkCnt++;
  }
  
}
/*****************************************************************************************/
float32_t psiShearFit(float32_t *pSrcA, bool *pSrcB, float32_t *pSrcC, uint16_t blockSize)
{
  uint16_t 	blkCnt = 0;
  float32_t psiFit = 0;
  float32_t psiFitNumerator = 0;
  float32_t psiFitDenominator = 0;
  while (blkCnt < blockSize)
  {
    if(*(pSrcB + blkCnt) == true)
    {
      psiFitNumerator   += (*(pSrcA + blkCnt))*(cbrtf(*(pSrcC + blkCnt)));
      psiFitDenominator += cbrtf((*(pSrcC + blkCnt))*(*(pSrcC + blkCnt)));
    }
    blkCnt++;
  }
  psiFit = psiFitNumerator/psiFitDenominator;
  return(psiFit);
}
/*****************************************************************************************/

float32_t fitPsiTP(float32_t *pSrcA, bool *pSrcB, float32_t *pSrcC, uint16_t blockSize)
{
  uint16_t 	blkCnt = 0;
  float32_t psiFit = 0;
  float32_t psiFitNumerator = 0;
  float32_t psiFitDenominator = 0;
  while (blkCnt < blockSize)
  {
    if(*(pSrcB + blkCnt) == true)
    {
     psiFitNumerator   += (*(pSrcA + blkCnt))*(*(pSrcC + blkCnt));
     psiFitDenominator += ((*(pSrcC + blkCnt))*(*(pSrcC + blkCnt)));
    }
    blkCnt++;
  }
  psiFit = psiFitNumerator/psiFitDenominator;
  return(psiFit);
}

/*****************************************************************************************/
void fallSpdCompute(float32_t *pSrc, uint16_t blockSize, float32_t *pDst)
{
/*
* @brief Difference of start and end pressure and divide by sample size and sampling rate gives fall speed
*/
  *pDst = (fabs(*(pSrc+blockSize-1)-*(pSrc)))/((blockSize-1)*0.01);   
}

/*****************************************************************************************/

void numSegmentsCompute(uint16_t *pSrc, uint16_t blockSize)
{
  uint16_t blkCnt = 0;

  while (blkCnt < blockSize)
  {
    *(pSrc+blkCnt) =  blkCnt*50;
    blkCnt++;
  }
}

/*****************************************************************************************/

//C version of MATLAB function diff
void diffCompute(float32_t *pSrcA, 
                  float32_t *pDst,
                  uint16_t   blockSize,
                  uint16_t  *pSrcB)
{
  uint16_t blkCnt = 0;
  while (blkCnt < (blockSize-1))
  {
    *(pDst+blkCnt) = (fabs(*(pSrcA+*(pSrcB+blkCnt))-*(pSrcA+*(pSrcB+blkCnt+1))))*2;  
											/* 2Hz  1/dt*50  dt = 0.01 100Hz 50 is every 50th point */
    blkCnt++;
  }
}

/*****************************************************************************************/


void despikeShearSegment(float32_t *pSrc, uint16_t blockSize)
{
	//C version of MATLAB function blk = despike_shear_blocks_fcs(blk)
  float32_t xMean,
			xDespikeMean,
			xStd;
  float32_t xSum = 0;
  bool 		xSpikes[blockSize];
  uint16_t 	blkCnt = 0;
  uint16_t 	spikeCnt = 0; 
  arm_mean_f32(&(*pSrc),blockSize,&xMean);   //Mean of S1 
  arm_std_f32(&(*pSrc),blockSize,&xStd);    // Standard Deviation of S1
  while (blkCnt < blockSize)				//Keep track of #spikes in each blkCnt iteration
  {
     if (fabs(*(pSrc+blkCnt)-xMean) > (3*xStd))
     {
      xSpikes[blkCnt] = true;
	  spikeCnt++; 
     }
     else
     {
      xSpikes[blkCnt] = false; 
      xSum += *(pSrc+blkCnt);     //sum the good ones within the arrray and then create a new array that
     }
     blkCnt++;  				//increment loop counter    
  }

  xDespikeMean = xSum/(blkCnt-spikeCnt);  //mean of good values without spikes
  blkCnt = 0;                              // reset block counter back to zero

  while (blkCnt < blockSize)
  {
    if (xSpikes[blkCnt] == true)           //check if this has spikes
    {
      *(pSrc+blkCnt) = xDespikeMean;      //if so then set the array value to xDespikeMean
    }
    blkCnt++;                               //increment the counter till all the buffer is read
  }
}

/*****************************************************************************************/

void defineFreqFiltRanges(uint16_t   fs,
                             uint16_t   blockSize,
                             float32_t *pDst)

/*
%   Define the low and high limits over which to do the two fits for each shear and TP spectra
%   The high bound for the first range is the same as the low bound for the second range
%
%   Input
%   -----
%   fs: sampling frequency
%   numFreqencies: number of points that will be used in FFT
%
%   Outputs
%   -------
%   f: 1 x numFreqencies vector of frequencies associated with a spectra using numFreqencies
%   fbounds: four-element vector with the two low and two high frequency bounds
%            [f_low_1, f_high_1, f_low_2, f_high_2]
%
%   (Ken Hughes wrote the original MATLAB Version)
*/
{
  uint16_t numFreqencies = ((uint16_t)(blockSize*0.5)) + 1;
  uint16_t blkCnt = 0;
  float32_t step = (fs*0.5-0)/(float32_t)(numFreqencies-1);   /*MATLAB  f = linspace(0, fs/2, numFreqencies);*/

  while(blkCnt < numFreqencies)
  {
    *(pDst+blkCnt) = ((float32_t)blkCnt * step);
    blkCnt++;
  }
}


/*
 MATLAB Linspace Linearly spaced vector.
    linspace(X1, X2) generates a row vector of 100 linearly
    equally spaced points between X1 and X2.
 
    linspace(X1, X2, N) generates N points between X1 and X2.
    For N = 1, linspace returns X2.
 float32_t* c_lin_space(float32_t x1, float32_t x2, uint16_t n) 
{

 float32_t *x = calloc(n, sizeof(float32_t));

 float32_t step = (x2 - x1) / (float32_t)(n - 1);

 for (uint16_t i = 0; i < n; i++) {
     x[i] = x1 + ((float32_t)i * step);
 }
 
 return x;
}
*/

/*****************************************************************************************/
