out_name = 'my_map.nii';
out_header = spm_vol('/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_2017062801/Func/avg_func_ref/bold_avg_mcf_brain.nii');
% image_data = spm_read_vols(out_header);
out_header.dt = [16 0]; % sets it to float output
out_header.fname = out_name;
image_data='/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_2017062801/mvpa_analysis/mask_heatmap.mat';
load(image_data)
spm_write_vol(out_header, full_data);