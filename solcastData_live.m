
username = 'kLb3oN5PLu_uJopDliGYblcz3vSt_EzB';
password = '';
% Manually set Authorization header field in weboptions
options = weboptions('HeaderFields',{'Authorization',...
    ['Basic ' matlab.net.base64encode([username ':' password])]});
dataUrl = "https://api.solcast.com.au/rooftop_sites/{c28d-86a5-e368-39f6}/forecasts";
pastUrl = "https://api.solcast.com.au/rooftop_sites/{c28d-86a5-e368-39f6}/estimated_actuals";
data = webread(dataUrl, options);
dataPast = webread(pastUrl, options);

%% 
pv=[data.forecasts.pv_estimate];
pvPast=[dataPast.estimated_actuals.pv_estimate];
period_end = {data.forecasts.period_end}.';
period_past = {dataPast.estimated_actuals.period_end}.';
cal1 = datetime(period_end,'TimeZone','UTC','InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSSSSSS''Z');
calPast = datetime(period_past,'TimeZone','UTC','InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSSSSSS''Z');
blank = isnat(cal1);
for i =1:length(blank)
    if(blank(i))
        cal1(i)=datetime(period_end(i),'TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSS''Z');
    end
end
cal1.TimeZone= 'America/Chicago';
cal1.Format = 'HH:mm';
calPast.TimeZone= 'America/Chicago';
calPast.Format = 'HH:mm';

%t=linspace(0,23.5,48);
%t=0/48:1/96:46/48+2/96;
%t=0/24:1/48:23/24+2/48;

t = datetime('now'):minutes(30):datetime('now')+hours(24);
t.Format = 'HH:mm';
t.TimeZone= 'America/Chicago';
figure(1)
plot(cal1(1:48),double(pv(1,1:48)));
xtickformat('HH:mm')
title('Tomorrow')
xlabel('Time')
ylabel('Solar AC Generation (kW)');
grid on;



a = datenum(0/24:1/48:23/24+2/48);
tUpper=datetime("21:00",'InputFormat','HH:mm','Format','HH:mm');
tLower=datetime("09:00",'InputFormat','HH:mm','Format','HH:mm');
%C = datetime(datestr(a, 'HH:mm'),'InputFormat','HH:mm','Format','HH:mm');
%C.TimeZone= 'America/Chicago';
pricesF=zeros(1,49);
for i=1:length(a)
    if  hour(t(i))>=hour(tLower)&&hour(t(i))<hour(tUpper)
        pricesF(i)=8.92;
    else
        pricesF(i)=8.67;
    end

end

yyaxis right

plot(t,pricesF);
datetick('x', 'dd-mmm-yyyy HH:MM')
ylabel('Cents per kWh')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
plot(calPast(1:48),double(pvPast(1:48)))
xlabel('Time')
ylabel('Solar AC Generation (kW)');
title('Solar AC Yesterday')
grid on;
tPast = datetime('now')-hours(24):minutes(30):datetime('now');
tPast.Format = 'HH:mm';
tPast.TimeZone= 'America/Chicago';
pricesPast=zeros(1,49);
for i=1:length(a)
    if  hour(tPast(i))>=hour(tLower)&&hour(tPast(i))<hour(tUpper)
        pricesPast(i)=8.92;
    else
        pricesPast(i)=8.67;
    end

end

yyaxis right
plot(tPast,pricesPast);
datetick('x', 'dd-mmm-yyyy HH:MM')
ylabel('Cents per kWh')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tTot = [tPast t];
pricesTotal = zeros(1,98);
for i=1:length(tTot)
    if  hour(tTot(i))>=hour(tLower)&&hour(tTot(i))<hour(tUpper)
        pricesTotal(i)=8.92;
    else
        pricesTotal(i)=8.67;
    end

end
figure(3)
plot(calPast(1:48),double(pvPast(1:48)),'r',cal1(1:48),double(pv(1,1:48)),'b')
yyaxis right
plot(tTot,pricesTotal);
