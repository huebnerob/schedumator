% this semester schedule:
% classes = {'ME342A','ME335A','ME358','ME358L','PE200F1','ME345E','ME322D'};
%
% last semester schedule: 
% classes = {'me361','e243','me234','me225','e344','e321'};
% when me361a is scheduled, e344 will eventually conflict
% when me361b is scheduled, me225 will eventually conflict
% so no solution is possible!

function schedumator( classes ) 
    disp( ' ' )
    disp( 'Welcome to The Schedumator for Stevens Inst. of Tech.' )
    disp( 'Version 1.0' )
    disp( '(C)2013 Rob Huebner' )
    disp( ' ' )
    
    % this retrieves the xml file from Stevens containing all schedule
    % information
    domnode = xmlread('http://www.stevens.edu/scheduler/core/core.php?cmd=getxml&term=2013S');
%     domnode = xmlread('stevens_sched.xml');
    root = domnode.getDocumentElement;
     
    % if classes are not specified on the command line, prompt the user
    if length(classes) == 0
        classes = promptForClasslist(root);
    end

    % get the schedules from the specified class list
    schedules = schedulesForClasses(root,classes);
    if length(schedules) == 0 % no valid schedules found
       disp( 'From here, it looks like there are no schedules for those classes without conflicts.' )
       disp( 'Remove a class and try again :)' )
    end
    
    % this loop displays all the valid schedules
    for j = 1:length(schedules)
        schedule = schedules{j};
        disp( ' ' )
        disp( ' ' )
        disp( ['------- SCHEDULE ', num2str(j), ' ---------------'] ) 
        for i = 1:length(schedule)
            dispMeeting(schedule{i})
            if i<length(schedule) && schedule{i}{2}~=schedule{i+1}{2}
               disp( ' ' ) % seperates weekdays, looks nicer
            end
        end
    end
end

% prompts the user for a list of classes
function classes = promptForClasslist(r) 
    disp( 'Enter a list of classes to schedule.' )
    disp( '**  to schedule a lab or recitation, enter the "L" or "R" section separately' )
    disp( '**  e.g: ME345, ME358, ME358L, ...' )
    class = 'dummyval';
    classes = {};
    while 1
        disp(' ')
       class = input('course number (or leave blank if done): ', 's'); %prompt for a course name
       if strcmp(class,'')==1
          break; 
       end
       class(class==' ') = ''; %remove all whitespace from query
       class = upper(class); %convert to uppercase
       [sct,mtn] = findMeet(r, class); % runs the query 
       if( length(sct) >= 20 )
           disp( 'Too many classes were found, be more specific!' )
       else if length(sct) > 0 
               % valid class
               % displays the short list of classes for verification
               str = [];
               for i = 1:length(sct)
                   str = [sct{i}, ' ', str];
               end
               disp( ['Found sections: ', str] )
               classes = [classes; {class}];
           else
              disp( 'Course not found, try again!' ) 
           end
       end
    end
end

% main logic of the program, searches for each specified class on class
% list then checks each permutation of sections for validity, returning the
% valid ones
function schedules = schedulesForClasses( r, classList )
    numSections = [];
    nameSections = {};
    allMtngs = {};
    poss = {{}};
    for i = 1:length(classList)
        [sct,mtn] = findMeet(r, classList{i});
        allMtngs{i} = mtn; % stores all meetings for the class
        numSections(i) = length(sct); % stores the number of unique sections
        nameSections{i} = sct; % and the names of those sections
    end
    
    % this loop runs over all specified classes
    for i = 1:length(numSections)
        classMtngs = allMtngs{i};
        if numSections(i) > 1 %more than one section, schedule needs to branch
            p_new = {};
            for n = 1:numSections(i) % all sections
                for p = 1:length(poss)
                    this_p = poss{p}; % copy all preexisting possible schedules
                    for j = 1:length(classMtngs) % all meetings
                       if strcmp(classMtngs{j}{1},nameSections{i}{n})==1 % if the meeting is the correct section
                          this_p = [this_p; {classMtngs{j}}];
                       end
                    end
                    p_new = [p_new; {this_p}]; %appends a new possibility for each new class permutation
                end
            end
            poss = p_new;
        else % there's only one possible section, that's easy
            for p = 1:length(poss)
                for n = 1:length(classMtngs)
                   poss{p} = [poss{p}; {classMtngs{n}}]; % simply append the sections to the preexisting schedules
                end
            end
        end
    end
    
    schedules = {};
    for q = 1:length(poss)
        [schedule, valid] = sort(poss{q}); % check the validity of each schedule
        if valid == 1
           schedules = [schedules; {schedule}]; % returning only the valid ones
        end
    end
    if length(schedules{1})==0
       schedules = {}; % nullify if no valid schedules
    end
end

% compares meetings (a ? b) and returns before (-1) after (1) or conflicts (0) 
function c = compareMeetings(a,b) 
    as = day2min(a{2},a{3}); % start of meeting A
    ae = day2min(a{2},a{4}); % end of meeting A
    bs = day2min(b{2},b{3}); % start of meeting B
    be = day2min(b{2},b{4}); % end of meeting B
    if( (as<=bs && bs<ae) || (as<be && be<=ae)  || (as==bs&&ae==be) ) % coincident
        c = 0;
    else if as < bs % before
            c = -1;
        else % after
            c = 1;
        end
    end
    
end

% sorts a list of meetings, returns valid == 0 if there are any collisions
function [s, valid] = sort( m )
    s = m(:);
    valid = 1;
    for i = 1:length(m)
        for j = i+1:length(m)
            result = compareMeetings(s{i},s{j});
            if result == 0
                valid = 0;
                % more sorting should happen here but we arent using the
                % results anyway
            else if result == 1 % swap them if necessary
                temp = s{j};
                s{j} = s{i};
                s{i} = temp;
                end
            end
        end
    end
end

% flattens days of the week into minutes for comparsion purposes
function val = day2min( day, time ) 
    val = day*24*60+time;
end

% prints line describing a meeting
function dispMeeting(m)
    days = {'Mon','Tue','Wed','Thu','Fri','Sat','Sun'};
    disp( [days{m{2}}, ' ', print(m{3}), ' to ', print(m{4}), ' :: [', m{1}, ' ', m{5}, '] (', m{6}, ')' ] ) 
end

% find meetings information for a class from the XML data
function [sects,mtngs] = findMeet(r, q)
    sects = {};
    mtngs = {};
    for i = 1:2:r.getLength-1 %skip by two to avoid #text nodes, bug in xml parse?
        %get the section number, title, and call number from the Course node
        s = char(r.item(i).getAttributes.getNamedItem('Section').getValue); 
        c_n = char(r.item(i).getAttributes.getNamedItem('Title').getValue);
        call = char(r.item(i).getAttributes.getNamedItem('CallNumber').getValue);
        s(s==' ') = ''; %removes all whitespace from section name
        if( length(s)-length(q)>1 ) % corrects the lab/recitation section problem, kind of a bandaid
           continue; 
        end
        if( length(strfind(s, q))==1  && length(strfind(s(2:end),q))==0 ) % make sure search starts at beginning
            for j = 1:2:r.item(i).getChildNodes.getLength-1 % once again skip by two to avoid #text
                if strcmp(r.item(i).getChildNodes.item(j).getNodeName,'Meeting') % if it is a meeting (ignoring requirments for now)
                    attrs = r.item(i).getChildNodes.item(j).getAttributes;
                    day = char(attrs.getNamedItem('Day').getValue);
                    if strcmp(day,'TBA')~=1 %can't process 'TBA' unscheduled meetings
                        sects = [sects; {s}];
                        % gets start time and end time from meeting
                        startStr = char(attrs.getNamedItem('StartTime').getValue);
                        stopStr = char(attrs.getNamedItem('EndTime').getValue);
                        start = telltime(startStr);
                        stop = telltime(stopStr);
                        days = code(day);
                        for k = 1:length(days)
                            mtngs = [mtngs; {{s,days(k),start,stop,c_n,call}}];
                        end
                    end
                end
            end
        end
    end
    sects = unique(sects);
end 

% takes a time string and returns a decimal number of minutes past midnight
function minutes = telltime(s)
    s(s==':') = ' '; %changes :'s to spaces
    s(s=='Z') = ''; %removes Z
    vals = str2num(s); %creates array of values
    minutes = vals(1)*60 + vals(2); %calculates minutes past midnight
    minutes = minutes + 5*60; %adds 5 hours to correct for time zone, hardcoded
end

% turns an minutes value (as returned above) to a human readable string
function str = print(minutes) 
    h = floor(minutes/60);
    m = mod(minutes,60);
    if h >= 12
        if h > 12
            h = mod(h,12);
        end
        ampm = 'pm';
    else 
        ampm = 'am';
    end
    str = [num2str(h,'%02d'), ':', num2str(m,'%02d'), ampm];
end
    
% finds day indices from daycodes, e.g.: 'MW' -> [1,3]
function days = code(s)
    codes = ['M','T','W','R','F','S','U'];
    days = {};
%     s = char(s{1});
    for i = 1:length(s)
        day = strfind(codes,s(i));
        days = [days; day];
    end
    days = cell2mat(days);
end

%#ok<*AGROW>