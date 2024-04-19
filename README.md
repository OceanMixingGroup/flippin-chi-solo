# Flippin' Chi Solo (FCS) processing code

Matlab prototype: Ken Hughes, April 2022

C firmware implementation: Pavan Vutukur, October 2022 

For full details, see 
  
[Hughes et al. (2023)][H23]. A turbulence data reduction scheme for autonomous and expendable profiling floats.  
*Ocean Sci.* 19, 193–207, doi:10.5194/os-19-193-2023

## Directory layout:

- `full`: The standard processing
- `reduce`: The processing using the data reduction scheme
- `reducedC`: The processing in C language using the MATLAB data reduction scheme from `reduce`
- `other`: Functions called by both methods
- `comp`: Functions used with compressed files
- `sat`: Documentation and scripts for parsing and processing .sat files
 
## Dependencies (beyond standard Matlab tools):

Seawater toolbox functions (`sw_... .m`), copies of which are available at `github.com/OceanMixingGroup/chipod_gust/tree/master/software/mix_files`.

`integrate.m` from  
`github.com/OceanMixingGroup/mixingsoftware/blob/master/marlcham/integrate.m`

## Notes:

Processing FCS data is much like processing Chameleon data; both are vertical microstructure profilers. However, the different sensors and different deployment methods of the two instruments mean that it is worth having a separate and stand-alone processing suite for FCS. Indeed, some functions (e.g., Kraichnan and Nasmyth spectra) already exist in MixingSoftware. I've rewritten them (and included a `_fcs` in the filename) to keep the directory more self contained.

[H23]: https://doi.org/10.5194/os-19-193-2023
