function varargout=ea_coregctmri_brainsfit(options)
% This function uses the BRAINSfit to register postop-CT to preop-MR.
% __________________________________________________________________________________
% Copyright (C) 2015 Charite University Medicine Berlin, Movement Disorders Unit
% Andreas Horn

if ischar(options) % return name of method.
    varargout{1}='BRAINSFit (recommended)';
    varargout{2}={'SPM8','SPM12'};
    varargout{3}=['nan']; % suggestion for alpha-parameter.
    return
end


ea_brainsfit([options.root,options.patientname,filesep,options.prefs.prenii_unnormalized],...
          [options.root,options.patientname,filesep,options.prefs.rawctnii_unnormalized],...
          [options.root,options.patientname,filesep,options.prefs.ctnii_coregistered])

