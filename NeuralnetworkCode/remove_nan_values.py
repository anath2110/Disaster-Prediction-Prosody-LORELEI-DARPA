#Gerardo Cervantes
#University of Texas at El Paso

import numpy as np

def countNans(data):
    count_nans = 0
    for patch in data:
        for feature in patch:
            if(np.isnan(feature)):
                count_nans += 1
    
    return count_nans

#Removes the patches in the training matrices that have nan values from both x_train and y_train and returns them
def removeNanValues(x_train, y_train):
    
    x_train_removed_nans = []
    y_train_removed_nans = []
    for i, patch in enumerate(x_train):
        patchHasNan = False
        for feature in patch:
            if np.isnan(feature): #Can be a little more efficient by stop search early instead of searching all feats even after finding 1 nan
                patchHasNan = True
                break;
        #If patch doesn't have nan, then add it to the list
        if(patchHasNan == False):
            x_train_removed_nans.append(patch)
            y_train_removed_nans.append(y_train[i])
            patchHasNan = False
            
    return (x_train_removed_nans, y_train_removed_nans)
    
def removeNanValuesFromSegments(x_test, segment_names):
    x_test_without_nans = []
    valid_segment_names = []
    
    for i,story in enumerate(x_test):
        revised_story_without_nans = []
        for patch in story:
            patch_has_nan = False
            for feature in patch:
                if np.isnan(feature):
                    patch_has_nan = True
                    break;
            #If patch doesn't have nan
            if (patch_has_nan == False):
                revised_story_without_nans.append(patch)
            patch_has_nan = False
        
        #If the story wasn't full of only patches that had nan, we add story and name of story to revised lists without nan values
        if len(revised_story_without_nans) != 0:
            x_test_without_nans.append(revised_story_without_nans)
            valid_segment_names.append(segment_names[i])
        
        
    
    return (x_test_without_nans,valid_segment_names);   
          