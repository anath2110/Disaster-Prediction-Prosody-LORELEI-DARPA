	   % Goals: 1) avoid values outside [0..1], Goal 2: avoid a too narrow range 
	   % Probably only rarely will there be values greater than 1,
function normalized = normalizeTo01(estimateMat)
  columnAverages = mean(estimateMat);
  columnMaxima = max(estimateMat);
  columnMinima = min(estimateMat);
  if min(columnMinima) < 0
    fprintf('!!! error, a negative number crept in!!!\n');    
  elseif max(columnMaxima) > 1
    fprintf('note: normalizing to get all values in this column below 1\n');
    normalized = estimateMat ./ repmat(columnMaxima, size(estimateMat,1), 1);
  else
    %normalized = estimateMat;
    colMinRep = repmat(columnMinima, size(estimateMat,1), 1);
    colMaxRep = repmat(columnMaxima, size(estimateMat,1), 1);
    normalized = (estimateMat - colMinRep) ./ (colMaxRep - colMinRep);
  end
end

