function [data,head] = comp_load_solo2(filnam)
%com_load_solo loads a compressed data file which has been uploaded from ChiSolo
%   The ChiSolo cmpressed data files
% 



if ~exist('filnam', 'var')
    [raw_name,temp,~]=uigetfile('*.*','Load Binary File');
    filnam=[temp raw_name];
end


% [raw_name,temp,filterindex]=uigetfile('*.*','Load Binary File');
% filnam=[temp raw_name];

fid = fopen(filnam,'r');
% first get the number of bytes in file
fseek(fid,0,'eof'); % move to end of file
pos2 = ftell(fid); % pos2 is overall length of file
frewind(fid); % move back to beginning of file
nrecs = (pos2-32)/16;

fread(fid,[1,1],'uint32');
frewind(fid)

if (fread(fid,[1,1],'uint32') == (2^32-1))
        frewind(fid); % move back to beginning of file
        headval = fread(fid,[8,1],'uint32');
        dvals = fread(fid,[(pos2-32),1],'uint8');
end

fprintf('%8.8G 5-second records in the file\n',nrecs);
tbase = double(datenum(1970,1,1));

% % % % typedef struct{
% % % %         //uint32_t  unixSeconds;
% % % % 		uint8_t	      ticks,   //counter from 0 to 255 to end with DIVE_PACKET
% % % % 				  WspdMin,
% % % %                   psiS1Fit1,
% % % %                   psiS1Fit2,
% % % %                   psiS2Fit1,
% % % %                   psiS2Fit2,
% % % %                   psiT1pFit1,
% % % %                   psiT1pFit2,
% % % %                   psiT2pFit1,
% % % %                   psiT2pFit2;
% % % % 		uint16_t      t1Mean,
% % % %                   t2Mean,
% % % % 				          pEnd;
% % % % }reducedDataSOLO;
% % % % //128 bits or 16 bytes of reduced data packet		

data.ticks = dvals(1:16:end);
data.WspdMin = dvals(2:16:end)/16000;
data.psiS1Fit1 = 10.^((dvals(3:16:end)-256)/16);   
data.psiS1Fit2 = 10.^((dvals(4:16:end)-256)/16);
data.psiS2Fit1 = 10.^((dvals(5:16:end)-256)/16);
data.psiS2Fit2 = 10.^((dvals(6:16:end)-256)/16);
data.psiT1pFit1 = 10.^((dvals(7:16:end)-256)/16);
data.psiT1pFit2 = 10.^((dvals(8:16:end)-256)/16);
data.psiT2pFit1 = 10.^((dvals(9:16:end)-256)/16);
data.psiT2pFit2 = 10.^((dvals(10:16:end)-256)/16);
data.T1Mean = (dvals(11:16:end) + 2^8.*(dvals(12:16:end)))*6.2500e-05;
data.T2Mean = (dvals(13:16:end) + 2^8.*(dvals(14:16:end)))*6.2500e-05;
data.pEnd = (dvals(15:16:end) + 2^8.*(dvals(16:16:end)))*6.2500e-05;

headval(2)
tv = headval(2)  + data.ticks*512./100.0; % seconds since base
 %   data.daytime(i) = mod( data.THi(i) * 65536.0 + data.TLo(i), 86400) +  data.tick(i)/100.0;
tv = tv./86400.0;  % matlab keeps time in days
tv = tv + tbase;
data.time = tv;

head.starttime = datetime(headval(2), 'ConvertFrom','posixtime','TicksPerSecond',1e3,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
% head.endtime = datetime(headval(4), 'ConvertFrom','posixtime','TicksPerSecond',1e3,'Format','dd-MMM-yyyy HH:mm:ss.SSS');


fclose(fid);
end
