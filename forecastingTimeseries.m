function forecastingTimeseries( file,obj )

xDoc = xmlread(file);
rootNode = xDoc.getDocumentElement.getChildNodes;
node = rootNode.getFirstChild;

while ~isempty(node)
    if strcmpi(node.getNodeName, 'metric')
        returnedMetric = node.getAttribute('returnedMetric');
        subNode = node.getFirstChild;
        while ~isempty(subNode)
            if strcmpi(subNode.getNodeName, 'target')
                metric = strsplit(char(subNode.getTextContent),',');
                
                % data = ?
            end
            if strcmpi(subNode.getNodeName, 'method')
                methodName = char(subNode.getAttribute('name'));
                second_node = subNode.getFirstChild;
                while ~isempty(second_node)
                    if strcmpi(second_node.getNodeName, 'parameters')
                        if strcmpi(methodName,'AR')
                            m = str2double(second_node.getAttribute('order'));
                            K = str2double(second_node.getAttribute('forecastPeriod'));
                        elseif strcmpi(methodName,'ARMA')
                            p = str2double(second_node.getAttribute('autoregressive'));
                            q = str2double(second_node.getAttribute('movingAverage'));
                            K = str2double(second_node.getAttribute('forecastPeriod'));
                        elseif strcmpi(methodName,'ARIMA')
                            p = str2double(second_node.getAttribute('autoregressive'));
                            d = str2double(second_node.getAttribute('integrated'));
                            q = str2double(second_node.getAttribute('movingAverage'));
                            K = str2double(second_node.getAttribute('forecastPeriod'));
                        end
                    end
                    second_node = second_node.getNextSibling;
                end
            end
            subNode = subNode.getNextSibling;
        end
        
%         interval = mean(diff(timestamps))/1000;
%         K = ceil(K/interval);
        
        %len = length(data);
        %data = data(len-dataUsed+1:len);
        switch(methodName)
            case 'AR'
                %% Forecast linear system response into future
                data_id = iddata(data',[]);
                sys = ar(data_id,m);
                p = forecast(sys,data_id,K);
                values = p;
                
            case 'ARMA'
                if isnan(p) || isnan(q)
                    LOGL = zeros(4,4); %Initialize
                    PQ = zeros(4,4);
                    for p = 1:4
                        for q = 1:4
                            mod = arima(p,0,q);
                            [fit,~,logL] = estimate(mod,data','print',false);
                            LOGL(p,q) = logL;
                            PQ(p,q) = p+q;
                        end
                    end
                    
                    LOGL = reshape(LOGL,16,1);
                    PQ = reshape(PQ,16,1);
                    [~,bic] = aicbic(LOGL,PQ+1,100);
                    bic = reshape(bic,4,4);
                    
                    [p,q] = find(bic==min(min(bic)));
                end
                
                Mdl = arima(p,0,q);
                
                if iscolumn(data)
                    EstMdl = estimate(Mdl,data);
                    [YF YMSE] = forecast(EstMdl,K,'Y0',data);
                else
                    EstMdl = estimate(Mdl,data');
                    [YF YMSE] = forecast(EstMdl,K,'Y0',data');
                end
                
                
                values = YF;
                
            case 'ARIMA'
                %% Forecast ARIMA or ARIMAX process
                if isnan(p) || isnan(q) || isnan(d)
                    LOGL = zeros(4,3,4); %Initialize
                    PQ = zeros(4,3,4);
                    for p = 1:4
                        for q = 1:4
                            for d = 0:2
                                mod = arima(p,d,q);
                                [fit,~,logL] = estimate(mod,data','print',false);
                                LOGL(p,d+1,q) = logL;
                                PQ(p,d+1,q) = p+q;
                            end
                        end
                    end
                    
                    LOGL = reshape(LOGL,48,1);
                    PQ = reshape(PQ,48,1);
                    [~,bic] = aicbic(LOGL,PQ+1,100);
                    bic = reshape(bic,4,3,4);
                    
                    [temp I] = min(bic,[],3);
                    [p,d] = find(temp==min(min(temp)));
                    q = I(p,d);
                    d = d-1;
                end
                
                Mdl = arima(p,d,q);
                
                if iscolumn(data)
                    EstMdl = estimate(Mdl,data);
                    [YF YMSE] = forecast(EstMdl,K,'Y0',data);
                else
                    EstMdl = estimate(Mdl,data');
                    [YF YMSE] = forecast(EstMdl,K,'Y0',data');
                end
                
                values = YF;
                
                %send back the data
        end
    end
    node = node.getNextSibling;
end


end