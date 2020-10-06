function params = build_params(path_to_json)
fid = fopen(path_to_json, 'r');
json_content = fread(fid, inf, '*char');
params = jsondecode(json_content(:).');

if params.Modem.name == "PSK" && params.Modem.modulation_order == 4
    params.Modem.short_name = "QPSK";
elseif params.Modem.name == "PSK" && params.Modem.modulation_order == 2
    params.Modem.short_name = "BPSK";
else
    params.Modem.short_name = params.Modem.name;
end

params.Simulation.eb_n0_db = params.Simulation.eb_n0_db_min:params.Simulation.eb_n0_db_step:params.Simulation.eb_n0_db_max;

if ~isfield(params.Channel,'delay_in_samples')
    params.Channel.delay_in_samples = params.Channel.delay_in_secs * params.Waveform.sample_rate;
end

params.Frame.bits_per_frame = params.Frame.pkt_per_frm * params.Frame.pkt_oct_sz * 8;