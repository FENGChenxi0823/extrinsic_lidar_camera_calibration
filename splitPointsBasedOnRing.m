function data = splitPointsBasedOnRing(points, num_beams)
    data(num_beams) = struct();
    total = 0;
    for n = 0:num_beams-1
        if ~any(points(5,:)==n)
%             disp("n")
%             disp(n)
%             disp("points")
%             disp(points(:, points(5,:)==n))
%             pause;
            continue
        end
        ring_point = points(:, points(5,:)==n);
        m = n+1;
        data(m).points = [ring_point(1:3,:); ones(1,size(ring_point,2))];
        data(m).point_with_I = ring_point;
        total= total+size(ring_point,2);
    end
    if total ~= size(points,2)
        warning("inconsistent number of poins in splitPointsBasedOnRing.m");
        warning("split total: %i", total)
        warning("original total %i", size(points,2))
    end
end