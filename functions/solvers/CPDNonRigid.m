classdef CPDNonRigid < images.geotrans.internal.GeometricTransformation
        
    properties
       
        %Transform object from cpd_register
        Transform
                  
    end
    
    
    methods
        
        function self = CPDNonRigid(Transform)
            %CPDNonRigid
            
            self.Transform = Transform;
            self.Transform.beta = self.Transform.beta * self.Transform.normal.yscale;
            self.Transform.W = self.Transform.normal.xscale * self.Transform.W;
            self.Transform.shift = self.Transform.normal.xd - self.Transform.normal.xscale / self.Transform.normal.yscale * self.Transform.normal.yd;
            self.Transform.s = self.Transform.normal.xscale / self.Transform.normal.yscale;
            
            self.Dimensionality = 2;
                            
        end
        
        function G = G(self, x)
            k= -2 * self.Transform.beta ^ 2;
            [n, d] = size(x);
            [m, d] = size(self.Transform.Yorig);

            G = repmat(x, [1 1 m]) - permute(repmat(self.Transform.Yorig, [1 1 n]), [3 2 1]);
            G = squeeze(sum(G .^ 2, 2));
            G = G / k;
            G = exp(G);
        end
        
        function varargout = transformPointsForward(self,varargin)
            %transformPointsForward Apply forward geometric transformation
            
            packedPointsSpecified = (nargin==2);
            if packedPointsSpecified
                U = varargin{1};
                validateattributes(U,{'single','double'},{'2d','nonsparse'},'images:affine2d:transformPointsForward','U');
                if ~isequal(size(U,2),2)
                    error(message('images:geotrans:transformPointsPackedMatrixInvalidSize',...
                        'transformPointsForward','U'));
                end
            else
                narginchk(3,3);
                u = varargin{1};
                v = varargin{2};
                if ~isequal(size(u),size(v))
                    error(message('images:geotrans:transformPointsSizeMismatch','transformPointsForward','U','V'));
                end
                validateattributes(u,{'double','single'},{'nonsparse'},'images:affine2d:transformPointsForward','U');
                validateattributes(v,{'double','single'},{'nonsparse'},'images:affine2d:transformPointsForward','V');
                U = [u(:), v(:)];
            end
            
            G = self.G(U);
            X = U * self.Transform.s + G * self.Transform.W + repmat(self.Transform.shift, size(U, 1), 1);
            
            
            if packedPointsSpecified
                varargout{1} = X;
            else
                varargout{1} = X(:, 1);
                varargout{2} = X(:, 2);
            end
                        
        end
        
        function varargout = transformPointsInverse(self,varargin)
            %transformPointsInverse Apply inverse geometric transformation
            %
            %   [u,v] = transformPointsInverse(tform,x,y)
            %   applies the inverse transformation of tform to the input 2-D
            %   point arrays x,y and outputs the point arrays u,v. The
            %   input point arrays x and y must be of the same size.
            %
            %   U = transformPointsInverse(tform,X)
            %   applies the inverse transformation of tform to the input
            %   Nx2 point matrix X and outputs the Nx2 point matrix U.
            %   transformPointsFoward maps the point X(k,:) to the point
            %   U(k,:).
                      
%             packedPointsSpecified = (nargin==2);
%             if packedPointsSpecified
%                 
%                 X = varargin{1};
%                 validateattributes(X,{'single','double'},{'2d','nonsparse'},'images:affine2d:transformPointsInverse','X');
%                 
%                 if ~isequal(size(X,2),2)
%                     error(message('images:geotrans:transformPointsPackedMatrixInvalidSize',...
%                         'transformPointsInverse','X'));
%                 end
%                 
%             else
%                 narginchk(3,3);
%                 x = varargin{1};
%                 y = varargin{2};
%                 
%                 if ~isequal(size(x),size(y))
%                     error(message('images:geotrans:transformPointsSizeMismatch','transformPointsInverse','X','Y'));
%                 end
%                 
%                 validateattributes(x,{'double','single'},{'nonsparse'},'images:affine2d:transformPointsInverse','X');
%                 validateattributes(y,{'double','single'},{'nonsparse'},'images:affine2d:transformPointsInverse','Y');
%                 
%                 M = self.Tinv;
%                 
%                 varargout{1} = M(1,1).*x + M(2,1).*y + M(3,1);
%                 varargout{2} = M(1,2).*x + M(2,2).*y + M(3,2);
%                 
%             end
            
        end
        
        function [xLimitsOut,yLimitsOut] = outputLimits(self,xLimitsIn,yLimitsIn)
            %outputLimits Find output limits of geometric transformation
            %
            %   [xLimitsOut,yLimitsOut] = outputLimits(tform,xLimitsIn,yLimitsIn) estimates the
            %   output spatial limits corresponding to a given geometric
            %   transformation and a set of input spatial limits.
            
            [xLimitsOut,yLimitsOut] = outputLimits@images.geotrans.internal.GeometricTransformation(self,xLimitsIn,yLimitsIn);
            
        end
        
        
                                                                      
    end
        
end