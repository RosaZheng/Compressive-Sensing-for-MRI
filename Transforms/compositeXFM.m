function y = compositeXFM(x,XFM,timebasis,inputsize,dir)

% y = compositeXFM(x,XFM,numdiff,inputsize,dir)
%
% implements a composite 3D transform in both time and space
%
% dir = 0 for forward, 1 for inverse

y = reshape(x,inputsize);
if(dir)
    
    if(~isempty(strfind(timebasis,'DFT')))
        
        % DFT
        y = ifft(y,[],3);
        
    elseif(~isempty(strfind(timebasis,'DCT')))
        
        % DCT
        for a = 1:inputsize(1)
            for b = 1:inputsize(2)
                y(a,b,:) = idct(y(a,b,:));
            end
        end
        
    elseif(~isempty(strfind(timebasis,'FD')))
        
        % Finite differences
        y = cumsum(y,3);
        
    end

    for a=1:inputsize(3)
        z = y(:,:,a);
        z = z(:);
        y(:,:,a) = reshape(XFM(z),inputsize(1:2));
    end
    
else

    for a=1:inputsize(3)
        z = y(:,:,a);
        z = z(:);
        y(:,:,a) = reshape(XFM(z),inputsize(1:2));
    end
    
    if(~isempty(strfind(timebasis,'DFT')))

        % DFT
        y = fft(y,[],3);

    elseif(~isempty(strfind(timebasis,'DCT')))

        % DCT
        for a = 1:inputsize(1)
            for b = 1:inputsize(2)
                y(a,b,:) = dct(y(a,b,:));
            end
        end
        
    elseif(~isempty(strfind(timebasis,'FD')))
        
        % Finite differences
        y = cat(3,y(:,:,1),diff(y,1,3));
        
    end

end
y = y(:);

