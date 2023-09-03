import os
import cv2
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Flatten
from sklearn.model_selection import train_test_split

base_model = VGG16(weights='imagenet', include_top=False)



def getroi(video_file):
    name = video_file.lstrip("output_").rstrip(".mp4")

    return [449, 17, 278, 211]





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

directories = [('Hits/', 1), ('Misses/', 0)]
for directory, label in directories:
    for video_file in os.listdir(directory):
        roi = getroi(video_file)
        features = extract_features_from_video(os.path.join(directory, video_file),roi=roi)
        if features is not None:
            X.append(features)
            y.append(label)

X_train, X_test, y_train, y_test = train_test_split(np.array(X), np.array(y), test_size=0.2, random_state=42)

# classify the stuff
model = Sequential([
    Dense(512, activation='relu', input_shape=(X_train.shape[1],)),
    Dropout(0.5),
    Dense(256, activation='relu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid')
])

model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
model.fit(X_train, y_train, epochs=10, batch_size=32, validation_data=(X_test, y_test))

# please over 80 percent
loss, accuracy = model.evaluate(X_test, y_test)
print("Accuracy:", accuracy)


