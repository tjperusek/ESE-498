

numTime = datenum(cal1(1:49));
bar(numTime,[array(:,10) array(:,2)]);
%hold on

yyaxis right
plot(numTime,pricesF);
datetick('x', 'dd-mmm-yyyy HH:MM')
ylabel('Cents per kWh')

datetick('x',15)
xlabel('Time');
ylabel('Watts')
legend('Used','Generated')

C = ['r','g','b','m','c','k'];
simplyDevice = array(:,4:9);
figure(2)
for k = 1:6
    tick = 0;
    first = 0;
    timeVect =[];
    for i=1:length(array)
        if(simplyDevice(i,k)~=0) %make sure we are running a device
            first = first +1;
            y=simplyDevice(i,k);
            tick = tick+1;
            timeVect = [timeVect cal1(i,1)];
        end
    end
    yAx= y*(ones(tick,1));
    line(timeVect,yAx,'color',C(k),'LineWidth',3.0)
    hold on
end
legend('EV','Dryer','Laundry Machine',...
    'Dish Washer','Water Heater','Vacuum');