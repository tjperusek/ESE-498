devices = [150; 450; 1400; 1500; 4500; 5000];
devices = devices/2000;
dhours = [16; 2; 2; 2; 2; 2];
array = zeros(49,10);
array(:,1) = hour(cal1(1:49));
array(:,2)=double(pv(1,1:49))';


for i=1:49
    %array(i,1) = i;
    if (pricesF(i) == 8.67 && pv(i) < 0.5)
        %array(i,1) = 'grid';
        array(i,3) = 1;
    elseif (pricesF(i) == 8.67 && pv(i) >= 0.5)
        %array(i,1) = 'store';
        array(i,3) = 3;
    elseif (pricesF(i) == 8.92 && pv(i) >= 0.5)
        %array(i,1) = 'solar';
        array(i,3) = 2;
    else
        %array(i,1) = 'do nothing';
        array(i,3) = 0;
    end

end

bin = zeros(1,49);
counter = 0;
    for g=1:6 %each device
        for h=1:dhours(g)
            if pv(counter+h) > devices(g)
                bin(counter+h) = 1;

            else
                bin(counter+h)=0;
            end
         counter = counter +1;
        end
    end



for i=1:49
count = 1;
    for k=1:6 %each device
        %length = dhours(k);
        if (array(i,3) == 2)  %make sure it's solar
            for m=1:dhours(k)   %for each of the lengthh
                if  (pv(i+m-1) > devices(k))
                    check = 1;
                else
                    check =0;
                    break
                end
            end
            if(check==1)            %if check passes
                %if array(i+m-1,k+3)
                for m=1:dhours(k) %for the duration of that device
                    array(i+m-1,k+3) = devices(k);
                end
            else
                array(i+m-1,k+3) = 0;
            end

        elseif array(i,3) == 1  %electricity low and generation lower than device
            for m=1:dhours(k) %for the duration of that device
                if ismember(0,bin(i:i+dhours(k))) 
                    array(i+m-1,k+3) = 0;
                else
                    array(i+m-1,k+3) = devices(k);
                end
            end
      
        else% do nothing
            for m=1:dhours(k) %for the duration of that device
                array(i+m-1,k+3) = 0;
            end
        end
       %count = count+ 1;
    end
   
    tot_sum = 0;
    for q=4:9
        tot_sum = tot_sum + array(i,q);
        array(i,10) = tot_sum;
    end
end


             