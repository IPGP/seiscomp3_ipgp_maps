function mksc3maps
%MAKESC3MAPS make new background maps for SeisComP3
%	From ETOPO1 and SRTM data, makes new tiles for SeisComp3 applications
%	like scolv.
%
%	To produce maps this code uses functions READHGT, DEM and IBIL from the IPGP's 
%	toolbox available at https://github.com/IPGP/mapping-matlab and ETOPO1 
%	data available at https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO1/data/bedrock/grid_registered/binary/etopo1_bed_g_i2.zip
%
%
%	Reference: https://www.seiscomp3.org/wiki/recipes/backgroundmaps
%
%	Authors: François Beauducel, IRD/IPGP <beauducel@ipgp.fr>
%	         Ali A. Fahmi, IRD
%	Created: 2016-12-20, Yogyakarta, Indonesia
%	Updated: 2016-12-27

% try to reproduce original colors from seiscomp3 maps
seacolor = [linspace(51,144)',linspace(79,161)',linspace(122,178)']/255;
landcolor = [linspace(193,230)',linspace(194,230)',linspace(159,230)']/255;

X.optdem = {'noplot','latlon','zlim',[-1e4,1e4],'landcolor',landcolor,'seacolor',seacolor,'lake','interp'};
X.etopo = 'data/etopo1_bed_g_i2'; % ETOPO1 base filename (.bin and .hdr) 
X.psrtm3 = 'data/SRTM3'; % directory to write SRTM3 downloaded files
X.psrtm1 = 'data/SRTM1'; % directory to write SRTM1 downloaded files

% makes needed sub-directories
mkdir(X.psrtm3);
mkdir(X.psrtm1);
mkdir('maps');

% defines the maximum zoom level for all maps
%   4 is default with tiles of 22.5 x 11.25° using ETOPO1
%   6 means tiles of about 6 x 3° using SRTM3
%	8 means tiles of about 1.4 x 0.7° using SRTM1
maxlevel = 4;

% defines a list of targets ([longitude,latitude] pairs in a 2-column matrix)
% for which tiles will be made until level 8 zoom (SRTM1 30m resolution)
targets = [ ...
   110.448654,-7.536658; % Merapi volcano, Indonesia
   -61.663560, 16.04443; % Soufrière volcano, Guadeloupe
   -61.168500, 14.811330; % Pelée volcano, Martinique
    55.714050,-21.24861; % Piton de la Fournaise, Réunion
];

% low resolution maps using ETOPO1
% dividing world map (-180/180,-90,90) into 4 tiles, numbered 0 to 3 from
% northeast to southeast counterclockwise
xylim0 = [-180,180,-90,90];
mkmap(xylim0,[],'etopo',X);
for n1 = 0:3
   xylim1 = mkmap(xylim0,n1,'etopo',X);
   for n2= 0:3
      xylim2 = mkmap(xylim1,[n1,n2],'etopo',X);
      for n3 = 0:3
         xylim3 = mkmap(xylim2,[n1,n2,n3],'etopo',X);
         for n4 = 0:3
            xylim4 = mkmap(xylim3,[n1,n2,n3,n4],'etopo',X);
            % starting level 5 zoom, makes tile only if a target is inside
            for n5 = 0:3
               if maxlevel >= 5 || any(isintoxy(targets,xytile(xylim4,n5)))
                  xylim5 = mkmap(xylim4,[n1,n2,n3,n4,n5],'etopo',X);
                  for n6 = 0:3
                     if maxlevel >= 6 || any(isintoxy(targets,xytile(xylim5,n6)))
                        xylim6 = mkmap(xylim5,[n1,n2,n3,n4,n5,n6],'srtm3',X);
                        for n7 = 0:3
                           if maxlevel >= 7 || any(isintoxy(targets,xytile(xylim6,n7)))
                              xylim7 = mkmap(xylim6,[n1,n2,n3,n4,n5,n6,n7],'srtm3',X);
                              for n8 = 0:3
                                 if maxlevel >=8 || any(isintoxy(targets,xytile(xylim7,n8)))
                                    mkmap(xylim7,[n1,n2,n3,n4,n5,n6,n7,n8],'srtm1',X);
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xylim = mkmap(xylim,n,source,opt)
% n = tile number vector (0 to 3)
% builds tile n(end)
% length(n) is zoom level

f = sprintf(['maps/world',repmat('%d',1,length(n)),'.png'],n);

if ~isempty(n)
   xylim = xytile(xylim,n(end));
end
if ~exist(f,'file')
fprintf('** makes tile "%s": xylim = [%g %g %g %g]... ',f,xylim);

switch lower(source)
	 	case 'etopo'
		    DEM = ibil(opt.etopo,xylim);
			   r = ceil(10/2^length(n));
 		case 'srtm1'
			   DEM = readhgt(xylim([3:4,1:2]),'srtm1','outdir',opt.psrtm1);
			   r = ceil(128/2^length(n));
		 case 'srtm3'
			   DEM = readhgt(xylim([3:4,1:2]),'srtm3','outdir',opt.psrtm3);
			   r = ceil(128/2^length(n));
end
if all(DEM.z(:)==0)
 		fprintf('full offshore tile. Not written.\n')
	  else
		    I = dem(DEM.lon,DEM.lat,DEM.z,'decim',r,opt.optdem{:});
		    imwrite(flipud(I.rgb),f)
		    fprintf('done.\n');
	  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xylim2 = xytile(xylim,n)
% returns the limits of tile from initial area and tile number
% SeisComP3 tiles numbering (left) is converted to binary (right):
%     +---+---+       +----+----+
%     | 1 | 0 |       | 01 | 11 |
%     +---+---+   =>  +----+----+
%     | 2 | 3 |       | 00 | 10 |
%     +---+---+       +----+----+

% re-orders the tile number to get a (more) logical binary information...
tiles = [3,1,0,2];
c = (dec2bin(tiles(n+1),2)=='1'); % tile binary coordinates

xy2 = diff(reshape(xylim,[2,2]))/2; % half size (width,height) of the tile
xylim2 = xylim([1,1,3,3]) + [0,xy2(1),0,xy2(2)] + reshape(repmat(c.*xy2,2,1),1,4);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function k=isintoxy(xy,xylim)
% tests if a coordinate (x,y) is into (x1,x2,y1,y2) limits
if ~isempty(xy)
   k = xy(:,1)>=min(xylim(1:2)) & xy(:,1)<=max(xylim(1:2)) ...
		   & xy(:,2)>=min(xylim(3:4)) & xy(:,2)<=max(xylim(3:4));
else
   k = false;
end
