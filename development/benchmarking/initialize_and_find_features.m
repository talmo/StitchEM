dir_listing = dir('/data/home/talmo/EMdata/W002');
sections = {dir_listing([dir_listing.isdir]').name}';
sections = sections(cellfun(@(name) ~isempty(strfind(name, '_Montage')), sections));

sections = find_section_folders('/data/home/talmo/EMdata/W002');

tic;
for i = 1:numel(sections)
    section = initialize_section(sections{i}, true, 0.1); 
    find_section_features(section);
end
toc;
