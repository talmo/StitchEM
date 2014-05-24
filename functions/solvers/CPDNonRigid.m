classdef CPDNonRigid < images.geotrans.internal.GeometricTransformation
        
    properties
       
        %Transform object from cpd_register
        Transform
                  
    end
    
    
    methods
        
        function self = CPDNonRigid(Transform)
            %CPDNonRigid
            
            self.Transform = Transform;
            
            self.Dimensionality = 2;
                            
        end
        
        
        function varargout = transformPointsForward(self,varargin)
            %transformPointsForward Apply forward geometric transformation
            %
            %   [x,y] = transformPointsForward(tform,u,v)
            %   applies the forward transformation of tform to the input 2-D
            %   point arrays u,v and outputs the point arrays x,y. The
            %   input point arrays u and v must be of the same size.
            %
            %   X = transformPointsForward(tform,U)
            %   applies the forward transformation of tform to the input
            %   Nx2 point matrix U and outputs the Nx2 point matrix X.
            %   transformPointsFoward maps the point U(k,:) to the point
            %   X(k,:).
            
            
            
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
                
                U = [u, v];
                
            end
            
            self.Transform.beta = self.Transform.beta * self.Transform.normal.yscale;
            self.Transform.W = self.Transform.normal.xscale * self.Transform.W;
            self.Transform.shift = self.Transform.normal.xd - self.Transform.normal.xscale / self.Transform.normal.yscale * self.Transform.normal.yd;
            self.Transform.s = self.Transform.normal.xscale / self.Transform.normal.yscale;

            G = cpd_G(Z, self.Transform.Yorig, self.Transform.beta);
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
                      
            packedPointsSpecified = (nargin==2);
            if packedPointsSpecified
                
                X = varargin{1};
                validateattributes(X,{'single','double'},{'2d','nonsparse'},'images:affine2d:transformPointsInverse','X');
                
                if ~isequal(size(X,2),2)
                    error(message('images:geotrans:transformPointsPackedMatrixInvalidSize',...
                        'transformPointsInverse','X'));
                end
                
            else
                narginchk(3,3);
                x = varargin{1};
                y = varargin{2};
                
                if ~isequal(size(x),size(y))
                    error(message('images:geotrans:transformPointsSizeMismatch','transformPointsInverse','X','Y'));
                end
                
                validateattributes(x,{'double','single'},{'nonsparse'},'images:affine2d:transformPointsInverse','X');
                validateattributes(y,{'double','single'},{'nonsparse'},'images:affine2d:transformPointsInverse','Y');
                
                M = self.Tinv;
                
                varargout{1} = M(1,1).*x + M(2,1).*y + M(3,1);
                varargout{2} = M(1,2).*x + M(2,2).*y + M(3,2);
                
            end
            
        end
        
        function [xLimitsOut,yLimitsOut] = outputLimits(self,xLimitsIn,yLimitsIn)
            %outputLimits Find output limits of geometric transformation
            %
            %   [xLimitsOut,yLimitsOut] = outputLimits(tform,xLimitsIn,yLimitsIn) estimates the
            %   output spatial limits corresponding to a given geometric
            %   transformation and a set of input spatial limits.
            
            [xLimitsOut,yLimitsOut] = outputLimits@images.geotrans.internal.GeometricTransformation(self,xLimitsIn,yLimitsIn);
            
        end
        
        function invtform = invert(self)
            %invert Invert geometric transformation
            %
            %   invtform = invert(tform) inverts the geometric
            %   transformation tform and returns the inverse geometric
            %   transform.
            
            self.T = self.Tinv;
            invtform = self;
            
        end
        
        function TF = isTranslation(self)
            %isTranslation Determine if transformation is pure translation
            %
            %   TF = isTranslation(tform) determines whether or not affine
            %   transformation is a pure translation transformation. TF is
            %   a scalar boolean that is true when tform defines only
            %   translation.
            
            TF = isequal(self.T(1:self.Dimensionality,1:self.Dimensionality),...
                         eye(self.Dimensionality));

        end

        function TF = isRigid(self)
            %isRigid Determine if transformation is rigid transformation
            %
            %   TF = isRigid(tform) determines whether or not affine
            %   transformation is a rigid transformation. TF is a scalar
            %   boolean that is true when tform is a rigid transformation. The
            %   tform is a rigid transformation when tform.T defines only
            %   rotation and translation.

            TF = isSimilarity(self) && abs(det(self.T)-1) < 10*eps(class(self.T));

        end

        function TF = isSimilarity(self)
            %isSimilarity Determine if transformation is similarity transformation
            %
            %   TF = isSimilarity(tform) determines whether or not affine
            %   transformation is a similarity transformation. TF is a scalar
            %   boolean that is true when tform is a similarity transformation. The
            %   tform is a similarity transformation when tform defines only
            %   homogeneous scale, rotation, and translation.

            % Check for expected symmetry in diagonal and off diagonal
            % elements.
            singularValues = svd(self.T(1:self.Dimensionality,1:self.Dimensionality));

            % For homogeneous scale, expect all singular values to be equal
            % to each other within roughly eps of the largest singular value present.
            TF = max(singularValues)-min(singularValues) < 10*eps(max(singularValues(:)));

        end
                                                                      
    end
    
    methods
        % Set/Get methods
        function self = set.T(self,T)
            
            % This is to support internal CVST requirement of allowing 3x2
            % specification of affine matrix. 
            if isnumeric(T) && isequal(size(T),[3 2])
                T = [T,[0 0 1]'];
            end
            
            validateattributes(T,{'single','double'},{'size',[3 3],'finite','nonnan','nonsparse'},...
                'affine2d.set.T',...
                'T');
            
            % Check last column of T
            if ~isequal(T(:,3),[0 0 1]')
                error(message('images:geotrans:invalidAffineMatrix'));
            end
            
            self.T = T;
            
        end
        
        function Tinv = get.Tinv(self)
           
            tinv = inv(self.T);
            tinv(:,end) = [0;0;1];
            Tinv = tinv;
            
        end
        
    end
    
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of geometric transformation classes
    % changes.
    methods (Hidden)
       
        function S = saveobj(self)
            
            S = struct('TransformationMatrix',self.T);
            
        end
        
    end
    
    methods (Static, Hidden)
       
        function self = loadobj(S)
           
            self = affine2d(S.TransformationMatrix);
            
        end
        
    end
        
end