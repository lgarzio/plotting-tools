#! /usr/local/bin/python

"""
Created on Wed Aug 23 2017

@author: lgarzio
"""

import xarray as xr
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as ticker
import os
import numpy as np
import re
import datetime

'''
This script is used to generate timeseries plots of met buoy data from netCDF files for the CONCORDE project,
between a time range specified by the user.
'''

def createDir(newDir):
    # Check if dir exists.. if it doesn't... create it. From Mike S
    if not os.path.isdir(newDir):
        try:
            os.makedirs(newDir)
        except OSError:
            if os.path.exists(newDir):
                pass
            else:
                raise

def plot_timeseries(t, y, ymin, ymax, args):

    yD = y.data.flatten()

    fig, ax = plt.subplots()
    plt.grid()
    plt.margins(y=.1, x=.1)
    plt.plot(t, yD, c='b', marker='.', lw = .75)

    # Format date axis
    df = mdates.DateFormatter('%Y-%m-%d')
    ax.xaxis.set_major_formatter(df)
    fig.autofmt_xdate()

    # Format y-axis to disable offset
    y_formatter = ticker.ScalarFormatter(useOffset=False)
    ax.yaxis.set_major_formatter(y_formatter)

    # Labels
    ax.set_ylabel(args[1] + " ("+ y.units + ")", fontsize=10)
    ax.set_title(args[0] + " " + str(args[3])[0:19] + " to " + str(args[4])[0:19], fontsize=10)
    ax.legend(["Max: %f" % ymax + "\nMin: %f" % ymin], loc='best', fontsize=8)

    filename = args[0] + "_" + args[1] + "_" + str(args[3])[0:10] + "_to_" + str(args[4])[0:10]
    save_file = os.path.join(args[2], filename)  # create save file name
    plt.savefig(str(save_file),dpi=150) # save figure
    plt.close()


save_dir = '/Users/lgarzio/Documents/RUCOOL/CONCORDE/buoy42067'

file = '/Users/lgarzio/Documents/RUCOOL/CONCORDE/buoy42067/data/42067h9999.nc'

# enter deployment dates
start_time = datetime.datetime(2016, 3, 22, 12, 0, 0)
end_time = datetime.datetime(2016, 4, 7, 15, 0, 0)


# Identifies variables to skip when plotting
misc_vars = ['time','latitude','longitude','dominant_wpd','average_wpd']
reg_ex = re.compile('|'.join(misc_vars))

f = xr.open_dataset(file)
#f = f.swap_dims({'obs':'time'})
f_slice = f.sel(time=slice(start_time,end_time)) # select dates
fName = '42067_USM3M01'
t = f_slice['time'].data
t0 = t[0] # first timestamp
t1 = t[-1] # last timestamp
dir1 = os.path.join(save_dir, 'timeseries_' + str(t0)[0:10] + '_to_' + str(t1)[0:10])
createDir(dir1)


varList = []
for vars in f_slice.variables:
    varList.append(str(vars))

yVars = [s for s in varList if not reg_ex.search(s)]

for v in yVars:
    print v

    y = f_slice[v]
    yD = y.data.flatten()

    #check if the array is all nans
    if len(yD[~np.isnan(yD)]) == 0:
        print v + ": No data available"
        pass
    else:

        try:
            ymin = np.nanmin(yD)
        except TypeError:
            ymin = ""
            continue

        try:
            ymax = np.nanmax(yD)
        except TypeError:
            ymax = ""
            continue

        plotArgs = (fName, v, dir1, t0, t1)
        plot_timeseries(t, y, ymin, ymax, plotArgs)