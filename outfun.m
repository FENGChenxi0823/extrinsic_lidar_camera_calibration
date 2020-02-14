function stop = outfun(in, optimValues, state, idx, X, X_reference)
     persistent history searchdir fhistory
     stop = false;
 
     switch state
         case 'init'
             hold on
             history = [];
             fhistory = [];
             searchdir = [];
         case 'iter'
         % Concatenate current point and objective function
         % value with history. in must be a row vector.
           fhistory = [fhistory; optimValues.fval];
           history = [history; in(:)']; % Ensure in is a row vector
         % Concatenate current search direction with 
         % searchdir.
           searchdir = [searchdir;... 
                        optimValues.searchdirection(:)'];
           plot(in(idx.x),in(idx.y),'o');
         % Label points with iteration number and add title.
         % Add .15 to idx.x to separate label from plotted 'o'
           text(in(idx.x)+.15,in(idx.y),... 
                num2str(optimValues.iteration));
           title('Sequence of Points Computed by fmincon');
         case 'done'
             hold off
             assignin('base','optimhistory',history);
             assignin('base','searchdirhistory',searchdir);
             assignin('base','functionhistory',fhistory);
         otherwise
     end
 end