classdef tx_factory
    methods (Static, Access = public)
        function source = build_source(params)
            %% Construction de la source
            if strcmp(params.Source.type, 'random')
                source = Source_random('samples_per_frame', params.Frame.pkt_oct_sz*params.Frame.pkt_per_frm, ...
                                       'data_type'        , params.Source.data_type);
            elseif strcmp(params.Source.type, 'file')
                
                source = Source_file(...
                    'file_name'        , params.Source.file_name, ...
                    'samples_per_frame', params.Frame.pkt_oct_sz*params.Frame.pkt_per_frm,...
                    'data_type'        , params.Source.data_type);
            end
        end


        function scrambler = build_scrambling_sequence(params)
            %% Construction du Scrambler 
            bits_per_frame = params.Frame.pkt_oct_sz*params.Frame.pkt_per_frm*8;
            bits_per_pkt   = params.Frame.pkt_oct_sz*8;

            scrambler  = comm.Scrambler(...
                'CalculationBase'  , params.Scrambler.calculation_base,...
                'Polynomial'       , params.Scrambler.polynomial,...
                'InitialConditions', params.Scrambler.initial_conditions(:).');

            scramble_sequence = scrambler(zeros(bits_per_frame-8,1));
            scrambler_enable  = ones(size(scramble_sequence));

            for i_pckt = 0:6
                scrambler_enable((bits_per_pkt-8) + i_pckt*bits_per_pkt + (1:8)) = 0;
            end
            dvb_scramble_bit = scramble_sequence & scrambler_enable;
            dvb_scr_seq = uint8([255; bi2de(reshape(dvb_scramble_bit,8,[])','left-msb')]);

            scrambler = Scrambler('sequence', dvb_scr_seq);
        end

        function modulator = build_modulator(params)
            %%  Construction du modulateur
            modulator = comm.PSKModulator(...
                'ModulationOrder', params.Modem.modulation_order, ...
                'PhaseOffset'    , params.Modem.phase_offset, ...
                'SymbolMapping'  , params.Modem.symbol_mapping,...
                'BitInput'       , params.Modem.bit_input);
        end


        function shp_filter = build_shaping_filter(params)
            %% Construction du filtre de mise en forme
            shp_filter = comm.RaisedCosineTransmitFilter(...
                'FilterSpanInSymbols'   , params.Waveform.filter_span_in_symbols,...
                'RolloffFactor'         , params.Waveform.rolloff_factor,...
                'OutputSamplesPerSymbol', params.Waveform.samples_per_symbol);
        end

        function cc_enc = build_concolutional_encoder(params)
            %% Construction de l'encodeur du code convolutif
            cc_treillis = poly2trellis(params.Convolutional_codec.Encoder.constraint_length, ...
                                       params.Convolutional_codec.Encoder.code_generator(:).'); % Definition du treillis

            cc_enc = comm.ConvolutionalEncoder(...
                'TrellisStructure', cc_treillis,...
                'TerminationMethod', params.Convolutional_codec.Decoder.termination_method);
        end


        function rs_enc = build_rs_encoder(params)
            %% Construction de l'encodeur du code RS
            rs_enc = comm.RSEncoder(...
                'ShortMessageLength', params.Frame.pkt_oct_sz, ...
                'CodewordLength'    , params.RS_codec.codeword_length, ...
                'MessageLength'     , params.RS_codec.message_length, ...
                'BitInput'          , params.RS_codec.bit_input);
        end

        %% Construction de l'entrelaceur
        function itl = build_interleaver(params)
            itl = comm.ConvolutionalInterleaver(...
                'NumRegisters' , params.Convolutional_interleaver.num_registers, ...
                'RegisterLengthStep', params.Convolutional_interleaver.register_length_step);
        end
        
        function oct2bit = build_octet_to_binary(params)
            %% Construction de la conversion octets -> bits
            oct2bit = Converter_oct_bit();
        end

    end
end