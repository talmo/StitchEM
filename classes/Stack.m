classdef Stack
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
        end
        
        function section = get_section(s, section_number)
            % Returns the section structure with the specified section
            % number.
            
            % Get the index in the cell array
            idx = s.get_section_idx(section_number);
            
            % Check to see if it was found
            if isempty(idx)
                error('Section with the specified section number does not exist in this stack.');
            end
            
            section = s.sections{idx};
        end
        
        function idx = get_section_idx(s, section_number)
            % Returns the index of the specified section number in the
            % sections cell array.
            idx = find(s.section_numbers == section_number, 1);
        end
    end
    
end

