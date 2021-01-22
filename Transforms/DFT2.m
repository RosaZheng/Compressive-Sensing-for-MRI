function y = DFT2(x,inputsize,dir);

x = reshape(x,inputsize);
if dir
    y = ifft2c(x);
else
    y = fft2c(x);
end
y = y(:);
