%function estimation( file,obj )

file = 'configuration_SDA_Estimation.xml';
xDoc = xmlread(file);
rootNode = xDoc.getDocumentElement.getChildNodes;
node = rootNode.getFirstChild;

nbMetric = 0;

while ~isempty(node)
    if strcmpi(node.getNodeName, 'metric')
        data = [];
        returnedMetric = node.getAttribute('returnedMetric');
        subNode = node.getFirstChild;
        while ~isempty(subNode)
            if strcmpi(subNode.getNodeName, 'target')
                metric = strsplit(char(subNode.getTextContent),',');
                
                data_format = [];
                category_index = 1;
                category_count = 1;
                mapObj = containers.Map;
                temp_str = myobj.obtainData(metric{1},metric{2},metric{3});
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
                
            end
            if strcmpi(subNode.getNodeName, 'method')
                method = subNode.getTextContent;
            end
            if strcmpi(subNode.getNodeName, 'window')
                window = subNode.getTextContent;
            end
            if strcmpi(subNode.getNodeName, 'cpuUtil')
                cpuUtil = strsplit(char(subNode.getTextContent),',');
                %get cpu data
                
            end
            subNode = subNode.getNextSibling;
        end
        
        [data,delete] = dataFormat(rawData,window,cpu_value,cpu_timestamps);
        
        switch method
            case 'ci'
                
            case 'fcfs'
            case 'ubo'
            case 'ubr'
            case 'otherwise'
                warning('Unexpected method. No demand generated.');
        end
    end
    node = node.getNextSibling;
end


%end