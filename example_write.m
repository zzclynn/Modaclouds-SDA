% example_write.m
%
% Authors:
%   Valerio De Carolis          <valerio.decarolis@gmail.com>

clear all; close all; clc;

%% create data structure
data = struct();
relname = sprintf('dataset_%s', datestr(now,'yyyymmdd'));
outfile = sprintf('%s.arff', relname);

% nominal classes
type_class = { 'front', 'middle', 'rear' };

%% populate dataset
for i = 1 : 100
    data(i).idx = i;
    data(i).low = randi([0 33], 1);
    data(i).med = randi([34 66], 1);
    data(i).high = randi([67 100], 1);
    data(i).type_class = type_class{ randi([1 3]) };
end

%% declare nominal specification attributes
nomspec.type_class = type_class;

% save arff
arff_write(outfile, data, relname, nomspec);
