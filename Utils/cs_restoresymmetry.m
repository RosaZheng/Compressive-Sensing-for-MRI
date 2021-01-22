% Restores origin symmetric coefficients to a mask of an image

function y = cs_restoresymmetry(x)

    [row col] = size(x);

    y = x;
    roweven = 1-mod(row,2);
    coleven = 1-mod(col,2);
    
    for a = (1+roweven):row
        for b = (1+coleven):floor(col/2)
        	m = x(row-a+1+roweven,col-b+1+coleven);
            if(m~=0)
                y(a,b) = m;
            end
        end
    end
   
end

