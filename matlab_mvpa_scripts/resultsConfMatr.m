%Compute error matrix for CrossVal Performance

%First load the results .mat

allGuesses=[pmLocCrossVal.results.iterations(1).perfmet.guesses,...
    pmLocCrossVal.results.iterations(2).perfmet.guesses,...
    pmLocCrossVal.results.iterations(3).perfmet.guesses];

allDesireds=[pmLocCrossVal.results.iterations(1).perfmet.desireds,...
    pmLocCrossVal.results.iterations(2).perfmet.desireds,...
    pmLocCrossVal.results.iterations(3).perfmet.desireds];

cMat=confusionmat(allDesireds,allGuesses)