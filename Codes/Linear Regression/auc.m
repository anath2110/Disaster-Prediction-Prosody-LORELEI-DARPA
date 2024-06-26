function A = auc(pred, ground_truth)
  %% computes the area under the ROC curve
  %%   pred is probably in [0,1]; ground truth is 0 or 1
  %%   programmed by Olac Fuentes, 2016
  %% c.f. prAuc for the area under the precision-recall curve
  pos = sum(ground_truth);
  neg = length(ground_truth) - pos;
  [sorted_pred, ind] = sort(pred);
  sorted_gt = ground_truth(ind);
  c = cumsum(sorted_gt);
  c = c(end) - c;
  A = sum(c(sorted_gt==0))/pos/neg;
end

  
