history = table2array(GetRooftopSiteEstimatedActuals);
pv=history(:,1);
pv = double(pv);
dateHist = history(:,2);
datetime1 = datetime(dateHist,'TimeZone','UTC','InputFormat','yyyy-MM-dd''T''HH:mm:ssZ');
blank = isnat(datetime1);
for i =1:length(blank)
    if(blank(i))
        datetime1(i)=datetime(dateHist(i),'TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssZ');
    end
end
datetime1.TimeZone= 'America/Chicago';
datetime1.Format = 'hh:mm';
%t=linspace(0,23.5,48);
%xticks(0:0.5:23.5);
%xtickformat('hh:mm')
plot(datetime1,double(pv));
xlabel('Time')
ylabel('Solar AC Generation (kW)');
title('Historical Solar Generation and Price per Watt Comparison');
grid on;

prices = zeros(1,49);
prices(1:18) = 8.67;
prices(19:42) = 8.92;
prices(42:end) = 8.67;
dv = 0/24:1/48:23/24+2/48;

yyaxis right
%plot(dv,prices);

devices = [150; 450; 1400; 1500; 4500; 5000];
devices = devices/2000;
dhours = [16; 2; 2; 2; 2; 2];
array = zeros(49,9);
array(:,1) = 1:49;
array(:,2) = double(pv(1:49,1))';
for i=1:49
    %array(i,1) = i;
    if (prices(i) == 8.67 && pv(i) < 0.5)
        %array(i,1) = 'grid';
        array(i,3) = 1;
    elseif (prices(i) == 8.67 && pv(i) >= 0.5)
        %array(i,1) = 'store';
        array(i,3) = 3;
    elseif (prices(i) == 8.92 && pv(i) >= 0.5)
        %array(i,1) = 'solar';
        array(i,3) = 2;
    else
        %array(i,1) = 'do nothing';
        array(i,3) = 0;
    end

end

check = zeros(1,6);
j = 1;
for i=1:49
    % Device counter
    while (j < 7)
    %for k=1:dhours(j)
        % Reset sum when going to next device
        sum = 0;
        for m=1:dhours(j)
            % Check to see if the device can be ran for entire running time
            % during solar
            for q=1:j
                sum = sum + array(i,q+3);
            end
            sum = sum + devices(j);
            if (array(i+m-1,2) >= sum && array(i+m-1,2) >= devices(j))
                check(j) = 1;
            else
                check(j) = 0;
                break;
            end
        end
        % Counter for the hours the device should be run while summing
        sum_count = 0;
        for k=1:dhours(j)
            % If the recommendation is solar and the device can be ran for
            % the entire running time
            if (array(i+k-1,3) == 2 && check(j) == 1)
                % If the solar generation is greater than the sum of the
                % current running devices at that half hour, run the next
                % device as well
                if (array(i+k-1,2) >= sum)
                    array(i+k-1,j+3) = devices(j);
                % Run the device after the previous device is finished
                else
                    if (array(i+k-1+dhours(j-1),3) == 2)
                        array(i+k-1,j+3) = devices(j);
                    end
                end
            else
                check(j) = 0;
            end
        end
        
        time_left = 0;
        for n=1:49
            % Searching for when in the array the recommendation is
            % grid. Subtract by 1 because n starts at index 1
            if (array(n,3) == 1 && check(j) == 0)
                array(n,j+3) = devices(j);
                time_left = time_left + 1;
            end
            if (time_left == dhours(j))
                time_left = 0;
                break;
            end
        end

        if (array(i,3) == 0)
            array(i,j+3) = 0;
        end
        if (array(i,3) == 3)
            array(i,j+3) = 0;
        end
        % Increment which device we are placing in the array
        j = j + 1;
    end
end