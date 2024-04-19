function [data, t] = comp_load_surf(filnam)
    % power spectrum reduced az data from surface expression
	%pavan vutukur 02/09/2023
if ~exist('filnam', 'var')
    [raw_name,temp,~]=uigetfile('*.*','Load Binary File');
    filnam=[temp raw_name];
end
fid = fopen(filnam,'r');
frewind(fid); % move back to beginning of file
if (fread(fid,[1,1],'uint16') == 65535)
    % display("Raw File flag present. Parsing rest of file");
        frewind(fid); % move back to beginning of file
end
        headval = fread(fid,[3,1],'uint32');
        % disp(headval)
%         dvals = fread(fid,[(pos2-32)/4,1],'float32');
t = datetime(...
    headval(3), 'ConvertFrom','posixtime', 'TicksPerSecond',1e3, ...
    'Format','dd-MMM-yyyy HH:mm:ss.SSS');
% try
    % dvals = fread(fid,[500,1],'uint16'); %read the next 128 bytes of uint16 data;
    dvals = fread(fid,'uint16'); %read the next 128 bytes of uint16 data;
% catch
    % dvals = fread(fid,[64,1],'uint16'); %read the next 128 bytes of uint16 data;
% end
data = dvals./50000; %psi scaling factor
frewind(fid); % move back to beginning of file

end
