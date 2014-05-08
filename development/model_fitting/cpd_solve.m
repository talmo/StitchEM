function T = cpd_solve(z_matches)
total_time = tic;
M = merge_match_sets(z_matches);

X = M.A.global_points;
Y = M.B.global_points;

% Set the options
opt.method='affine'; % 'rigid', 'affine', 'nonrigid'
opt.viz=1;          % show every iteration
opt.savegif = false;

% registering Y to X
Transform=cpd_register(X,Y,opt);

T = [[Transform.s * Transform.R'; Transform.t'] [0 0 1]'];
%T=Transform.s*(Z*Transform.R')+repmat(Transform.t',[size(Z,1) 1]);

avg_prior_error = rownorm2(bsxadd(X, -Y));
avg_post_error = rownorm2(bsxadd(X, -Transform.Y));
fprintf('Error: %f -> %fpx / match (%d matches) [%.2fs]\n', avg_prior_error, avg_post_error, z_matches.num_matches, toc(total_time))
end
% Now lets apply the found transformation to the image
% Create a dense grid of points
%[M,N]=size(refim);
%[x,y]=meshgrid(1:N,1:M); 
%grid=[x(:) y(:)];

% Transform the grid according to the estimated transformation
%T=cpd_transform(grid, Transform);

% Interpolate the image
%Tx=reshape(T(:,1),[M N]);
%Ty=reshape(T(:,2),[M N]);
%result=interp2(im,Tx,Ty);   % evaluate image Y at the new gird (through interpolation)

% Show the result
%figure,imshow(im); title('Source image');
%figure,imshow(refim); title('Reference image');
%figure,imshow(result); title('Result image');
