function x = twoD_to_oneD(fullspace,mask)

row = size(mask,1);
col = size(mask,2);

x = zeros(sum(sum(mask)),1);
ind = 1;
for a=1:row
    for b=1:col
        if(mask(a,b))
           x(ind) = fullspace(a,b);
           ind = ind + 1;
        end
    end
end

end

