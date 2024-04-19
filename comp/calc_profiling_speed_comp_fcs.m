function Vavg = calc_profiling_speed_comp_fcs(Vavg, head)
    % Calculate profiling speed in voltage units and add it to Vavg struct
    Delta_VP = diff(Vavg.P_end);

    if head.isUP
        Delta_VP = -Delta_VP;
    end

    Delta_VP = [Delta_VP(1); Delta_VP]; % Extrapolate backward for first value

    dt = 1/head.primary_sample_rate;
    Vavg.Wspd = Delta_VP/(head.Nseg*dt);
end
