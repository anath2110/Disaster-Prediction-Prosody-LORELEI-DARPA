function [stancePrediction, votePerTest, neighbors,neighnames,neighdisnames,neighpatches,namespatches,uniquenamespatches] = ....
    knnForTypes(testdata, testtimestamps,Model, trainingResults,reftimestamps,refnames, k)
    %regSegmentNN predicts values for each segment testdata using...
    %Model(training features) and trainingResults(types per training patch)...
    %according to the k nearest neighbor algorithm and outputs the predicted values.

    votes = zeros(1, size(trainingResults,2));

    votePerTest = zeros(size(testdata,1), size(trainingResults,2));

    [neighbors, distances] = knnsearch(Model,testdata,'K',k);

    %retrieving names,patches of the all 3 neighbour audio files
    neighnames=[];
    neighpatches=[];
    testpatchesneigh=[];
    for neighrow=1:size(neighbors,1)

        for neighcol=1:size(neighbors,2)
            if length(neighnames)==0 && length(neighpatches)==0 && length(testpatchesneigh)==0
                neighnames=refnames(neighbors(neighrow,neighcol),:);
                neighdisnames=unique(neighnames,'rows');
                neighpatches=reftimestamps(neighbors(neighrow,neighcol),1);
                testpatchesneigh=[testtimestamps(neighrow) reftimestamps(neighbors(neighrow,neighcol),1)];
            else
                neighnames=vertcat(neighnames,refnames(neighbors(neighrow,neighcol),:));
                neighdisnames=unique(neighnames,'rows');
                neighpatches=vertcat(neighpatches,reftimestamps(neighbors(neighrow,neighcol),1));
                testpatchesneigh=vertcat(testpatchesneigh,[testtimestamps(neighrow) reftimestamps(neighbors(neighrow,neighcol),1)]);
            end
        end
    end

    namespatches=table(testpatchesneigh,neighnames);
    uniquenamespatches=unique(namespatches);


    distances = distances .^ 2 + 0.0000000001;

    %test every value
    for row = 1:size(testdata,1)

        %sums each squared element and keeps track of the index
        dist = distances(row,:);

        %get indices of the k nearest frames in the training data
        vals = neighbors(row,:);

       

        %get the type values of those k nearest frames from the
        %trainingResults
        vals = trainingResults(vals,:);

        %get the squared distances of the k nearest frames and invert them for
        %weights

        weights = (1 ./ dist)';

        % replicate the weights for each of the type predictions
        weights = repmat(weights,1,size(trainingResults,2));

        % weighted average = sum(value_i * weight_i) / sum(weight_i) for all i
        vals = vals .* weights;

        vals = sum(vals,1);

        vals = vals ./ (sum(weights, 1));

        votePerTest(row,:) = vals; %type prediction per row of testdata

        % add the weighted average to the running total
        for j = 1:size(votes,2)
            votes(1,j) = votes(1,j) + vals(1,j);
        end
    end

    %get the predictions by dividing the running sum of weighted averages by
    %the number of frames in the test data.

    stancePrediction = votes ./ size(testdata,1);

end
