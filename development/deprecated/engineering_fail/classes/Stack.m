classdef Stack < handle
    %STACK This class allows you to work with a stack of sections.
    % This class provides some methods for working with a set of sections.
    % Make sure that the section objects are already initialized before
    % passing them in to the constructor.
    %
    % This class is usually instantiated by stack.initialize().
    
    properties
        sections
        num_sections
        wafer
        data_path
        metadata_path
        z_matches_path
        section_numbers
        min_section_number
        max_section_number
        time_stamp
        features
        matches
    end
    
    methods
        function s = Stack(sections)
            % Constructs a Stack instance. Sections must be a cell array of
            % section objects from section.initialize() or section.load().
            
            % Some input validation
            if ~iscell(sections) || ~all(cellfun(@isstruct, sections))
                error(['The input was not a cell array of initialized sections (i.e., section structures).\n' ...
                    'Try to load the stack by calling stack.initialize() instead.'])
            end
            
            % Save the sections to instance
            s.sections = sections;
            
            % Save the number of sections for convenience when iterating
            s.num_sections = length(sections);
            
            % The wafer identifier extracted from the folder filenames,
            % e.g., 'S2-W002_Sec100_Montage' -> '002'
            s.wafer = sections{1}.wafer;
            
            % The path to the data folder
            s.data_path = sections{1}.data_path;
            
            % The path to the metadata file for this stack
            s.metadata_path = fullfile(sections{1}.data_path, 'stack_data.mat');
            
            % The path to the matching pairs across different sections
            s.z_matches_path = fullfile(sections{1}.data_path, 'z_matches.mat');
            
            % Build a look-up table between the index of the sections cell
            % array and the actual section number so we can access the
            % section structures using either one
            s.section_numbers = cellfun(@(sec) sec.section_number, sections);
            
            % Convenience properties
            s.min_section_number = min(s.section_numbers);
            s.max_section_number = max(s.section_numbers);
            
            % Time stamp of when this stack was initialized
            s.time_stamp = datestr(now);
            
            % The features field should be empty when saved
            s.features = {};
            
            % The matches field is initialized as empty
            s.matches = struct();
        end
        
        function section = get_section(s, section_number)
            % Returns the section structure with the specified section
            % number.
            
            % Get the index in the cell array
            idx = s.get_section_idx(section_number);
            
            % Check to see if it was found
            if isempty(idx)
                error('Section with section number %d does not exist in this stack.', section_number);
            end
            
            section = s.sections{idx};
        end
        
        function idx = get_section_idx(s, section_number)
            % Returns the index of the specified section number in the
            % sections cell array.
            idx = find(s.section_numbers == section_number, 1);
        end
        
        function load_features(s)
            % Wrapper for the load_features function.
            s.features = stack.load_features(s);
        end
        
        function find_features(s)
            % Wrapper for the find_features function.
            s.features = stack.find_features(s);
        end
        
        function feature_set = get_features(s, section_number)
            % Returns the features structure with the specified section
            % number.
            
            % Get the index in the cell array
            idx = s.get_section_idx(section_number);
            
            % Check to see if it was found
            if isempty(idx)
                error('Section with section number %d does not exist in this stack.', section_number);
            end
            
            % Check to see if we've loaded features for this section
            if idx > length(s.features) || isempty(s.features{idx})
                error('Features for this section have not been loaded.');
            end
            
            feature_set = s.features{idx};
        end
        
        function match_features(s)
            % Wrapper for the match_features function.
            s.matches = stack.match_features(s);
        end
        
        function sobj = saveobj(obj)
            % Subclasses the save function to avoid saving the huge
            % features structure.
            
            sobj = obj;
            sobj.features = {};
        end
    end
    
end

