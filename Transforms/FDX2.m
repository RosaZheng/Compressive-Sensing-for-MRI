function y = FDX2(x,numdiff,inputsize,dir)

% y = FDX2(x,numdiff,inputsize,dir)
%
% implements a finite difference operator in x axis
%
% dir = 0 for forward, 1 for inverse

y = reshape(x,inputsize);
if dir
    for a=1:numdiff
        y = cumsum(y,2);
    end
else
    for a=1:numdiff
        y = [y(:,1) diff(y,1,2)];
    end
end
y = y(:);

