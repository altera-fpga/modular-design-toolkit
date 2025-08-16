%##################################################################################
% Copyright (C) 2025 Altera Corporation
%
% This software and the related documents are Altera copyrighted materials, and
% your use of them is governed by the express license under which they were
% provided to you ("License"). Unless the License provides otherwise, you may
% not use, modify, copy, publish, distribute, disclose or transmit this software
% or the related documents without Altera's prior written permission.
%
% This software and the related documents are provided as is, with no express
% or implied warranties, other than those that are expressly stated in the License.
%##################################################################################

function dsp_builder_build_model(modelDir, modelName, family, speedGrade, outdir)

    t = [datetime('now')];
    datetime_string = datestr(t);

    fprintf('===========================================================\n')
    fprintf('Running DSP Builder, Build Model Script\n')
    fprintf('Date/Time        : %s\n',datetime_string)
    fprintf('Model Name       : %s\n', modelName)
    fprintf('Model Directory  : %s\n', modelDir)
    fprintf('Device Family    : %s\n', family)
    fprintf('Output Directory : %s\n', outdir)
    fprintf('Speed Grade      : %s\n', speedGrade)
    fprintf('===========================================================\n\n')

    try
        cd(modelDir);
        load_model_set_device_set_rtl_dir(modelName, family, speedGrade, outdir);
        sim(modelName);
    catch ME
        disp(['ID: ' ME.identifier]);
    end

    try
        save_system
    catch ME
        disp(['ID: ' ME.identifier]);
        bdclose('all')
    end

end

function load_model_set_device_set_rtl_dir(modelName, family, speedGrade, outdir)

    narginchk(4, 4)

    load_system(modelName);

    if ~isempty(family)

        % Find all device blocks and set family
        DeviceBlks = find_system(modelName,'FollowLinks','on','MaskType', 'DSP Builder Advanced Blockset Device Block');
        for i = 1:numel(DeviceBlks)
            dspba.set_param(DeviceBlks{i},'family', family);
            dspba.set_param(DeviceBlks{i},'device', 'AUTO');
            dspba.set_param(DeviceBlks{i},'speed', speedGrade);
        end
    end

    if ~isempty(outdir)
        dspba.SetRTLDestDir(modelName, outdir);
    end

end
