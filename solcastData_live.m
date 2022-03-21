
username = 'kLb3oN5PLu_uJopDliGYblcz3vSt_EzB';
password = '';
% Manually set Authorization header field in weboptions
options = weboptions('HeaderFields',{'Authorization',...
    ['Basic ' matlab.net.base64encode([username ':' password])]});
dataUrl = "https://api.solcast.com.au/rooftop_sites/{c28d-86a5-e368-39f6}/forecasts";
data = webread(dataUrl, options);

%% 
pv=[data.forecasts.pv_estimate];
cal1 = datetime(period_end,'TimeZone','UTC','InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSSSSSS''Z');
blank = isnat(cal1);
for i =1:length(blank)
    if(blank(i))
        cal1(i)=datetime(period_end(i),'TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSS''Z');
    end
end
cal1.TimeZone= 'America/Chicago';
cal1.Format = 'hh:mm';

%t=linspace(0,23.5,48);
t=0/24:1/48:23/24+2/48;
plot(cal1(1:48),double(pv(1,1:48)));

xtickformat('hh:mm')
xlabel('Time')
ylabel('Solar AC Generation (kW)');
grid on;

prices = zeros(1,49);
prices(1:18) = 8.67;
prices(19:42) = 8.92;
prices(42:end) = 8.67;
dv = 0/96:1/48:23/96+2/48;

yyaxis right
d = datetime(0:minutes(30):days(2));
plot(dv,prices);
