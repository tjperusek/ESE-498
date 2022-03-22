
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
cal1.Format = 'HH:mm';

%t=linspace(0,23.5,48);
%t=0/48:1/96:46/48+2/96;
%t=0/24:1/48:23/24+2/48;

t = datetime('now'):minutes(30):datetime('now')+hours(24);
t.Format = 'HH:mm';
t.TimeZone= 'America/Chicago';
plot(cal1(1:48),double(pv(1,1:48)));


xtickformat('HH:mm')
xlabel('Time')
ylabel('Solar AC Generation (kW)');
grid on;

% prices = zeros(1,49);
% prices(1:18) = 8.67;
% prices(19:42) = 8.92;
% prices(42:end) = 8.67;

% now=datestr(now,'dd/mm/yy');
% later=datestr(datetime('tomorrow'),'dd/mm/yy');
% infi = {now
%         later};
% infi = datenum(infi,'dd/mm/yyyy');
% days = infi(1):infi(2);
% out  = bsxfun(@plus, days, t.');

a = datenum(0/24:1/48:23/24+2/48);

C = datetime(datestr(a, 'HH:MM:SS.FFF'),'InputFormat','HH:mm:ss.SSS','Format','HH:mm');
C.TimeZone= 'America/Chicago';
for i=1:length(a)
if isbetween(t(i),C(19),C(43))
    prices(i)=8.67;
else
    prices(i)=8.92;
end

end

yyaxis right


plot(t,prices);
datetick('x', 'dd-mmm-yyyy HH:MM')
