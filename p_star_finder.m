function p_star = p_star_finder(A, B, P)

    eps_val = 1e-6;

    A = A(:);
    B = B(:);
    P = P(:);

    AP = P - A;
    AB = B - A;

    AB_norm_sq = norm(AB)^2;

    if AB_norm_sq < eps_val
        p_star = A;
        return;
    end

    t = dot(AP, AB) / AB_norm_sq;
    tc = min(max(t, 0), 1);

    p_star = A + tc * AB;

end