# chating_app

A real-time chat application built with Flutter, inspired by messaging platforms like Messenger or Zalo.

## Description

**chating_app** is a Flutter-based messaging app that supports real-time chatting, Google Sign-In authentication, file sharing, emoji support, local push notifications. The goal is to deliver a seamless and familiar chat experience on mobile devices.

## Technologies Used

- Flutter (Dart)
- Firebase Auth (Google authentication)
- Google Sign-In
- Dio & HTTP (API calls)
- Firebase Core/Web
- Shared Preferences (token & session storage)
- flutter_local_notifications (local notifications)
- flutter_sound, permission_handler (voice messaging/calling)
- file_picker, image_picker (file and image selection)
- emoji_picker_flutter (emoji integration)
- easy_localization (multi-language support)
- provider (state management)

## Integration

- Google Sign-In with Firebase for authentication  
- RESTful APIs for syncing messages, groups, and user data  
- File upload: send images, documents  
- Push notifications for incoming messages

## Role

As the main developer, responsibilities include:

- Developing UI/UX fully in Flutter  
- Integrating backend APIs and Firebase services  
- Managing localization, file handling, API communication, and app security  

## Database

The backend uses **Amazon Web Services (AWS)** for data storage and management, likely involving services such as:

- **Amazon DynamoDB** for storing user and chat data  
- **Amazon S3** for file and media uploads

## Backend

This app does not contain backend logic in Flutter itself. The backend (hosted separately) is assumed to be built with:

-  **Node.js (Express)**
- Responsible for authentication, message history, user and group management

## Frontend

- Fully developed using Flutter  
- Multi-screen support: login, chat, groups, profile, media  
- Rich features: emoji picker, file/voice messaging, Google login  
- Optimized for Android platform (with potential iOS support)

---

Feel free to contribute or fork this project for further improvements!
