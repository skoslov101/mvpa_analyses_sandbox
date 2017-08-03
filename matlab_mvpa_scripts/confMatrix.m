%Quick way to perform a confusion matrix on loaded results file

%So at this point you've loaded the desired pmAll file

hat=[pmAll.results.iterations(6).perfmet.desireds,pmAll.results.iterations(7).perfmet.desireds,pmAll.results.iterations(8).perfmet.desireds,...
    pmAll.results.iterations(9).perfmet.desireds,pmAll.results.iterations(10).perfmet.desireds];

guess=[pmAll.results.iterations(6).perfmet.guesses,pmAll.results.iterations(7).perfmet.guesses,pmAll.results.iterations(8).perfmet.guesses,...
    pmAll.results.iterations(9).perfmet.guesses,pmAll.results.iterations(10).perfmet.guesses];

confMatrix=confusionmat(guess,hat);

