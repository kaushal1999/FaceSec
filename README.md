# FaceSec


## Project Overview & Motivation

My project is a Mobile app for criminal detection based on face recognition. Through this App, I wanted to show the use case of face recognition & as security is a very fit use case of face recognition, so I built this project. It detects criminals in a live stream from the camera & in given images also. Whenever any criminal is caught, it plays an alarming sound & we can also see the list of criminals detected in that session with their details like id, name & image. Whenever the user starts the App, he is shown an animated splash screen & then taken to the homepage. On the homepage, three buttons are there. First for criminal addition, second for detection & 3rd for seeing already added criminals. The app user can add new criminals to the list of already existing criminals. User can also view all the added criminals in a single place with their details & can delete entry any entry he wants. He can also delete all the entries together if he wants to. On the page where users can see all added criminals, each entry is in the form of an expansion tile. We can see an image of any particular criminal by expanding that tile & delete that entry by sliding that tile left or right.

Two modes are available for detection. The first is to detect in any image & second is using the camera. In-camera mode, all faces on the screen are marked by a rounded rectangle around them & if any criminal is present, his name is shown above that rectangle around his face. I have also handled some cases separately. Some of them are:
1. if the user selects an image for detection without any face in it, then the App shows a dialogue that no face is detected in the selected image.
2. While new criminal addition, if the user tries to add a criminal with a previously used criminal id, then the App shows him two options: the first to change the id & second one to replace the existing criminal.
3. If the user denies the camera permission, then App asks for permission again. If the user denies permission permanently, the App shows the dialogue that he has to change permissions in-app settings.


I have developed this app using flutter SDK. For face detection, I have used the face detection package from google ml kit & for face recognition purpose, I have used the mobile facenet model, which is a TensorFlow model.
## Screenshots

<a href="https://ibb.co/C1S9q7m"><img src="https://i.ibb.co/ngK1Tc6/second.jpg" alt="second" border="0" width="300"></a>


<a href="https://ibb.co/wNNjKxk"><img src="https://i.ibb.co/RppdCVF/first.jpg" alt="first" border="0" width="300"></a>


<a href="https://ibb.co/K9fyvxd"><img src="https://i.ibb.co/wKP6mhV/3rd.jpg" alt="3rd" border="0" width="300"></a>


<a href="https://ibb.co/fvfbzHp"><img src="https://i.ibb.co/QdLZ3MN/4rth.jpg" alt="4rth" border="0" width="300"></a>

## Tech Stack

**Flutter:** For help getting started with Flutter, view our online documentation, which offers tutorials, samples, guidance on mobile development, and a full API reference.

https://flutter.dev/docs

**Tensorflow lite:** TensorFlow Lite is an open source deep learning framework for on-device inference.

https://www.tensorflow.org/lite

**Flutter + Tensrorflow lite = tflite_flutter package:** TensorFlow Lite plugin provides a dart API for accessing TensorFlow Lite interpreter and performing inference. It binds to TensorFlow Lite C API using dart:ffi.


https://pub.dev/packages/tflite_flutter/install

## Getting Started Guide

### (a) Installation prerequisites:

 1. An android device (Android 6 or above).  
 2. Stable release Flutter SDK version 2.10.1 (Important Note: Don't use other versions to avoid version conflicts among dependencies.)  
 3. Android Studio installed  
 4. Vs code (android studio can also be used)

### (b) Running the project locally:

1. Download the zip from the GitHub repository  
2. extract it to any folder you wish  
3. open that folder in vs code or android studio  
4. run 'flutter pub get' command to get required dependencies (Internet required)  
5. Connect any android device with your laptop or desktop (make sure USB debugging is allowed on the connected phone).  
6. Now use 'flutter run --release' command to install the app on the connected device.  

### (c) Demo video:

https://youtu.be/8Ejdldwcluo


## Useful resuorces & links

Flutter official site: https://flutter.dev/   

Flutter packages: https://pub.dev/

