function dir = dot_vec(target_pos, pos)

    target_pos = target_pos(:);
    pos = pos(:);
    eps_val = 1e-6;

    r = target_pos - pos;
    r_norm = norm(r);

    if r_norm < eps_val
        dir = [0; 0; 0];
    else
        dir = r / r_norm;
    end

end