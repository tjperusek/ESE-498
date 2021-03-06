
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
plot(cal1(1:49),double(pv(1,1:49)));
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

% Season span
today = datetime('today');
mo_lower = datetime(2022,5,1);
mo_higher = datetime(2022,10,1);
% True: Winter; False: Summer
boolean season;

% Determine the season
if (isbetween(today, mo_lower, mo_higher))
    season = false;
else
    season = true;
end

pricesF = zeros(1,49);
for i=1:length(a)
    if (hour(t(i))>=hour(tLower) && hour(t(i))<hour(tUpper))
        if (season == true)
            pricesF(i) = 8.92;
        else
            pricesF(i) = 13.13;
        end
    else
        if (season == true)
            pricesF(i) = 8.67;
        else
            pricesF(i) = 12.58;
        end
    end
end

yyaxis right

plot(t,pricesF);
datetick('x', 'dd-mmm-yyyy HH:MM')
ylabel('Cents per kWh')

%%

% Inputs
devices = [150; 450; 1400; 1500; 4500; 5000];
devices = devices/2000;
dhours = [16; 2; 2; 2; 2; 2];
threshold = 0.5;
thresh_diff = linspace(0,3);
%thresh_diff = 0.6;



for optimizer = 1:length(thresh_diff)
    % Empty Scheduling Array
    array = zeros(49,9);

    % First Column: 24 hours at half hour increments starting at the current
    % time
    array(:,1) = hour(cal1(1:49));
    % Second Column: forecasted PV (kW) at each half hour for 24 hours
    array(:,2) = double(pv(1,1:49))';

    % Winter
    if (season == true)
        for i=1:49
            if (pricesF(i) == 8.67 && pv(i) < threshold)
                % GRID
                array(i,3) = 1;
            elseif (pricesF(i) == 8.67 && pv(i) >= threshold)
                % STORE
                array(i,3) = 2;
            elseif (pricesF(i) == 8.92 && pv(i) >= threshold)
                % SOLAR
                array(i,3) = 2;
            else
                % NOTHING
                array(i,3) = 0;
            end
        end
    end
    % Summer
    if (season == false)
        for i=1:49
            if (pricesF(i) == 12.58 && pv(i) < threshold)
                % GRID
                array(i,3) = 1;
            elseif (pricesF(i) == 12.58 && pv(i) >= threshold)
                % STORE
                array(i,3) = 2;
            elseif (pricesF(i) == 13.13 && pv(i) >= threshold)
                % SOLAR
                array(i,3) = 2;
            else
                % NOTHING
                array(i,3) = 0;
            end
        end
    end

    % Search for the first instance that we should use solar for as many
    % devices as possible
    for i=1:49
        if (array(i,3) == 2)
            index = i;
            break;
        end
    end

    % Create check array for when to schedule.
    % 1: schedule at current index (solar)
    % -1: schedule at off-peak pricing (grid)
    % 0: schedule after last device ran (solar) if available, if not at
    % off-peak
    check = zeros(1,6);

    % Last check helps to clarify the devices that can and cannot be run on
    % solar. 0->0: cannot run (run on grid). 1->1: can run (run on solar at
    % current index). 0->1: couldn't run, now can (run on solar at his later
    % index). 1->0: could run, now can't (run on grid).
    last_check = 1;

    % Increment the device
    j = 1;
    while (j < 7)
        % Reset sum after incrementing device
        sum = 0;
        % Find the sum of all devices previously ran at the first solar index
        for q=1:j
            sum = sum + array(index,q+3);
        end
        % Ensure that the current device can also be ran
        sum = sum + devices(j);
        for k=1:dhours(j)
            % Check to see if we should use solar for the entire device
            % duration
            if (array(index+k-1,3) == 2)
                % Check to see if solar power generated is greater than the sum
                % of all devices and all devices can be ran during the entire
                % running duration
                if ((array(index+k-1,2) + thresh_diff(optimizer)) >= sum && (array(index+k-1,2) + thresh_diff(optimizer)) >= devices(j))
                    check(j) = 1;
                    % Schedule the device on solar if for all hours check = 1
                    if (k == dhours(j) && last_check == 1)
                        for r=1:k
                            array(index+r-1,j+3) = devices(j);
                        end
                        j = j + 1;
                        break;
                        % If not, the device has two future possibilities: can run
                        % on solar at a later index or on grid. This is determined
                        % in later logic.
                    elseif (k == dhours(j) && last_check == 0)
                        check(j) = 0;
                        j = j + 1;
                        break;
                    end
                    last_check = 1;
                else
                    check(j) = 0;
                    if (k == dhours(j) && last_check == 0)
                        j = j + 1;
                        break;
                    end
                    last_check = 0;
                end
                % This is the situation where last check is 1->0, so it cannot be
                % ran because the threshold > solar generated. Will run on grid
            elseif (array(index+k-1,3) ~= 2 && last_check == 1)
                check(j) = -1;
                j = j + 1;
                break;
            end
            if (index + k - 1 == 49)
                check(j) = -1;
                break;
            end
        end
        if (j == 7)
            break;
        end
    end

    j = 1;
    count = 0;
    while (j < 7)
        % Device has to be ran on the grid at off-peak pricing
        if (check(j) == -1)
            time_left = 0;
            for n=1:49
                % Searching for when in the array the recommendation is grid
                % and schedule the device
                if (array(n,3) == 1)
                    array(n,j+3) = devices(j);
                    time_left = time_left + 1;
                end
                % Break after the device is scheduled for the entire device
                % duration and increment device
                if (time_left == dhours(j))
                    time_left = 0;
                    j = j + 1;
                    break;
                end
            end
        elseif (check(j) == 0)
            sum = 0;
            for q=1:j
                if (j > 1)
                    sum = sum + array(index+dhours(j-1),q+3);
                else
                    sum = 0;
                end
            end
            sum = sum + devices(j);
            index2 = index;
            for k=1:dhours(j)
                if (array(index2+k-1+dhours(j-1),3) == 2)
                    if ((array(index2+k-1+dhours(j-1),2) + thresh_diff(optimizer)) >= sum && (array(index2+k-1+dhours(j-1),2) + thresh_diff(optimizer)) >= devices(j))
                        last_check = 1;
                        if (k == dhours(j) && last_check == 1)
                            for r=1:k
                                array(index2+r-1+dhours(j-1),j+3) = devices(j);
                            end
                            count = index2 - index;
                            j = j + 1;
                            break;
                        end
                    else
                        index2 = index + count + dhours(j-1);
                        sum = 0;
                        for q=1:j
                            if (j > 1)
                                sum = sum + array(index2+dhours(j-1),q+3);
                            else
                                sum = 0;
                            end
                        end
                        sum = sum + devices(j);

                        if ((array(index2+k-1+dhours(j-1),2) + thresh_diff(optimizer)) >= sum && (array(index2+k-1+dhours(j-1),2) + thresh_diff(optimizer)) >= devices(j))
                            last_check = 1;
                        else
                            last_check = 0;
                        end

                        if (last_check == 0)
                            time_left = 0;
                            for n=1:49
                                % Searching for when in the array the recommendation is
                                % grid. Subtract by 1 because n starts at index 1
                                if (array(n,3) == 1)
                                    array(n,j+3) = devices(j);
                                    time_left = time_left + 1;
                                end
                                if (time_left == dhours(j))
                                    time_left = 0;
                                    j = j + 1;
                                    break;
                                end
                            end
                        end
                    end
                    if (j == 7)
                        break;
                    end
                end
            end
        elseif (check(j) == 1)
            j = j + 1;
        end
    end

    for p=1:49
        tot_sum = 0;
        for q=4:9
            tot_sum = tot_sum + array(p,q);
            array(p,10) = tot_sum;
        end
    end


    %%% Random Assortment %%%
    % Empty Scheduling Array
    arrayRand= zeros(49,9);

    % First Column: 24 hours at half hour increments starting at the current
    % time
    arrayRand(:,1) = hour(cal1(1:49));
    % Second Column: forecasted PV (kW) at each half hour for 24 hours
    arrayRand(:,2) = double(pv(1,1:49))';
    for z = 1:6
        randomStart=randi(49-dhours(z));
        for y=1:dhours(z)
            arrayRand(randomStart+y-1,z+2)=devices(z);
        end
    end
    for p=1:49
        tot_sum = 0;
        for q=3:8
            tot_sum = tot_sum + arrayRand(p,q);
            arrayRand(p,9) = tot_sum;
        end
    end
    randCost=0;
    for i=1:49
        if (arrayRand(i,9)-arrayRand(i,2))>0
            randCost = randCost + (arrayRand(i,9)-arrayRand(i,2))*pricesF(i);
        end
    end




    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %function modelCost = solveCost(thresh_diff,array,pricesF)
    modelCost=0;
    for i=1:49
        if (array(i,10)-array(i,2))>0
            modelCost = modelCost + (array(i,10)-array(i,2))*pricesF(i);
        end
    end
    if optimizer ==1
        MinModelCost=modelCost;
        if MinModelCost==0
            bestThresh = thresh_diff(optimizer);
            break;
        end
    end
    if MinModelCost>0
        if(modelCost<MinModelCost)
            MinModelCost=modelCost;
            bestThresh = thresh_diff(optimizer);
        end
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

