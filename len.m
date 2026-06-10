rootDir = 'result';
datRoot = fullfile(rootDir, '실험 결과 dat 파일 모음');

name = '(0.02)SAC_ver15(mod_1)';
q0File = fullfile(datRoot, name, 'EpisodeQ0.dat');

M = readmatrix(q0File);
M = M(~all(isnan(M),2), :);

fprintf('EpisodeQ0 size = %d x %d\n', size(M,1), size(M,2));

for j = 1:size(M,2)
    col = M(:,j);
    valid = ~isnan(col);

    fprintf('\nColumn %d\n', j);
    fprintf('  valid count = %d / %d\n', sum(valid), numel(col));

    if any(valid)
        fprintf('  first valid = %.6g\n', col(find(valid,1,'first')));
        fprintf('  last valid  = %.6g\n', col(find(valid,1,'last')));
        fprintf('  mean        = %.6g\n', mean(col(valid)));
        fprintf('  std         = %.6g\n', std(col(valid)));
        fprintf('  min         = %.6g\n', min(col(valid)));
        fprintf('  max         = %.6g\n', max(col(valid)));
    else
        fprintf('  all NaN\n');
    end
end