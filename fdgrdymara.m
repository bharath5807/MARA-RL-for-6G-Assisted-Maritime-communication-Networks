clc;
clear;
close all;

%% =========================================================
% MARA-SYS : Maritime Resource Allocation
% 6G Maritime Satellite Communication System
%
% COMPARISON METHODS:
% 1. Static FDMA
% 2. Greedy SINR
% 3. Proposed MARA-RL
%
% PERFORMANCE METRICS:
% Throughput
% Energy Consumption
% Spectral Efficiency
%
% CHANNEL MODEL:
% Rician Maritime Fading Channel
%% =========================================================

%% =========================
% SYSTEM PARAMETERS
%% =========================

Iterations      = 200;
N_vessels       = 20;
K_subchannels   = 48;

Bandwidth       = 10e3;      % 10 KHz
NoisePower      = 1e-10;

TTI             = 0.05;      % 50 ms

Pmax_dBm        = 30;
Pmax            = 10^((Pmax_dBm-30)/10);

SeaState        = 4;

%% =========================
% RICIAN FACTOR
%% =========================

K_dB = 2.1 - 0.3*SeaState;
K = 10^(K_dB/10);

%% =========================
% RL PARAMETERS
%% =========================

alpha   = 0.1;
gamma   = 0.95;
epsilon = 0.2;

Q_table = zeros(N_vessels,2);

%% =========================
% STORAGE VARIABLES
%% =========================

%% STATIC FDMA

Thr_FDMA      = zeros(1,Iterations);
Energy_FDMA   = zeros(1,Iterations);
SE_FDMA       = zeros(1,Iterations);

%% GREEDY SINR

Thr_Greedy    = zeros(1,Iterations);
Energy_Greedy = zeros(1,Iterations);
SE_Greedy     = zeros(1,Iterations);

%% PROPOSED RL

Thr_RL        = zeros(1,Iterations);
Energy_RL     = zeros(1,Iterations);
SE_RL         = zeros(1,Iterations);

%% =========================================================
% MAIN SIMULATION LOOP
%% =========================================================

for t = 1:Iterations
    
    %% =====================================================
    % STATIC FDMA
    %% =====================================================
    
    total_rate_fdma = 0;
    total_energy_fdma = 0;
    total_se_fdma = 0;
    
    for i = 1:N_vessels
        
        %% Rician Channel
        
        LOS = sqrt(K/(K+1));
        
        NLOS = sqrt(1/(2*(K+1))) * ...
              (randn(1,K_subchannels) + ...
               1i*randn(1,K_subchannels));
        
        h = LOS + NLOS;
        
        gain = abs(h).^2;
        
        %% Equal Power Allocation
        
        P_tx = (Pmax/K_subchannels) * ...
               ones(1,K_subchannels);
        
        %% SINR
        
        SINR = (P_tx .* gain) ./ NoisePower;
        
        %% Shannon Capacity
        
        Rate = Bandwidth * log2(1 + SINR);
        
        %% Total Throughput
        
        total_rate_fdma = total_rate_fdma + ...
                          sum(Rate);
        
        %% Energy
        
        total_energy_fdma = total_energy_fdma + ...
                            sum(P_tx)*TTI;
        
        %% Spectral Efficiency
        
        total_se_fdma = total_se_fdma + ...
                        mean(log2(1 + SINR));
        
    end
    
    Thr_FDMA(t)    = total_rate_fdma/1e6;
    Energy_FDMA(t) = total_energy_fdma;
    SE_FDMA(t)     = total_se_fdma/N_vessels;
    
    %% =====================================================
    % GREEDY SINR
    %% =====================================================
    
    total_rate_greedy = 0;
    total_energy_greedy = 0;
    total_se_greedy = 0;
    
    for i = 1:N_vessels
        
        %% Rician Channel
        
        LOS = sqrt(K/(K+1));
        
        NLOS = sqrt(1/(2*(K+1))) * ...
              (randn(1,K_subchannels) + ...
               1i*randn(1,K_subchannels));
        
        h = LOS + NLOS;
        
        gain = abs(h).^2;
        
        %% Greedy SINR Allocation
        
        if mean(gain) > 1
            
            P_tx = 1.2*(Pmax/K_subchannels) * ...
                   ones(1,K_subchannels);
               
        else
            
            P_tx = 0.5*(Pmax/K_subchannels) * ...
                   ones(1,K_subchannels);
               
        end
        
        %% SINR
        
        SINR = (P_tx .* gain) ./ NoisePower;
        
        %% Rate
        
        Rate = Bandwidth * log2(1 + SINR);
        
        %% Throughput
        
        total_rate_greedy = total_rate_greedy + ...
                            sum(Rate);
        
        %% Energy
        
        total_energy_greedy = total_energy_greedy + ...
                              sum(P_tx)*TTI;
        
        %% Spectral Efficiency
        
        total_se_greedy = total_se_greedy + ...
                          mean(log2(1 + SINR));
        
    end
    
    Thr_Greedy(t)    = total_rate_greedy/1e6;
    Energy_Greedy(t) = total_energy_greedy;
    SE_Greedy(t)     = total_se_greedy/N_vessels;
    
    %% =====================================================
    % PROPOSED MARA-RL
    %% =====================================================
    
    total_rate_rl = 0;
    total_energy_rl = 0;
    total_se_rl = 0;
    
    for i = 1:N_vessels
        
        %% Rician Channel
        
        LOS = sqrt(K/(K+1));
        
        NLOS = sqrt(1/(2*(K+1))) * ...
              (randn(1,K_subchannels) + ...
               1i*randn(1,K_subchannels));
        
        h = LOS + NLOS;
        
        gain = abs(h).^2;
        
        %% RL ACTION
        
        if rand < epsilon
            
            action = randi([1 2]);
            
        else
            
            [~,action] = max(Q_table(i,:));
            
        end
        
        %% RL Adaptive Power Allocation
        
        if action == 1
            
            P_tx = 0.4*(Pmax/K_subchannels) * ...
                   ones(1,K_subchannels);
               
        else
            
            P_tx = 1.0*(Pmax/K_subchannels) * ...
                   ones(1,K_subchannels);
               
        end
        
        %% SINR
        
        SINR = (P_tx .* gain) ./ NoisePower;
        
        %% Rate
        
        Rate = Bandwidth * log2(1 + SINR);
        
        vessel_rate = sum(Rate);
        
        %% Energy
        
        energy = sum(P_tx)*TTI;
        
        %% RL Reward Function
        
        reward = 0.6*(vessel_rate/1e6) ...
               - 0.3*energy ...
               + 0.2*mean(log2(1 + SINR));
        
        %% Q-Learning Update
        
        oldQ = Q_table(i,action);
        
        nextMax = max(Q_table(i,:));
        
        Q_table(i,action) = oldQ + ...
            alpha*(reward + gamma*nextMax - oldQ);
        
        %% Update Totals
        
        total_rate_rl = total_rate_rl + ...
                        vessel_rate;
        
        total_energy_rl = total_energy_rl + ...
                          energy;
        
        total_se_rl = total_se_rl + ...
                      mean(log2(1 + SINR));
        
    end
    
    Thr_RL(t)    = total_rate_rl/1e6;
    Energy_RL(t) = total_energy_rl;
    SE_RL(t)     = total_se_rl/N_vessels;
    
    %% Epsilon Decay
    
    epsilon = max(0.01, epsilon*0.995);
    
end

%% =========================================================
% SMOOTHING
%% =========================================================

window = 8;

Thr_FDMA   = movmean(Thr_FDMA,window);
Thr_Greedy = movmean(Thr_Greedy,window);
Thr_RL     = movmean(Thr_RL,window);

%% =========================================================
% PLOTS
%% =========================================================

%% THROUGHPUT

figure;
plot(Thr_FDMA,'k','LineWidth',2);
hold on;
plot(Thr_Greedy,'b','LineWidth',2);
plot(Thr_RL,'r','LineWidth',3);

xlabel('Iterations');
ylabel('Throughput (Mbps)');
title('Throughput Comparison');

legend('Static FDMA',...
       'Greedy SINR',...
       'Proposed MARA-RL');

grid on;

%% ENERGY CONSUMPTION

figure;
plot(Energy_FDMA,'k','LineWidth',2);
hold on;
plot(Energy_Greedy,'b','LineWidth',2);
plot(Energy_RL,'r','LineWidth',3);

xlabel('Iterations');
ylabel('Energy Consumption (J)');
title('Energy Consumption Comparison');

legend('Static FDMA',...
       'Greedy SINR',...
       'Proposed MARA-RL');

grid on;

%% SPECTRAL EFFICIENCY

figure;
plot(SE_FDMA,'k','LineWidth',2);
hold on;
plot(SE_Greedy,'b','LineWidth',2);
plot(SE_RL,'r','LineWidth',3);

xlabel('Iterations');
ylabel('Spectral Efficiency (bits/s/Hz)');
title('Rician Fading Channel Spectral Efficiency');

legend('Static FDMA',...
       'Greedy SINR',...
       'Proposed MARA-RL');

grid on;

%% =========================================================
% RESULTS DISPLAY
%% =========================================================

fprintf('\n===========================================\n');
fprintf('AVERAGE PERFORMANCE RESULTS\n');
fprintf('===========================================\n');

%% FDMA

fprintf('\n1. STATIC FDMA\n');

fprintf('Average Throughput      : %.2f Mbps\n',...
        mean(Thr_FDMA));

fprintf('Average Energy          : %.2f J\n',...
        mean(Energy_FDMA));

fprintf('Average Spectral Eff.   : %.2f bits/s/Hz\n',...
        mean(SE_FDMA));

%% GREEDY

fprintf('\n2. GREEDY SINR\n');

fprintf('Average Throughput      : %.2f Mbps\n',...
        mean(Thr_Greedy));

fprintf('Average Energy          : %.2f J\n',...
        mean(Energy_Greedy));

fprintf('Average Spectral Eff.   : %.2f bits/s/Hz\n',...
        mean(SE_Greedy));

%% RL

fprintf('\n3. PROPOSED MARA-RL\n');

fprintf('Average Throughput      : %.2f Mbps\n',...
        mean(Thr_RL));

fprintf('Average Energy          : %.2f J\n',...
        mean(Energy_RL));

fprintf('Average Spectral Eff.   : %.2f bits/s/Hz\n',...
        mean(SE_RL));

fprintf('\n===========================================\n');

%% =========================================================
% IMPROVEMENT ANALYSIS
%% =========================================================

imp_fdma = ((mean(Thr_RL)-mean(Thr_FDMA))...
           /mean(Thr_FDMA))*100;

imp_greedy = ((mean(Thr_RL)-mean(Thr_Greedy))...
             /mean(Thr_Greedy))*100;

fprintf('\nTHROUGHPUT IMPROVEMENT OVER FDMA   : %.2f %%\n',...
         imp_fdma);

fprintf('THROUGHPUT IMPROVEMENT OVER GREEDY : %.2f %%\n',...
         imp_greedy);

fprintf('\nSimulation Completed Successfully.\n');