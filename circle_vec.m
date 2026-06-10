function [p_star, dir] = circle_vec(C_pos, R, z_ref, pos)

    eps_val = 1e-6;

    % 원 벡터필드 파라미터
    chi_inf = pi/2;
    k = 0.5;
    kz = 0.2;

    C = C_pos(:);   % [cx; cy; cz]
    P = pos(:);     % [x; y; z]

    C_xy = C(1:2);
    P_xy = P(1:2);

    r_xy = P_xy - C_xy;
    r_norm = norm(r_xy);

    % Coder용 초기화
    r_hat = [1; 0];
    p_star_xy = C_xy + [R; 0];
    dir = [0; 0; 0];

    if r_norm < eps_val
        r_hat = [1; 0];
        p_star_xy = C_xy + [R; 0];
    else
        r_hat = r_xy / (r_norm + eps_val);
        p_star_xy = C_xy + R * r_hat;
    end

    % 3차원 원 궤도 위 최근접점
    p_star = [p_star_xy; z_ref];

    % 반경 오차 (스칼라)
    h = r_norm - R;

    % 접선 방향 각도 (CCW)
    w_hat = [-r_hat(2); r_hat(1)];
    w_theta = atan2(w_hat(2), w_hat(1));

    % desired heading
    chi_desired = w_theta - chi_inf * 2/pi * atan(k * h);

    % xy 방향벡터
    u = -cos(chi_desired);
    v = -sin(chi_desired);

    % z 방향벡터
    z_err = z_ref - P(3);
    z_cmd = kz * z_err;

    dir = [u; v; z_cmd];
    dir_norm = norm(dir);

    if dir_norm < eps_val
        dir = [0; 0; 0];
    else
        dir = dir / dir_norm;
    end

end