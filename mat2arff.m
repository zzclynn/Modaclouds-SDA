function mat2arff(data,flag,name)

dataarff = struct();
relname = 'data';
outfile = 'data.arff';

if flag > 0
    basic_timestamps = data{flag,1};
else
    min_length = inf;
    for i = 1:size(data,1)
        if length(data{i,1}) < min_length;
            flag = i;
        end
    end
    
    basic_timestamps = data{flag,1};
end

for i = 1:size(data,1)
    if (i ~= flag)
        data{i,2} = interp1(data{i,1},data{i,2},basic_timestamps);
    end
end

for i = 1:length(basic_timestamps)
    dataarff(i).time = basic_timestamps(i);
    for j = 1:size(data,1)
        dataarff(i).(name{1,j}) = data{j,2}(i);
    end
end
    
arff_write(outfile, dataarff, relname);

end