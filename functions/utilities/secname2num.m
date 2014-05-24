function sec_num = secname2num(sec_name)
%SECNAME2NUM Parses the section name to return its number.

section_pattern = '(?<wafer>S\d+-W\d+)_Sec(?<sec>\d+)_Montage$';
sec_matches = regexp(sec_name, section_pattern, 'names');

sec_num = str2double(sec_matches.sec);

end

