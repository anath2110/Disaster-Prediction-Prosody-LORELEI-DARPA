#Gerardo Cervantes
#University of Texas at El Paso

import numpy as np
import random
import math
from pathlib import Path
import statistics
import pandas as pandas
#Used to plots graphs in python
import matplotlib.pyplot as plt

#Keras Library for neural networks
from keras.models import Sequential, load_model
from keras.layers import Dense, Activation, Dropout
from keras.wrappers.scikit_learn import KerasRegressor
from keras import regularizers
from keras import optimizers

#Used to calculate the mean squared error
from sklearn.metrics import mean_squared_error

#Used for reading .MAT files
import scipy.io as sio

#Used for saving Neural Network Model
import h5py

#Used for running times
import time

from read_mat import *

from remove_nan_values import *

print('Finished importing libraries')


#The number of input nodes it usually len(x_train[0]) and the number of output nodes is usually len(y_train[0])
#nHidden nodes is how many hidden nodes you want to have, a good heuristic to use is it should be a number between nInputNodes and nOutputNodes
#Adds layers to the neural network.
def addDisasterNeuralNetworkLayers(neuralNetworkModel, numberInputNodes, numberOutputNodes, nHiddenNodes):
    
    #Input layer
    neuralNetworkModel.add(Dense(numberInputNodes, input_shape=(numberInputNodes,), activation = 'relu'))
    
    #neuralNetworkModel.add(Dense(nHiddenNodes, activation='relu', kernel_initializer='normal' ))
    
    #2 Hidden layers that use regularization, the 2nd hidden layer has hardcoded number of hidden nodes
    
    neuralNetworkModel.add(Dense(nHiddenNodes, activation='relu', kernel_initializer='normal', kernel_regularizer=regularizers.l2(0.01) ))
    neuralNetworkModel.add(Dense(70, activation='relu', kernel_initializer='normal', kernel_regularizer=regularizers.l2(0.01) ))
    
    #Output layer
    neuralNetworkModel.add(Dense(numberOutputNodes, kernel_initializer='normal', activation = 'sigmoid'))
    return neuralNetworkModel

#neuralNetworkModel is the NN model.  It should have layers and compile settings set before calling this function
#x_train and y_train is the training data it will train on;
#Kwargs, can be given optional arguments: x_test and y_test. The extra data it takes in is used as validation data to see how well the model does at predicting the given data
#Returns neural network after it has been trained with the training data
def trainNeuralNetwork(neuralNetworkModel, batch_size, nEpochs, x_train, y_train, **kwargs):
    if (('x_test' in kwargs) & ('y_test' in kwargs)):
        x_test = kwargs['x_test']
        y_test = kwargs['y_test']
        
        neuralNetworkModel.fit(x=x_train, y=y_train, batch_size=batch_size, epochs=nEpochs, verbose=1, callbacks=None, validation_data= (x_test,y_test) )
    else:
        neuralNetworkModel.fit(x=x_train, y=y_train, batch_size=batch_size, epochs=nEpochs, validation_split=10.0, verbose=1, callbacks=None)
    return neuralNetworkModel

#model is the neural network model that has had it's layers set and has been trained
#x_test is the input data of every segment you want to have predictions for
#Returns the segment-level predictions for each segment, predictions[0] will have a list with the predictions for each category (disasters or stances) for the first segment
def predictMultipleSegmentsAtSegmentLevel(model, x_test):
    predictions = []
    for audioFileProsFeat in x_test:
        segment_prosodic_features = np.array(audioFileProsFeat) 
        predictedStancesPatchLevel = model.predict(segment_prosodic_features, batch_size = 128, verbose = 1)
        
        #Mean of all the patches to get the predicted for the whole segment/audio file
        predictedStancesSegmentLevel = np.mean(predictedStancesPatchLevel, axis = 0)
        predictions.append(predictedStancesSegmentLevel)
    return predictions
        
#Find the individual MSE for every stance.  Find the MSE for Bad implication, good...
#Return is the MSE for every stance [0] contains good implication, ...
def findStancesMSE(annotations, predictions):
    annotations = np.transpose(annotations)
    predictions = np.transpose(predictions)
    mse_stances = []
    
    for i,stance_predictions in enumerate(predictions):
        
        mse = mean_squared_error(annotations[i], stance_predictions)
        mse_stances.append(mse)
    return mse_stances

#Saves the neural network model, including the configuration settings and the weights
def saveNeuralNetworkModel(model, fileDir):
    model.save(fileDir)
    
#Loads the neural network model, including the configuration settings and the weights
def loadNeuralNetworkModel(fileDir):
    model = load_model(fileDir)
    return model

#Creates a JSON file from the predictions and audio names.  Outputs into the format that NIST requires
def createJSON(predictions, audioNames, savePath):
    import json;
    jsonPredictions = []
    from collections import OrderedDict
    
    disaster_names = getDisasterNames()
    for j,segment in enumerate(predictions):
        typesOfDisasters = []
        for i, segmentDisasterScore in enumerate(segment):
            #Ordered dictionary, so that DocumentID, Type, and TypeConfidence keep that order
            fileDisaster = OrderedDict()
            audioName = audioNames[j];
            fileDisaster["DocumentID"] = audioName[:-3]
            fileDisaster["Type"] = disaster_names[i]
            fileDisaster["TypeConfidence"] = round(segmentDisasterScore,7)
            
            typesOfDisasters.append(fileDisaster)
        #Sorts the disasters in descending order based on their typeConfidence and then adds them to the list which we will convert to JSON
        typesOfDisasters.sort(key = lambda x: x["TypeConfidence"], reverse = True)
        
        for disaster in typesOfDisasters:
            jsonPredictions.append(disaster)
    print(json.dumps( jsonPredictions,indent=4, sort_keys=True  ))
    with open(savePath + '.json', 'w') as outfile: #TODO when saving json file automatically append current date to file name
        json.dump(jsonPredictions, outfile, indent=4, sort_keys=True)
 

#Takes in two paths to different mat files: one for training data, and the other for testing data
#Takes in a parameter to save the neural network settings and weights to a specified path
#saveJSONPath is the path where you want to save the JSON file output to. 
def disasterPredictions(trainMatPath,testMatPath, saveModelDir, saveJSONPath):
    try:
        (x_train,y_train) = readMat(trainMatPath, 'refFeatures', 'refTypes')
        readMatVariable(testMatPath, 'test') #Reads to see if testMat files is found and can be read, if not stops the program, this is done later on so no errors appear after training (long process)
    except:
        
        print("Error reading the file, on directory: ")
        print(trainMatPath)
        print(testMatPath)
        return
    

    #(x_train, y_train) = removeNanValues(x_train,y_train) #Might be needed if features have NaN values, by default it is off, so that we can find if they have NaN, loss should be NaN if has NaN features
    
    #Done because x_train and y_train and lists of ndarray before this, you will get error if not done
    x_train = np.array(x_train)
    y_train = np.array(y_train) 
    
    x_train = np.transpose(x_train)
    y_train = np.transpose(y_train)
    
    print(len(x_train))
    print(len(x_train[0]))
    print(len(y_train))
    print(len(y_train[0]))
    nInputNodes = len(x_train[0])
    nOutputNodes = len(y_train[0])
    
    model = Sequential()
    addDisasterNeuralNetworkLayers(model, nInputNodes, nOutputNodes, 60)
    model.compile(loss='mean_squared_error', optimizer='rmsprop')
    #For disaster types - 70 nodes and 60 nodes as hidden layers with 300 epochs and rmsprop have seemed to work well.
    nEpochs = 300
    batchSize = 128
    
    trainNeuralNetwork(model, batchSize, nEpochs, x_train, y_train)
    
    #Save the NN model
    saveNeuralNetworkModel(model, saveModelDir)
    
    #Loads the model from path and predicts the test data and saves it to a JSON file
    disasterPredictionsWithModel(saveModelDir, testMatPath, saveJSONPath)
   
def disasterPredictionsWithModel(loadModelDir,testMatDir, saveJSONPath):
    x_test_list_struct = readMatVariable(testMatDir, 'test')
    try:
        x_test_list_struct = readMatVariable(testMatDir, 'test')
    except:
        print("Error reading the file, on directory: ")
        print(testMatDir)
        return
    
    x_test = readListStructDitaFormat(x_test_list_struct)
    audioNames = readListAudioNamesDitaFormat(x_test_list_struct)
    (x_test, audioNames) = removeNanValuesFromSegments(x_test, audioNames)
    
    model = loadNeuralNetworkModel(loadModelDir)
    
    predictions = predictMultipleSegmentsAtSegmentLevel(model, x_test)
    
    predictionsAsList = np.array(predictions).tolist()
    sio.savemat(saveJSONPath + '.mat', mdict={'normalizedEstimates': (predictionsAsList), 'basenames': audioNames})
#    createJSON(predictionsAsList,audioNames, saveJSONPath)
    
#Returns a list of disaster names
def getDisasterNames():
    
    return ['Civil Unrest or Wide-spread Crime',
     'Elections and Politics',
     'Evacuation',
     'Food Supply',
     'Infrastructure',
     'Medical Assistance',
     'Shelter',
     'Terrorism or other Extreme Violence',
     'Urgent Rescue',
     'Utilities, Energy, or Sanitation',
     'Water Supply']



#Predicts multiple disasters that are in the disaster_files folder
def predictMultipleDisasters():
    import os
    directory = "Disaster_files/"
    i = 0;
    for root, dirs, files in os.walk(directory):
        print("Attempting directory: ")
        print(root)
        
        #If statement done so only a few folders can taken into account.  (i%11==2) to only get the testing on arab 
        if ((i % 11 == 2) & (i > 86)): #12 for arab-arab
            disasterPredictions(root + "/refdata.mat", root + '/testdata.mat', root + '/model300Epochs2LayersRegularizationAt01', root + '/NNPredictions300Epochs2LayersRegularizationAt01.json')
        i += 1

#predictMultipleDisasters()
#disasterPredictions('MAT_files/refdata.mat', 'MAT_files/testData.mat', 'MAT_files/testResults.mat', 'MAT_files/model', 'JSONOutputs/data.json')
    
#root = "Disaster_files/VIE_CHN"
#lang = "TUR"
#AMH, RUS, HUNGARY, FARSEE
#disasterPredictionsWithModel("Disaster_NN_Models/" + lang + "_ARA_model300Epochs2LayersRegularizationAt01", root + '/testdatav7.mat', root + '/testResults.mat', root + '/' + lang + 'NNPredictions300Epochs2LayersRegularizationAt01.json')

#disasterPredictions("Disaster_files/RUS_FAS" + "/refdatav7.mat", root + '/testdatav7.mat', root + '/testResultsVie100.mat', root + '/Vie100model300Epochs2LayersRegularizationAt01', root + '/Vie100_CHN_NNPredictions300Epochs2LayersRegularizationAt01.json')

#disasterPredictions("Disaster_files/VIE_FAS" + "/refdata.mat", root + '/testdatav7.mat',"Disaster_files/VIE_FAS" +  '/Rus80model100Epochs2LayersRegularizationAt01', root + '/Rus80_CHN_NNPredictions300Epochs2LayersRegularizationAt01.json')
#disasterPredictions('Disaster_files/AMH_IL6_EVAL/refdata.mat', 'Disaster_files/AMH_IL6_EVAL/testdata.mat', 'Disaster_files/AMH_IL6_EVAL/trainAMHTestOnIL6', 'Disaster_files/AMH_IL6_EVAL/trainAMHTestOnIL6.json')
disasterPredictions('C:/ANINDITA/Lorelei_2018/Lorelei_2018/EvaluationJuly\'18/Results/KNNEvaluatioJuly18/IL9/univTrain_IL9_SetE/refdataSF.mat', 'C:/ANINDITA/Lorelei_2018/Lorelei_2018/EvaluationJuly\'18/Results/KNNEvaluatioJuly18/IL9/univTrain_IL9_SetE/testdataSF.mat', 'C:/ANINDITA/Lorelei_2018/Lorelei_2018/EvaluationJuly\'18/Results/KNNEvaluatioJuly18/IL9/univTrain_IL9_SetE/NNunivTrain_IL9SetE', 'C:/ANINDITA/Lorelei_2018/Lorelei_2018/EvaluationJuly\'18/Results/KNNEvaluatioJuly18/IL9/univTrain_IL9_SetE/NNunivTrain_IL9SetE')
#disasterPredictions('Disaster_files\BengEval_BengEval/refdataUrgency.mat', 'Disaster_files\BengEval_BengEval/testdataUrgency.mat', 'Disaster_files\BengEval_BengEval/NNtrainBengUrgency', 'Disaster_files\BengEval_BengEval/NNtrainBengUrgency')

#Should only be used at the end after being done using tensorflow, closes the TensorFlow session, it's a bug in tensorflow
#That can occasionally produce the error: python nonetype object is not callable. session.py
import gc; gc.collect()