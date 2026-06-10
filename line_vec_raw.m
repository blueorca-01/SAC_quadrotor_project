function vec = line_vec_raw(A_pos, B_pos, pos)
    % 논문: (0.02)TD3_ver3(mod_1) 기반 선분 항로 추종 로직 구현
    
    % --- 파라미터 설정 (논문의 Gain 및 Max 값 기준) ---
    eps_val     = 1e-6;    % 수치적 안정성을 위한 작은 양수 (식 2, 5, 13, 18, 25, 33)
    v_line_max  = 5.0;     % 선분 진행 방향 최대 속도 (v_line,max)
    v_perp_max  = 2.5;     % 횡방향 최대 속도 (v_perp,max)
    v_point_max = 5.0;     % 호버링/도착점 지향 최대 속도 (v_max)
    
    k_t         = 0.4;     % 진행 방향 속도 이득 (k_t)
    k_perp      = 0.4;     % 횡방향 속도 이득 (k_perp)
    k_point     = 0.4;     % 점 정착(Hovering) 속도 이득 (k_v)
    
    v_max_total = 5.0;     % 최종 출력 벡터의 최대 제한 속도 (v_max)

    % 입력 벡터화
    A = A_pos(:);
    B = B_pos(:);
    P = pos(:);

    % ===== 1. 기본 벡터 및 투영 계산 (식 5, 6, 7, 8) =====
    AB = B - A;
    norm_AB = norm(AB);
    
    if norm_AB < eps_val
        vec = [0; 0; 0];
        return;
    end

    % 식 (5): 선분 단위 벡터 q_hat
    q_hat = AB / (norm_AB + eps_val);

    % 식 (6): 투영 파라미터 t 계산
    AP = P - A;
    t = dot(AP, AB) / (norm_AB^2);

    % 식 (7): t를 [0, 1] 구간으로 제한 (tc)
    tc = min(max(t, 0), 1);

    % 식 (8): 선분 상의 최근접점 P_star
    p_star = A + tc * AB;

    % ===== 2. 선분 추종 속도 계산 (식 9, 10, 11, 12, 13, 14, 15) =====
    % 식 (9): 진행 오차 벡터 e_B (P_star에서 B까지)
    e_B = B - p_star;
    d_B = norm(e_B);

    % 식 (10): 진행 방향 속도 성분 v_line
    v_line_mag = v_line_max * tanh(k_t * d_B);

    % 식 (11): 횡방향 오차 벡터 e_perp (P에서 P_star까지)
    e_perp = p_star - P;
    d_perp = norm(e_perp);

    % 식 (13): 횡방향 단위 벡터 q_perp_hat
    q_perp_hat = e_perp / (d_perp + eps_val);

    % 식 (12): 횡방향 속도 성분 v_perp
    v_perp_mag = v_perp_max * tanh(k_perp * d_perp);

    % 식 (14): 선분 추종 속도 벡터 v_line_vec 구성
    v_line_vec = (v_line_mag * q_hat) + (v_perp_mag * q_perp_hat);

    % 식 (15): 최대 속도 제한 (v_max)
    v_line_vec_norm = norm(v_line_vec);
    if v_line_vec_norm > v_max_total
        v_line_vec = (v_max_total / v_line_vec_norm) * v_line_vec;
    end

    % ===== 3. 점 정착(Hovering) 속도 계산 (식 1~4 기반) =====
    % 도착점 B를 향한 단순 점 정착 벡터 (V_point)
    e_point = B - P;
    d_point = norm(e_point);
    
    if d_point < eps_val
        v_point_vec = [0; 0; 0];
    else
        dir_point = e_point / d_point;
        % 식 (3, 4)와 유사한 로직
        speed_point = v_point_max * tanh(k_point * d_point);
        v_point_vec = speed_point * dir_point;
    end

    % ===== 4. 최종 참조 속도 결정 (식 16: 핵심 로직) =====
    % V_cmd = (1 - tc) * V_line + tc * V_point
    % t < 0 (A 이전) -> tc=0 -> V_line 사용
    % t > 1 (B 이후) -> tc=1 -> V_point 사용
    % 0 < t < 1 -> 두 벡터를 tc에 따라 부드럽게 혼합
    vec = (1 - tc) * v_line_vec + tc * v_point_vec;

end