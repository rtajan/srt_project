classdef rx_factory
    methods (Static, Access = public)
        function rx_filter = build_rx_filter(params)
            %% Construction du filtre adapté
            rx_filter   = comm.RaisedCosineReceiveFilter(...
                'FilterSpanInSymbols'  , params.Waveform.filter_span_in_symbols,...
                'RolloffFactor'        , params.Waveform.rolloff_factor,...
                'InputSamplesPerSymbol', params.Waveform.samples_per_symbol,...
                'DecimationFactor'     , params.Waveform.decimation_factor,...
                'DecimationOffset'     , params.Waveform.decimation_offset);
        end
        function demod_psk = build_demod_psk(params)
            %% Construction d'un démodulateur QPSK
            demod_psk = comm.PSKDemodulator(...
                'ModulationOrder', params.Modem.modulation_order, ...
                'PhaseOffset'    , params.Modem.phase_offset, ...
                'SymbolMapping'  , params.Modem.symbol_mapping,...
                'BitOutput'      , params.Modem.bit_output,...
                'DecisionMethod' , params.Modem.decision_method,...
                'Variance'       , params.Modem.variance);
        end
        function mac_sync = build_mac_sync(params)
            %% Construction d'un délai pour le calcul du TEB/TEP
            mac_sync = dsp.VariableIntegerDelay('MaximumDelay', params.Frame.bits_per_frame*2);
        end
        
        function bit2oct = build_bit_oct(params)
            %% Construction de la conversion octets -> bits
            bit2oct = Converter_bit_oct();
        end

        function sink = build_sink(params)
            %% Construction de la destination (écriture dans un fichier)
            sink = Sink_file('file_name', params.Sink.file_name);
        end
        
        function error_rate = build_error_rate(params)
            error_rate = comm.ErrorRate('ReceiveDelay', params.Frame.bits_per_frame,'ComputationDelay',params.Frame.bits_per_frame); % Calcul du nombre d'erreur et du BER
        end

        function decision = build_decision(params)
            decision = Decision();
        end        
    end
end