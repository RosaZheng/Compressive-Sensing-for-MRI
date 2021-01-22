function y = DCT2_full(x,inputsize,dir)

x = reshape(x,inputsize);
if dir
    y = idct2(x);
else
    y = dct2(x);
end
y = y(:);
