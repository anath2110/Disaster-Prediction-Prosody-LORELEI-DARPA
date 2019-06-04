#Used for reading .MAT files
import scipy.io as sio
import h5py
#Python module dedicated to reading the mat files.


#MatfilesPath should have forward slashes
def readMat(matFilePath, x_variable_name, y_variable_name):
    try:
        matlabData = sio.loadmat(matFilePath)
        x_data = matlabData[x_variable_name]
        y_data = matlabData[y_variable_name]
    except:
        with h5py.File(matFilePath, 'r') as f:
            x_data = list(f[x_variable_name])
            y_data = list(f[y_variable_name])
    return (x_data,y_data)

def readListStruct(y_test_list_struct):
    
    annotations= []
    for struct in y_test_list_struct:
        annotations.append(struct[0][0][0][0][0])
    return annotations

def readListStructMatricies(y_test_list_struct):
    
    annotations= []
    for struct in y_test_list_struct:
        annotations.append(struct[0][0][0][0])
    return annotations

def readMatVariable(matFilePath, variable_name):
    matlabData = sio.loadmat(matFilePath)
    data = matlabData[variable_name]
    return data

def readStanceTestData(matFilePath, variable_name):
    matlabData = sio.loadmat(matFilePath)
    data = matlabData[variable_name]
    data = data[0]
    return data

def parseStanceFeatures(testData):
    stance_segment_features = []
    for segment in testData:
        segment_features = segment[0];
        
        stance_segment_features.append(segment_features)
    return stance_segment_features

def readStanceTestMatricies(x_test_list_struct, y_test_list_struct):
    all_x_patches = []
    all_y_patches = []
    y_test = readListStruct(y_test_list_struct)
    for i, stories in enumerate(x_test_list_struct):
        story = stories[0][0][0][0]
        
        for j, patches in enumerate(story):
            all_x_patches.append(patches)
            all_y_patches.append(y_test[i])
                 
    return (all_x_patches, all_y_patches)

def readStanceTestNames(x_test_list_struct):
    testStoryNames = []
    for storyStruct in x_test_list_struct:
        testStoryNames.append(storyStruct[0][0][0][3][0][0][0]) #3 to get the name of the test story, 0 contains the feature vs patch matrix
        
    return testStoryNames    

def parseStanceAnnotation(testData):
    stance_annotations = []
    for segment in testData:
        annotation = segment[4][0]; #Column 4 has the annotations, 0 to specify the row it is 0 because it's a 1 by 14 matrix
        
        stance_annotations.append(annotation)
    return stance_annotations

#2D array of [0] column being names of audios files, [1] column being list of time stamps, and [2] column having the prosodic features for every patch
#Rows are audio files/segments
#Returns a list of 2D arrays, each 2D array is a patch vs prosodic feature table. It is list since each element is a different segment
def readListStructDitaFormat(x_test_list_struct):
    audioFiles = []
    for audioFile in x_test_list_struct[0]:
        audioFiles.append(audioFile[2])  #2 because 3rd column 
    return audioFiles

def readListAudioNamesDitaFormat(x_test_list_struct):
    audioFiles = []
    for audioFile in x_test_list_struct[0]:
        audioFiles.append(audioFile[0][0]) #2 because 3rd column 
        
    return audioFiles