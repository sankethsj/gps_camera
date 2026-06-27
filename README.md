# GPS Camera

GPS Camera is a Flutter application that combines camera capture with live GPS and location-based overlays. It lets you take photos while viewing location metadata such as coordinates, altitude, and compass-style overlay information directly in the camera view.

## Features

- Capture photos from the device camera
- Display live GPS location data during camera use
- Show camera overlay information such as coordinates and altitude
- Save and review captured photos with metadata
- Configure app settings for camera and overlay behavior

## Planned Improvements

- Improve the visual design of the camera overlay
- Add place names and reverse geocoding from location data
- Support multiple overlay designs and themes
- Refine metadata display for better readability on screen

## Getting Started

1. Install Flutter and set up your development environment.
2. Clone the repository.
3. Run the following commands:

   ```bash
   flutter pub get
   flutter run
   ```

## Project Structure

- lib/screens: app screens such as camera, gallery, and settings
- lib/services: camera, location, and settings services
- lib/widgets: reusable UI components and overlay widgets
- lib/models: data models for settings and photo metadata
