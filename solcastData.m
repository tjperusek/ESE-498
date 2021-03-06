
username = 'kLb3oN5PLu_uJopDliGYblcz3vSt_EzB';
password = '';
% Manually set Authorization header field in weboptions
options = weboptions('HeaderFields',{'Authorization',...
    ['Basic ' matlab.net.base64encode([username ':' password])]});
dataUrl = "https://api.solcast.com.au/rooftop_sites/{c28d-86a5-e368-39f6}/forecasts";
data = webread(dataUrl, options);

pv=[data.forecasts.pv_estimate];

t=linspace(0,23.5,48);
plot(t,pv(1:48));
xticks(0:0.5:23.5);
xtickformat('hh:mm')
xlabel('Time')
ylabel('Solar AC Generation (kW)');
grid on;


