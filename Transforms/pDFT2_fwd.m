function y = pDFT2_fwd(x,mask)
% Takes a small 1D k-space vector x and the mask, and generates 1D image y

fullspace = oneD_to_twoD(x,mask);
y = fft2c(fullspace);
y = y(:);