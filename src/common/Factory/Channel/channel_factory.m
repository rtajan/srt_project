classdef channel_factory
    methods (Static, Access = public)
        function awgn_channel = build_awgn_channel(params)
            awgn_channel = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (Es/No)',...
                                            'SignalPower', params.Channel.gain^2);
        end
        function doppler = build_doppler(params)
            doppler = comm.PhaseFrequencyOffset(...
            'FrequencyOffset',params.Channel.frequency_offset,...
            'PhaseOffset',    params.Channel.phase_offset,...
            'SampleRate',     params.Waveform.sample_rate);
        end
        function delay = build_delay(params)
            delay = dsp.VariableFractionalDelay();
        end
    end
end