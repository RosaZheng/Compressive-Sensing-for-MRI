function x = pDFT2_inv(y,mask)
% Takes a 1D image y and creates a shrunken 1D k-space x vector

row = size(mask,1);
col = size(mask,2);

fullspace = reshape(y,row,col);
fullspace = ifft2c(fullspace);

x = twoD_to_oneD(fullspace,mask);
