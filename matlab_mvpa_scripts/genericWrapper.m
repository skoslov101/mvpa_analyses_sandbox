function genericWrapper(varargin)

%% In this function, there are two required inputs
%1) Function Name
%2) Subject Number

%Optional arguments may increase, but for now, I just need subject initials
%sometimes
%3) subject inits


func1=varargin{1};
subjN=varargin{2};

if length(varargin)>2
    subInit=varargin{3};
end

for subI=1:length(subjN)
    func1(subjN(subI),subInit{subI})
end