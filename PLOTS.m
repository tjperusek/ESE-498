% for k = 1:6
%     for i=1:length(array)
%         if(simplyDevice(i,k)~=0)
%            
%         end
%     end
% end

numTime = datenum(cal1(1:49));
bar(numTime,[array(:,10) array(:,2)]);
hold on
for k=4:9
plot(numTime,array(:,k))
hold on
end
datetick('x',15)
xlabel('Time');
ylabel('Watts')
legend('Used','Generated')


