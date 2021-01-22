function fullspace = oneD_to_twoD(x,mask)

row = size(mask,1);
col = size(mask,2);

fullspace = zeros(row,col);
ind = 1;
for a=1:row
    for b=1:col
        if(mask(a,b))
           fullspace(a,b) = x(ind);
           ind = ind + 1;
        end
    end
end

end

