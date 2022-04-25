
numTime = datenum(cal1(1:49));
bar(numTime,[array(:,10) array(:,2)]);
xlabel('Time');
ylabel('KW')
legend('Used','Generated')
%hold on

yyaxis right
plot(numTime,pricesF);
datetick('x', 'mmm dd, HH:MM')
ylabel('Cents per kWh')

%datetick('x',15)



C = ['r','g','b','m','c','k'];
simplyDevice = array(:,4:9);
figure(2)
for k = 1:6
    tick = 0;
    timeVect =[];
    for i=1:length(array)
        if(simplyDevice(i,k)~=0) %make sure we are running a device
            y=simplyDevice(i,k);
            tick = tick+1;
            timeVect = [timeVect cal1(i,1)];
        end
    end
    yAx= y*(ones(tick,1));
    line(timeVect,yAx,'color',C(k),'LineWidth',8.0)
    hold on
end
grid;
xlabel('Time')
ylabel('KW')
title('Devices Run Time')
yyaxis right
plot(cal1(1:49),pricesF,'color',[0.9290, 0.6940, 0.1250]);
ylabel('Cents per kWh')
legend('EV','Vacuum','Water Heater',...
    'Dish Washer','Laundry Machine','Dryer','Electricity Price');