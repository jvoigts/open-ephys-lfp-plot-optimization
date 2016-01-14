% Test of some time series plot methods
% for the open ephys GUI LFP display
%

Npixels=800;
Nsamples=10000;

Is=[200,Npixels];

rng(1);

% some noise and fake data
X=randn(1,Nsamples)./50;
coeffs=randn(1,200).*10;
for i=1:numel(coeffs)
    X=X+sin(linspace(coeffs(i),coeffs(i)*i,Nsamples))/i;
end;

% add some random spikes
ii=randi(Nsamples,1,40);
X(ii)=X(ii)+3; X(ii+1)=X(ii+1)-.5;

% 'burst' of maximally dense spikes
ii=7000+2*round((linspace(0,4,100).^5));
X(ii)=X(ii)+3; X(ii+1)=X(ii+1)-.5;

% bimodal noise of arying density
ii=[1:2:500]; X(ii)=X(ii)+.5;
ii=[500:5:1000]; X(ii)=X(ii)+1;
ii=[1000:10:1500]; X(ii)=X(ii)+1.5;
ii=[1500:20:2000]; X(ii)=X(ii)+2;

% and with 4 modes
ii=[2500:6:3000]; X(ii)=X(ii)+1;
ii=[2502:6:3000]; X(ii)=X(ii)+2;
ii=[2504:6:3000]; X(ii)=X(ii)+3;

% and 3 modes
ii=[3000:4:3500]; X(ii)=X(ii)+1.5;
ii=[3002:4:3500]; X(ii)=X(ii)+3;

% normal noise
ii=4000:4500;
X(ii)=X(ii)+randn(1,numel(ii))./1;

%uniform noise
ii=4500:5000;
X(ii)=X(ii)+(rand(1,numel(ii))-.5).*3;

% decreasingly dense uniform noise
n=1500;
ii=5000:5000+n;
ii(rand(1,n)<linspace(0,1,n).^2)=[];
X(ii)=X(ii)+(rand(1,numel(ii))-.5).*3;

%re-scale for display
% scale is now pixels
X=((X+10)*20)-130;


% set up mapping between samples and pixels
px2t=1+floor(linspace(0,Nsamples-1,Npixels));
t2px=ceil(linspace(0,Npixels,Nsamples));
t2px_sm=(linspace(0,Npixels,Nsamples)); % for plotting original data

for cond=1:7 % go thorugh different methods
    I=zeros(Is(1),Is(2));
    clf;
    colormap(gray);
    switch cond
        case 1
            expname='matlab_plot';
            plot(t2px_sm,-X);
        case 2
            expname='pick_sample';
            % pick one
            for i=1:Npixels
                I(round(X(px2t(i))),i)=1;
            end;
            imagesc(I);
        case 3
            %mean within pixel
            expname='mean_per_pixel';
            for i=1:Npixels
                m=round(mean(X(t2px==i)));
                I(m,i)=1;
            end;
            imagesc(I);
        case 4
            % range within pixel
            expname='range';
            for i=1:Npixels
                lo=round(min(X(t2px==i)));
                hi=round(max(X(t2px==i)));
                I(lo:hi,i)=1;
            end;
            imagesc(I);
        case 5
            % histogram within pixel
            expname='histogram';
            ll=[1:Is(1)];
            for i=1:Npixels
                slice=histc(X(t2px==i),ll);
                I(:,i)=slice;
            end;
            I=I./max(I(:));
            imagesc(I);
        case 6
            % histogram of paired ranges / supersampling
            expname='supersampling';
            ll=[1:Is(1)];
            for i=1:Npixels
                ip=find(t2px==i);
                Ninpx=numel(ip);
                slice=ll.*0;
                for j=1:Ninpx-1
                    ii=floor(X(ip(j))):ceil(X(ip(j+1)));
                    slice(ii)=slice(ii)+1;
                end;
                I(:,i)=slice;
            end;
            I=I./max(I(:));
            imagesc(I);
        case 7
            % histogram+range within pixel & subsampling
            % & less saturation on envelope
            expname='mixture';
            I_envelope=I;
            
            ll=[1:Is(1)];
            for i=1:Npixels
                ip=find(t2px==i);
                Ninpx=numel(ip);
                slice=ll.*0;
                for j=1:Ninpx-1
                    % uniform between neighboring samples
                    ii=floor(X(ip(j))):1+floor(X(ip(j+1)));
                    slice(ii)=slice(ii)+1;
                    
                    % straight per-pixel histogram
                    ii=round(X(ip(j)));
                    slice(ii)=slice(ii)+1;
                end;
                
                %min-max per pixel
                lo=round(min(X(ip)));
                hi=round(max(X(ip)));
                slice(lo:hi)=slice(lo:hi)+1;
                
                I(:,i)=slice;
                
                slice=ll.*0;
                slice(lo:hi)=slice(lo:hi)+10;
                I_envelope(:,i)=slice;
            end;
            
            
            Ic=zeros(size(I,1),size(I,2),3);
            Ic(:,:,1)=I_envelope;
            Ic(:,:,2)=I;
            Ic(:,:,3)=I;
            Ic=Ic./max(Ic(:));
            image(Ic);
            I=Ic; % just for file output
    end;
    drawnow;
    I=I(:,60:630,:);
    imwrite(I,['plot_test_',expname,'.png'],'png');
end;
