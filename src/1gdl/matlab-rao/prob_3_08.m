function res = prob_3_08(plotar)
% Prob. 3.8: mola de 4000 N/m, forca de 100 N a 5 Hz, amplitude observada 20 mm.
% Achar m.  |k - m w^2| = F0/X  ->  m = (k -+ F0/X)/w^2  (so vale m > 0).
    if nargin < 1, plotar = true; end
    k = 4000; F0 = 100; f = 5; Xobs = 0.02; w = 2*pi*f;
    m_cand = [(k - F0/Xobs), (k + F0/Xobs)]/w^2;
    m_cand = m_cand(m_cand > 0);
    for i = 1:numel(m_cand)
        fprintf('\n>> m candidato = %.4f kg\n', m_cand(i));
        res(i) = sdof_caso(sprintf('3.8-%d',i),m_cand(i),0,k,F0,w,0,0,2,5e-4,plotar);
    end
end
