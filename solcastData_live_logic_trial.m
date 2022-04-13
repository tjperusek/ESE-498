
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
pricesF = zeros(1,49);
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

%% 

devices = [150; 450; 1400; 1500; 4500; 5000];
devices = devices/2000;
dhours = [16; 2; 2; 2; 2; 2];
array = zeros(49,9);
array(:,1) = hour(cal1(1:49));
array(:,2) = double(pv(1,1:49))';
for i=1:49
    %array(i,1) = i;
    if (pricesF(i) == 8.67 && pv(i) < 0.5)
        %array(i,1) = 'grid';
        array(i,3) = 1;
    elseif (pricesF(i) == 8.67 && pv(i) >= 0.5)
        %array(i,1) = 'store';
        array(i,3) = 3;
    elseif (pricesF(i) == 8.92 && pv(i) >= 0.5)
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
        % Reset sum when going to next device
        sum = 0;
        %for r=1:49
            for m=1:dhours(j)
                % Finding the sum of the past devices at the given index
                % and then adding the device to be run to see if it can
                % still be run
                for q=1:j
                    sum = sum + array(i,q+3);
                end
                sum = sum + devices(j);
                % Check to see if the device can be ran for entire running time
                % during solar
                if (array(i+m-1,2) >= sum && array(i+m-1,2) >= devices(j))
                    check(j) = 1;
                else
                    check(j) = 0;
                end
            %end
        end

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
                        array(i+k-1+dhours(j-1),j+3) = devices(j);
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
xlabel('Time')
ylabel('Solar AC Generation (kW)');
title('Yesterday to Tomorrow Solar')
grid on;
yyaxis right
datetick('x', 'dd-mmm-yyyy HH:MM')
ylabel('Cents per kWh')
plot(tTot,pricesTotal);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%