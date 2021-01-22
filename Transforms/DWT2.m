function y = DWT2(x,wavName,wavScale,inputsize,s,dir)

% y = DWT2(x,wavName,wavScale,inputsize,dir)
%
% implements a wavelet operator
%
% dir = 0 for forward, 1 for inverse

x = reshape(x,inputsize);
if dir
    y = waverec2(x,s,wavName);
    y = conj(y);
else
    [y,~] = wavedec2(x,wavScale,wavName);
end
y = y(:);

