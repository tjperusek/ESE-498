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
grid on;

prices = zeros(1,49);
prices(1:18) = 8.67;
prices(19:42) = 8.92;
prices(42:end) = 8.67;
dv = 0/24:1/48:23/24+2/48;

yyaxis right
plot(dv,prices);

sum = 0;
devices = [150; 450; 1400; 1500; 4500; 5000];
array = zeros(2,49);
pv = double(pv);
for i=1:49
    for j=1:20
        if (prices(i) == 8.67 && pv(i) < 0.5)
            %array(i,1) = 'grid';
            array(i,1) = 1;
        elseif (prices(i) == 8.67 && pv(i) >= 0.5)
            %array(i,1) = 'store';
            array(i,1) = 3;
        elseif (prices(i) == 8.92 && pv(i) >= 0.5)
            count = 1;
            while (count <= length(devices))
                array(i,1) = 2;
                if (pv(i) > devices(count)/1000)
                    %array(i,1) = 'solar';
%                         sum = sum + devices(count);
%                         array(i,2) = sum;
                    array(i,j) = devices(count);
%                     else
%                         %array(i,1) = 'do nothing';
%                         array(i,1) = 0;
                end
                count = count + 1;
            end
        else
            %array(i,1) = 'do nothing';
            array(i,1) = 0;
        end
        
    end
end
