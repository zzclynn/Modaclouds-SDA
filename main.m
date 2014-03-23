%% main function, requires the configuration file as input
clc
clear
file = 'configuration_SDA.xml';
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

xDoc = xmlread(file);
rootNode = xDoc.getDocumentElement.getChildNodes;
node = rootNode.getFirstChild;

while ~isempty(node)
    if strcmpi(node.getNodeName, 'forecastingTimeSeries')
        forecastingTSConFile = node.getAttribute('configurationFile');
        period(1) = str2double(node.getAttribute('period'));
    end
    if strcmpi(node.getNodeName, 'forecastingML')
        forecastingMLConFile = node.getAttribute('configurationFile');
        period(2) = str2double(node.getAttribute('period'));
    end
    if strcmpi(node.getNodeName, 'estimation')
        estimationConFile = node.getAttribute('configurationFile');
        period(3) = str2double(node.getAttribute('period'));
    end
    if strcmpi(node.getNodeName, 'correlation')
        correlationConFile = node.getAttribute('configurationFile');
        period(4) = str2double(node.getAttribute('period'));
        period(5) = str2double(node.getAttribute('trainingPeriod'));
    end
    node = node.getNextSibling;
end

nextPauseTime = period;

while 1
    [pauseTime, index] = min(nextPauseTime);
    nextPauseTime = nextPauseTime - pauseTime;
    pause(pauseTime/1000)
    
    switch index
        case 1
            forecastingTimeseries( forecastingTSConFile,obj );
        case 2
            forecastingMLConFile( file,obj );
        case 3
            estimationConFile( file,obj );
        case 4
            correlation( correlationConFile,0,obj );
        case 5
            correlation( correlationConFile,1,obj );
            period(5) = [];
            continue;
    end
    
    nextPauseTime(index) = period(index);
end

