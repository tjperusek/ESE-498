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


