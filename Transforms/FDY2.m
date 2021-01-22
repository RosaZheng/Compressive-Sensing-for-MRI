function y = FDY2(x,numdiff,inputsize,dir)

% y = FDY2(x,numdiff,inputsize,dir)
%
% implements a finite difference operator in y axis
%
% dir = 0 for forward, 1 for inverse

y = reshape(x,inputsize);
if dir
    for a=1:numdiff
        y = cumsum(y,1);
    end
else
    for a=1:numdiff
        y = [y(1,:);diff(y,1,1)];
    end
end
y = y(:);

