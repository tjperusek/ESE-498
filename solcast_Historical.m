history = table2array(GetRooftopSiteEstimatedActuals);
pv=history(:,1);
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

sum = 0;
devices = [150; 450; 1400; 1500; 4500; 5000];
devices = devices/2000;
dhours = [16; 2; 2; 2; 2; 2];
array = zeros(49,9);
pv = double(pv);

for i=1:49
    array(i,1) = i;
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

    array(i,2) = pv(i);
end

sum = 0;
for i=1:49
    if (array(i,3) == 2)
        for k=1:6
            count = dhours(k);
            for j=1:dhours(k)
                if (pv(i) > devices(k))
                    if (count >= 0 && array(i+j-1,3) == 2 && sum < pv(i))
                        array(i+j-1,k+3) = devices(k);
                    end
                    count = count - 1;
                else
                    array(i+j-1,k+3) = 0;
                    count2 = 0;
                    array(count2+j,k+3) = devices(k);
                end
                count2 = count2 + 1;
            end
        end
        break;
    end
    if (array(i,3) == 0)
        array(i,4) = 0;
    end
    if (array(i,3) == 3)
        array(i,4) = 0;
    end
end