function y = DFT3(x,inputsize,dir)

% y = DFT3(x,numdiff,inputsize,dir)
%
% dir = 0 for forward, 1 for inverse

y = reshape(x,inputsize);
if dir
    y = ifftn(y);
else
    y = fftn(y);
end
y = y(:);