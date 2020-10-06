clear
clearpath
close all
clc

addpath(genpath('data'));
addpath(genpath('src'));
addpath(genpath('.app'));

params = build_params('params.json'); % Builds the params structure from the JSON file

%%
% Modules TX
source        = tx_factory.build_source               (params); % Builds the source
scrambler     = tx_factory.build_scrambling_sequence  (params); % Builds the scrambling sequence
oct2bit       = tx_factory.build_octet_to_binary      (params); % Builds a tool for converting octets to bin
mod_psk       = tx_factory.build_modulator            (params); % Builds the QPSK modulator
shp_filter    = tx_factory.build_shaping_filter       (params); % Builds the shaping filter

% Modules canal
awgn_channel  = channel_factory.build_awgn_channel    (params); % Builds AWGN channel
doppler       = channel_factory.build_doppler         (params); % Builds Doppler module
delay         = channel_factory.build_delay           (params); % Builds Doppler module

% Modules RX
rx_filter     = rx_factory.build_rx_filter            (params); % Builds matched filter
demod_psk     = rx_factory.build_demod_psk            (params); % Builds QPSK demodulator
decision      = rx_factory.build_decision             (params); % Builds decision
mac_sync      = rx_factory.build_mac_sync             (params); % Builds a delay for correct BER/FER computation
bit2oct       = rx_factory.build_bit_oct              (params);
stat_erreur   = rx_factory.build_error_rate           (params);
%%
ber = zeros(1,length(params.Simulation.eb_n0_db));
Pe = qfunc(sqrt(2*10.^(params.Simulation.eb_n0_db/10)));
tx_rx_flt_delay = params.Frame.bits_per_frame - params.Waveform.filter_span_in_symbols * log2(params.Modem.modulation_order);

%% Preparation de l'affichage
figure(1)
semilogy(params.Simulation.eb_n0_db,Pe);
hold all
h_ber = semilogy(params.Simulation.eb_n0_db,ber,'XDataSource','params.Simulation.eb_n0_db', 'YDataSource','ber');
ylim([1e-6 1])
grid on
xlabel('$\frac{E_b}{N_0}$ en dB','Interpreter', 'latex', 'FontSize',14)
ylabel('$P_b$, TEB','Interpreter', 'latex', 'FontSize',14)
legend({'$P_b$ (Th\''eorique)', 'TEB (Exp\''erimental)'}, 'Interpreter', 'latex', 'FontSize',14);

msg_format = '|   %7.2f  |   %9d |  %7d | %2.2e |  %8.2f kO/s |   %8.2f kO/s |\n';

fprintf(      '|------------|-------------|----------|----------|----------------|-----------------|\n')
msg_header =  '|  Eb/N0 dB  |   Bit nbr   |  Bit err |   TEB    |    Debit Tx    |     Debit Rx    |\n';
fprintf(msg_header);
fprintf(      '|------------|-------------|----------|----------|----------------|-----------------|\n')

%% Calcul du TEB
for i_snr = 1:length(params.Simulation.eb_n0_db)
    reverseStr = ''; % Pour affichage en console
    
    stat_erreur.reset; % reset du compteur d'erreur
    err_stat = [0 0 0];
    T_rx = 0;
    T_tx = 0;
    source.reset;
    while (err_stat(2) < 100 && err_stat(3) < 1e7)
        source.reset;
        while(~source.isDone)
            %% Emetteur
            loc_T_tx    = tic;
            tx_oct      = step(source); % Lire une trame
            tx_oct(1:188:end) = 71;
            
            tx_scr_oct  = step  (scrambler,     tx_oct     ); % scrambler
            tx_scr_bit  = step  (oct2bit,       tx_scr_oct ); % Octets -> Bits
            tx_sym      = step  (mod_psk,       tx_scr_bit ); % Modulation QPSK
            tx_sps      = step  (shp_filter,    tx_sym     ); % Filtrage de mise en forme
            T_tx        = T_tx + toc(loc_T_tx);
            %% Channel
            Rcm = length(tx_oct(:)) * 8 / length(tx_sym);                % Rendement de la modulation codée
            es_n0_db = params.Simulation.eb_n0_db(i_snr) + 10*log10(Rcm);
            awgn_channel.EsNo = es_n0_db;                                % Mise a jour du EbN0 pour le canal
            
            tx_sps_dpl  = step(doppler, tx_sps                                     ); % Simulation d'un effet Doppler
            tx_sps_del  = step(delay,   tx_sps_dpl, params.Channel.delay_in_samples); % Ajout d'un retard de propagation
            rx_sps      = step(awgn_channel, params.Channel.gain * tx_sps_del      ); % Ajout d'un bruit gaussien
            
            %% Recepteur
            loc_T_rx    = tic;
            rx_sym      = step(rx_filter, rx_sps                     ); % Filtrage adapté QPSK
            rx_scr_llr  = step(demod_psk, rx_sym                     ); % Démodulation QPSK
            rx_scr_bit  = step(decision,  rx_scr_llr                 ); % Décision
            rx_scr_sync = step(mac_sync,  rx_scr_bit, tx_rx_flt_delay); % synchronisation couche acces.
            rx_scr_oct  = step(bit2oct,   rx_scr_sync                ); % Conversion en octet pour le scrambler
            rx_oct      = step(scrambler, rx_scr_oct                 ); % descrambler
            T_rx        = T_rx + toc(loc_T_rx);
            
            %% Calcul du TEB
            tx_bit     = step(oct2bit,tx_oct);
            rx_bit     = step(oct2bit,rx_oct);
            err_stat   = step(stat_erreur, tx_bit, rx_bit);
        end
        %% Affichage
        msg = sprintf(msg_format,params.Simulation.eb_n0_db(i_snr), err_stat(3), err_stat(2), err_stat(1), err_stat(3)/8192/T_tx, err_stat(3)/8192/T_rx);
        fprintf(reverseStr);
        msg_sz =  fprintf(msg);
        reverseStr = repmat(sprintf('\b'), 1, msg_sz);
    end
    if err_stat(2) == 0
        break
    end
    ber(i_snr) = err_stat(1);
    refreshdata(h_ber);
    drawnow limitrate
end
fprintf(      '|------------|-------------|----------|----------|----------------|-----------------|\n')
