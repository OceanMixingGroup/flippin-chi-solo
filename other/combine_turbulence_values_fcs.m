function out = combine_turbulence_values_fcs(in1, in2)
% function out = combine_turbulence_values_fcs(in1, in2)
% Combine the two values of epsilon from each shear probe or chi from each thermistor
%
%   Input
%   -----
%   in1, in2: equal-sized arrays (1D or 2D) of epsilon or chi values
%
%   Output
%   ------
%   comb: mean of the two values, or smallest if they differ by more than factor of 10
%
%   Ken Hughes, July 2021

    assert(isequal(size(in1), size(in2)), 'Inputs must be same size')
    assert(ndims(in1) <= 2, 'Inputs must be one- or two-dimensional')

    in = cat(3, in1, in2);
    out = mean(in, 3);

    idx = in1 > 10*in2 | in2 > 10*in1;
    out(idx) = min(in1(idx), in2(idx));

end
