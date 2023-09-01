import os
import cv2
import numpy as np
from keras.applications.vgg16 import VGG16, preprocess_input
from keras.preprocessing import image
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score

base_model = VGG16(weights='imagenet', include_top=False)

def extract_features_from_video(video_path, roi=None, n_frames=5):
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    frames_step = total_frames // n_frames
    frames = []
    
    for i in range(n_frames):
        cap.set(cv2.CAP_PROP_POS_FRAMES, i * frames_step)
        ret, frame = cap.read()
        if not ret:
            continue
        
        if roi:
            frame = frame[roi[1]:roi[1]+roi[3], roi[0]:roi[0]+roi[2]]
        
        frame = cv2.resize(frame, (224, 224))
        frames.append(frame)
    
    cap.release()

    if len(frames) == 0:
        return None

    frames = np.array(frames)
    frames = preprocess_input(frames)
    features = base_model.predict(frames)

    return features.reshape(features.shape[0], -1).mean(axis=0)


X, y = [], []

directories = [('makes/', 1), ('misses/', 0)]
for directory, label in directories:
    for video_file in os.listdir(directory):
        features = extract_features_from_video(os.path.join(directory, video_file))
        if features is not None:
            X.append(features)
            y.append(label)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

clf = SVC(kernel='linear', C=1, probability=True)
clf.fit(X_train, y_train)

y_pred = clf.predict(X_test)
print("Accuracy:", accuracy_score(y_test, y_pred))
