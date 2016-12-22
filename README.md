# seiscomp3 background maps from IPGP

This project proposes new maps for background navigation in SeisComP3 applications like scolv. Improvements are:
* better global resolution using ETOPO1 data
* possibility to zoom on specific targets at higher resolution, using SRTM data
* possibility to change a lot of mapping parameters (land/sea colormap, lighting, constrast, etc...)

![](mksc3maps_screenshot_level0.png)
![](mksc3maps_screenshot_level3.png)
![](mksc3maps_screenshot_level5.png)
![](mksc3maps_screenshot_level8.png)

## seiscomp3-ipgp-maps.tgz

Download the file at [seiscomp3-ipgp-maps.tgz](http://www.ipgp.fr/~beaudu/download/seiscomp3-ipgp-maps.tgz)  (452 Mb).

This tar archive contains 355 tiles named to be used as background maps in SeisComP3 applications like scolv.

To install it, seiscomp must be installed and configured, then just do:
```sh
cd $SEISCOMP_ROOT/share/maps
tar zxf seiscomp3-ipgp-maps.tgz
```

## mksc3maps.m: make new background maps

Matlab code to produce the maps.

### Dependencies

* use some functions from [mapping-matlab](../mapping-matlab) toolbox, in particular readhgt.m, ibil.m and dem.m
* ETOPO1 data, available at NGDC/NOAA: download the file [etopo1.zip](https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO1/data/bedrock/grid_registered/binary/etopo1_bed_g_i2.zip)
* SRTM3 and SRTM1 data will be automatically downloaded by the code (needs internet connection)

### Instllation and configuration

The code is a single function without argument. Some variable must be ajusted to proper local values:
```matlab
X.etopo = '/home/joe/grids/ETOPO/etopo1_bed_g_i2'; % ETOPO1 base filename (.bin and .hdr) 
X.psrtm3 = '/home/joe/grids/SRTM3'; % directory to write SRTM3 downloaded files
X.psrtm1 = '/home/joe/grids/SRTM1'; % directory to write SRTM1 downloaded files
```
It is mandatory to have two separated directories for SRTM1 and SRTM3 since they use the same filename. Once .hgt files are written, they won't be downloaded again from internet if the code is run again.

Default behavior of the code will make only level 4 zoom tiles using ETOPO1.

To make level 5 to 8 zoom tiles, define targets with coordinates longitude,latitude, e.g.:
```matlab
targets = [110.448654,-7.536658;   % Merapi volcano, Indonesia
           -61.663560, 16.04443;   % Soufrière volcano, Guadeloupe
           -61.168500, 14.811330;  % Pelée volcano, Martinique
            55.714050,-21.24861;   % Piton de la Fournaise, Réunion
];
```
Note that targets cannot be outside latitude 60S-60N (no SRTM data).

Graphic options are also in the code script and can be changed:
```matlab
seacolor = [linspace(51,144)',linspace(79,161)',linspace(122,178)']/255;
landcolor = [linspace(193,230)',linspace(194,230)',linspace(159,230)']/255;
```
Those two variables are Mx3 matrix of RGB values to define submarine and land colormaps, respectively. Proposed values attempt to reproduce the original SeisComP3 colormaps. Comment these lines and use seacolor.m and landcolor.m from [mapping-matlab](mapping-matlab) toolbox to try colorful maps.

```matlab
X.optdem = {'noplot','latlon','zlim',[-1e4,1e4],'landcolor',landcolor,'seacolor',seacolor,'lake','interp'};
```
This cell vector contain options for the main dem.m function that produces the lighting relief. See dem.m documentation for possible arguments.


### Usage

From Matlab command window, run:
```matlab
mksc3maps
```


## Author
**François Beauducel**, IPGP, [beaudu](https://github.com/beaudu), beauducel@ipgp.fr 

## Documentation
Type "doc mksc3maps" for detailed usage.
