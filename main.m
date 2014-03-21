%function main(file)
%% main function, requires the configuration file as input
file = 'configuration_SDAR.xml';
% the required jar files
javaaddpath(fullfile(pwd,'lib/commons-lang3-3.1.jar'));
javaaddpath(fullfile(pwd,'lib/pdm-timeseriesforecasting-ce-TRUNK-SNAPSHOT.jar'));
javaaddpath(fullfile(pwd,'lib/weka.jar'))
javaaddpath(fullfile(pwd,'lib/wekaForecasting.jar'))
javaaddpath(fullfile(pwd,'lib/csparql_server-0.0.1.jar'));
javaaddpath(fullfile(pwd,'lib/csparql-rest-api-0.0.1.jar'));
javaaddpath(fullfile(pwd,'lib/commons-collections4-4.0-alpha1.jar'))
javaaddpath(fullfile(pwd,'lib/csparqlObserverJar.jar'),'-end');

% pwd
% ctfroot
% javaaddpath(fullfile(ctfroot,'main/csparql-rest-api-0.0.1.jar'));
% javaaddpath(fullfile(ctfroot,'main/csparql_server-0.0.1.jar'));
% javaaddpath(fullfile(ctfroot,'main/commons-collections4-4.0-alpha1.jar'))
% javaaddpath(fullfile(ctfroot,'main/csparqlObserverJar.jar'),'-end');

myweka = javaObject('weka.TimeSeriesForecasting');

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

myobj = javaObject('observer.Client_Server');

% parse the configuration file
xDoc = xmlread(file);
rootNode = xDoc.getDocumentElement.getChildNodes;
node = rootNode.getFirstChild;

nbMetric = 0;

while ~isempty(node)
    if strcmpi(node.getNodeName, 'metric')
        nbMetric = nbMetric + 1;
        temp = strsplit(char(node.getTextContent),',');
        metric{1,nbMetric} = {temp{1},temp{2},temp{3}};
        period(1,nbMetric) = str2double(node.getAttribute('period'));
        output{1,nbMetric} = char(node.getAttribute('output'));
        functions(1,nbMetric) = 1;
        temp_window = str2double(node.getAttribute('window'));
        if ~isnan(temp_window)
            window(1,nbMetric) = temp_window;
            temp_cpu = strsplit(char(node.getAttribute('cpuUtil')),',');
            cpuUtil{1,nbMetric} = {temp{1},temp_cpu{1},temp_cpu{2}};
            myobj.addMetric(temp{1},temp_cpu{1},temp_cpu{2});
        else
            window(1,nbMetric) = 0;
            cpuUtil{1,nbMetric} = 0;
        end
        myobj.addMetric(temp{1},temp{2},temp{3});
    elseif strcmpi(node.getNodeName, 'forecasting')
        nbMetric = nbMetric + 1;
        functions(1,nbMetric) = 2;
        temp = strsplit(char(node.getTextContent),',');
        metric{1,nbMetric} = {temp{1},temp{2},temp{3}};
        period(1,nbMetric) = str2double(node.getAttribute('period'));
        foreacasting_nbDataUsed(1,nbMetric) = str2double(node.getAttribute('nbDataUsed'));
        forecasting_reponse_metric{1,nbMetric} = char(node.getAttribute('class'));
        window(1,nbMetric) = str2double(node.getAttribute('window'));
    elseif strcmpi(node.getNodeName, 'forecastingml')
        nbMetric = nbMetric + 1;
        functions(1,nbMetric) = 3;
        period(1,nbMetric) = str2double(node.getAttribute('period'));
        sendBackName{1,nbMetric} = char(node.getAttribute('sendBackName'));
        %target{1,nbMetric} = char(node.getAttribute('target'));
        nbsubMetric(1,nbMetric) = 0;
        subNode = node.getChildNodes.getFirstChild;
        while ~isempty(subNode)
            if strcmpi(subNode.getNodeName, 'metric')
                nbsubMetric(1,nbMetric) = nbsubMetric + 1;
                temp = strsplit(char(subNode.getTextContent),',');
                subMetric{1,nbMetric}{1,nbsubMetric} = {temp{1},temp{2},temp{3}};
                ml_metricname{1,nbMetric}{1,nbsubMetric}=strcat(temp{1},'_',temp{2},'_',temp{3});
            end
            subNode = subNode.getNextSibling;
        end
    end
    node = node.getNextSibling;
end

myobj.main(strcat(pwd,'/',file));

value = cell(1,nbMetric);
timestamps = cell(1,nbMetric);
last_index = zeros(1,nbMetric);

cpu_value = cell(1,nbMetric);
cpu_timestamps = cell(1,nbMetric);
cpu_last_index = zeros(1,nbMetric);

data_format = [];
category_index = 1;
category_count = 1;

nextPauseTime = period;

% receiving data and parse it
while 1
    [pauseTime, index] = min(nextPauseTime);
    nextPauseTime = nextPauseTime - pauseTime;
    pause(pauseTime/1000)
    
    for i = index
        if functions(1,i) ~= 3
            if strcmp(metric{1,i}{3},'ResponseInfo')
                mapObj = containers.Map;
                temp_str = myobj.obtainData(metric{1,i}{1},metric{1,i}{2},metric{1,i}{3});
                if isempty(temp_str)
                    break;
                end
                
                values = temp_str.getValues;
                
                for j = 0:values.size-1
                    str = values.get(j);
                    str = java.lang.String(str);
                    split_str = str.split(',');
                    dateFormat = java.text.SimpleDateFormat('yyyyMMddHHmmssSSS');
                    
                    date_str = '';
                    
                    for k = 1:7
                        date_str = strcat(date_str,char(split_str(k)));
                    end
                    
                    try
                        date = dateFormat.parse(date_str);
                    catch e
                        e.printStackTrace();
                    end
                    
                    date_milli = date.getTime();
                    
                    jobID = char(split_str(8));
                    
                    category_str = char(split_str(9));
                    
                    if isKey(mapObj, category_str) == 0
                        mapObj(category_str) = category_index;
                        category_list{1,category_count} = category_str;
                        category_count = category_count + 1;
                        
                        category = category_index;
                        data_format{6,category}=[];
                        category_index = category_index + 1;
                    else
                        category = mapObj(category_str);
                    end
                    response_time = str2double(char(split_str(11)));
                    data_format{3,category} = [data_format{3,category};date_milli-response_time*1000];
                    data_format{4,category} = [data_format{4,category};response_time];
                end
                
                rawData = data_format;
                rawData{3, category_index} = [];
                
                [data,delete] = dataFormat(rawData,window(i));
                
                if functions(i) == 2
                    index = mapObj(forecasting_reponse_metric{1,i});
                    index_delete = delete<=index;
                    index = index - sum(index_delete);
                    
                    if index <= 0
                        continue;
                    end
                    
                    len = length(data{4,index});
                    if len-foreacasting_nbDataUsed(1,i)+1 < 0
                        start = 1;
                    else
                        start = len-foreacasting_nbDataUsed(1,i)+1;
                    end
                    forecastValue = data{4,index}(1:start:len,1);
                    foreacastTime = data{3,index}(1:start:len,1);
                    [ sendBackMetric, values ] = forecasting(forecastValue, foreacastTime);
                    myobj.sendData(sendBackMetric,values(end),'sdas');
                elseif functions(i) == 1
                    temp_str =  myobj.obtainData(cpuUtil{1,i}{1},cpuUtil{1,i}{2},cpuUtil{1,i}{3});
                    if isempty(temp_str)
                        continue;
                    end
                    value_str = temp_str.getValues;
                    timestamps_str = temp_str.getTimestamps;
                    
                    for j = 1:value_str.size
                        cpu_value{1,i}(1,cpu_last_index(i)+j) = str2double(value_str.get(j-1));
                        cpu_timestamps{1,i}(1,cpu_last_index(i)+j) = str2double(timestamps_str.get(j-1));
                    end
                    cpu_last_index(i) = cpu_last_index(i) + value_str.size;
                    
                    %generate formatted data
                    [data,delete] = dataFormat(rawData,window(i),cpu_value{1,i},cpu_timestamps{1,i});
                    
                    save(output{i},'data');
                    
                    cpu_value{1,i} = 0;
                    cpu_timestamps{1,i} = 0;
                    cpu_last_index(i) = 0;
                end
                % remove unnecessary data in memory
                clearvars rawData formattedData
            else
                temp_str =  myobj.obtainData(metric{1,i}{1},metric{1,i}{2},metric{1,i}{3});
                if isempty(temp_str)
                    break;
                end
                value_str = temp_str.getValues;
                timestamps_str = temp_str.getTimestamps;
                
                for j = 1:value_str.size
                    value{1,i}(1,last_index(i)+j) = str2double(value_str.get(j-1));
                    timestamps{1,i}(1,last_index(i)+j) = str2double(timestamps_str.get(j-1));
                end
                
                if functions(i) == 2
                    len = last_index(i) + value_str.size;
                    if len-foreacasting_nbDataUsed(1,i)+1 < 0
                        start = 1;
                    else
                        start = len-foreacasting_nbDataUsed(1,i)+1;
                    end
                    forecastValue = value{1,i}(1,start:len);
                    foreacastTime = timestamps{1,i}(1,start:len);
                    [ sendBackMetric, values ] = forecasting(forecastValue, foreacastTime);
                    myobj.sendData(sendBackMetric,values(end),'sdas');
                elseif functions(i) == 1
                    last_index(i) = last_index(i) + value_str.size;
                    
                    metric_value = value{1,i};
                    metric_timestamps = timestamps{1,i};
                    save(output{i},'metric_value','metric_timestamps');
                    
                    value{1,i} = 0;
                    timestamps{1,i} = 0;
                    last_index(i) = 0;
                end
                % remove unnecessary data in memory
                clearvars metric_value metric_timestamps
            end
        else
            flag = 0;
            for x = 1:nbsubMetric(1,i)
                if strcmp(subMetric{1,i}{1,x}{3},'ResponseInfo')
                    mapObj = containers.Map;
                    temp_str = myobj.obtainData(subMetric{1,i}{1,x}{1},subMetric{1,i}{1,x}{2},subMetric{1,i}{1,x}{3});
                    if isempty(temp_str)
                        break;
                    end
                    
                    values = temp_str.getValues;
                    
                    for j = 0:values.size-1
                        str = values.get(j);
                        str = java.lang.String(str);
                        split_str = str.split(',');
                        dateFormat = java.text.SimpleDateFormat('yyyyMMddHHmmssSSS');
                        
                        date_str = '';
                        
                        for k = 1:7
                            date_str = strcat(date_str,char(split_str(k)));
                        end
                        
                        try
                            date = dateFormat.parse(date_str);
                        catch e
                            e.printStackTrace();
                        end
                        
                        date_milli = date.getTime();
                        
                        jobID = char(split_str(8));
                        
                        category_str = char(split_str(9));
                        
                        if isKey(mapObj, category_str) == 0
                            mapObj(category_str) = category_index;
                            category_list{1,category_count} = category_str;
                            category_count = category_count + 1;
                            
                            category = category_index;
                            data_format{6,category}=[];
                            category_index = category_index + 1;
                        else
                            category = mapObj(category_str);
                        end
                        response_time = str2double(char(split_str(11)));
                        data_format{3,category} = [data_format{3,category};date_milli-response_time*1000];
                        data_format{4,category} = [data_format{4,category};response_time];
                    end
                    
                    timestamps = [];
                    value = [];
                    for h = 1:size(data_format,2)
                        timestamps = [timestamps;data_format{3,category}];
                        value = [value;data_format{4,category}];
                    end
                    
                    [timestamps,index] = sort(timestamps);
                    value = value(index);
                    
                    temp_data_arff{x,1} = timestamps;
                    temp_data_arff{x,2} = value;  
                    
                    flag = x;
                    clearvars value timestamps;
                else
                    temp_str = myobj.obtainData(subMetric{1,i}{1,x}{1},subMetric{1,i}{1,x}{2},subMetric{1,i}{1,x}{3});
                    if isempty(temp_str)
                        break;
                    end
                    value_str = temp_str.getValues;
                    timestamps_str = temp_str.getTimestamps;
                    
                    for j = 1:value_str.size
                        value(1,j) = str2double(value_str.get(j-1));
                        timestamps(1,j) = str2double(timestamps_str.get(j-1));
                    end
                    
                    temp_data_arff{x,1} = timestamps;
                    temp_data_arff{x,2} = value;
                    clearvars value timestamps;

                end
            end
            
            mat2arff(temp_data_arff,flag,ml_metricname{1,i});
            forecastml_value = myweka.compute('configuration_SDAR_ForecastingML.xml');
            myobj.sendData(sendBackName{1,nbMetric},forecastml_value(end,:),'sdas');
        end
    end
    
    nextPauseTime(index) = period(index);
end
