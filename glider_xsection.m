% create glider xsection plots from processed and grouped glider data for a
% specific time range

saveDir = ['/Users/lgarzio/Documents/RUCOOL/CONCORDE/glider_figs/'];
file = ['/Volumes/boardwalk/lgarzio/rucool/concorde/data/ru31-473_realtime_DbdGroup.mat'];

dateStart = datenum([2016,3,22,17,0,0]); % define date for data to start
dateEnd = datenum([2016,4,10,0,0,0]); % define date for data to end

SD = 3 % define standard deviations for outliers

% load the *.mat file with glider data that have already been processed and
% grouped via dbds2DbdGroup() from spt toolbox (https://github.com/kerfoot/spt)

load(file)
dgroup.sensors % list sensors
plotvars={'drv_sea_water_electrical_conductivity',
    'drv_sea_water_temperature',
    'drv_sea_water_salinity',
    'drv_sea_water_density',
    'sci_flbbcd_bb_units',
    'sci_flbbcd_cdom_units',
    'sci_flbbcd_chlor_units',
    'sci_oxy3835_wphase_oxygen',
    'sci_oxy3835_wphase_saturation',
    'drv_latitude',
    'drv_longitude'}

[data,vars]=toArray(dgroup,'sensors',plotvars);

time = data(:,1);
ind_time = find(time>dateStart&time<dateEnd);
depth = data(:,2);
t0 = min(time(ind_time))
t0str = datestr((t0), 'yyyy-mm-dd HH:MM')
t1 = max(time(ind_time))
t1str = datestr((t1), 'yyyy-mm-dd HH:MM')

% get water depth for plotting bathymetry
w_depth_data = toArray(dgroup,'sensors',{'drv_m_present_time_datenum','m_water_depth'});
% index where time is not nan and water depth is not nan or fill values (0)
ind_w_depth = find(~isnan(w_depth_data(:,3))&w_depth_data(:,3)>dateStart&w_depth_data(:,3)<dateEnd&w_depth_data(:,4)>0);
w_depth_data = w_depth_data(ind_w_depth,3:4); % redefine so matrix is only non-nan time and depth
% add bottom corners to polygon, 2m deeper than max water depth
w_depth_data=[w_depth_data; w_depth_data(end,1), max(w_depth_data(:,2))+2; w_depth_data(1,1), max(w_depth_data(:,2))+2];

for c=3:length(vars)
    n = vars{c}; % var name
    units = dgroup.sensorUnits.(n); % var units
    d = data(:,c); % data
    d(d==0)=NaN; % glider fill values (0) = NaN
    % index data within +/- SD standard deviations (SD defined by user)
    % and within time ranges
    avg = mean(d,'omitnan');
    stdev = std(d,'omitnan');
    ind_d = find(d>(avg - SD*stdev)...
        &d<(avg + SD*stdev)...
        &time>dateStart&time<dateEnd);
    figure;
    scatter(time(ind_d),-depth(ind_d),15,d(ind_d),'filled');
    hold on;
    fill(w_depth_data(:,1),-w_depth_data(:,2),'k'); % draw polygon for bathymetry
    set(gca,'xlim',[t0 t1]); % set x limits to data limits
    datetick('x','mm/dd','keepticks','keeplimits');
    ylabel('Depth');
    ylim([-round(max(depth)) 0]);
    colormap(jet)
    cbh=colorbar;
    ylabel(cbh,[n,' (',units,')'],'interpreter','none');
    grid on;
    tString = ['RU-31: ',t0str,' - ',t1str, ' GMT'];
    title(tString);
    set(gcf,'PaperPosition',[0 0 11 5.5]);
    print(gcf,[saveDir,'RU31_',n,'_',t0str(1:10),'_',t1str(1:10),'_outliers',num2str(SD),'SDrm'],'-dpng', '-r200');
    close
end

clear all
close all