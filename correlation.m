function correlation( file,isTraining,obj )

xDoc = xmlread(file);
rootNode = xDoc.getDocumentElement.getChildNodes;
node = rootNode.getFirstChild;

nbMetric = 0;

while ~isempty(node)
    if strcmpi(node.getNodeName, 'metric')
        data = [];
        metricName = [];
        returnedMetric = node.getAttribute('returnedMetric');
        subNode = node.getFirstChild;
        while ~isempty(subNode)
            if strcmpi(subNode.getNodeName, 'target')
                metric = strsplit(char(subNode.getTextContent),',');
                
                nbMetric = nbMetric + 1;
                metricName{1,nbMetric} = strcat(metric{1,1},'_',metric{1,2},'_',metric{1,3});
                
                % data{nbMetric,1} = timestamps;
                % data{nbMetric,2} = values;
            end
            if strcmpi(subNode.getNodeName, 'method')
                method = subNode.getTextContent;
            end
            if strcmpi(subNode.getNodeName, 'otherMetric')
                otherMetric = strsplit(char(subNode.getTextContent),',');
                
                nbMetric = nbMetric + 1;
                metricName{1,nbMetric} = strcat(otherMetric{1,1},'_',otherMetric{1,2},'_',otherMetric{1,3});
                
                % data{nbMetric,1} = timestamps;
                % data{nbMetric,2} = values;
            end
            subNode = subNode.getNextSibling;
        end
        
        if (isTraining)
            data{1,1}=[2.1,2.3,3,4,5];
            data{1,2}=[11,2,3,52,3];
            data{2,1}=[1.5,2.5,3.5,4.5,5.5];
            data{2,2}=[131,32,33,532,33];
            %calculate
            flag = 2;
            mat2arff(data,flag,metricName,'correlationTraining.arff');
        else
            data{1,1}=[2.1,2.3,3,4,5];
            data{1,2}=[11,2,3,52,3];
            data{2,1}=[1.5,2.5,3.5,4.5,5.5];
            data{2,2}=[131,32,33,532,33];
            %calculate
            flag = 2;
            mat2arff(data,flag,metricName,'correlationTest.arff');
        end   
        
    end
    node = node.getNextSibling;
end

end