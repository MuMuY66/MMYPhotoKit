### **MMYPhotoKit**

A lightweight, on-device iOS toolkit for intelligent photo processing, featuring high-performance background removal and advanced face detection.

### **About The Project**

Tired of slow, expensive server-side image processing APIs? So were we.

MMYPhotoKit is a powerful and lightweight iOS framework designed to perform complex image processing tasks directly on the user's device, with no need for an internet connection. It leverages the speed of the NCNN deep learning framework and the robustness of OpenCV to provide a seamless and private experience for your users.

Think of it as your on-device Swiss Army knife for common but complex photo tasks. At its core, it offers two main capabilities:

* **Background Removal:** Using a pre-trained MobileNetV2 model, it can accurately segment a person from an image and replace the background with a solid color of your choice.

* **Face Analysis:** Using Apple's native Vision framework, it can detect faces, count them, and even determine if the subject is facing the camera.

All of this happens in a blink of an eye, right on the iPhone or iPad, ensuring user data remains private and your app works flawlessly offline.

![IMG_1713](https://github.com/user-attachments/assets/fd714ee5-386e-4b8d-bc76-af9b34a31b05)
![IMG_1714](https://github.com/user-attachments/assets/5a9e9a9a-1427-4919-91ba-a9dd8dc745d8)

(A quick demo of the on-device background removal.)

### **Key Features**

* **🚀 On-Device Background Removal:** Employs a MobileNetV2 model via NCNN to accurately segment portraits and replace the background. No API calls, no latency.

* **👨‍👩‍👧 Advanced Face Detection:** Utilizes Apple's Vision framework to not only find faces but also count them and verify a frontal pose—perfect for profile picture validation.

* **⚡️ High-Performance C++ Core:** The heavy lifting is done in a C++ backend powered by NCNN and OpenCV, ensuring maximum performance and efficiency.

* **🔒 Privacy-First:** All processing happens locally. No images or user data ever leave the device.

* **🎨 Customizable Backgrounds:** Easily specify any solid UIColor to be applied as the new background after segmentation.

* **🧩 Simple Objective-C API:** A clean and straightforward Objective-C wrapper makes integration into any iOS project a breeze.

### **Built With**

This project is built upon a foundation of powerful, industry-standard technologies:

* **NCNN** - A high-performance neural network inference framework optimized for mobile platforms.

* **OpenCV** - The leading open-source library for computer vision and image processing.

* **Vision Framework** - Apple's native framework for powerful computer vision tasks.

* Objective-C / C++

### **Prerequisites**

* Xcode 12.0 or later

* iOS 11.0 or later

### **Functional Analysis: Deconstructing the Codebase**

MMYPhotoKit's architecture is structured to efficiently bridge Objective-C with high-performance C++ components, specifically integrating OpenCV and NCNN.

#### **1. Computational Core: C++ Implementation (`MMYCVPhoto.hpp` & `MMYCVPhoto.cpp`)**
This segment houses the high-performance image processing logic utilizing C++, OpenCV, and NCNN.
*   **`MMYCVPhoto.hpp`** declares the `MMYCVPhoto` C++ class, which serves as the interface for the underlying image processing operations. It includes essential headers for NCNN (e.g., `net.h`, `benchmark.h`) and OpenCV (`opencv2/core.hpp`, `opencv2/imgproc.hpp`), signifying its reliance on these frameworks.
*   **`MMYCVPhoto.cpp`** contains the implementation details:
    *   **Neural Network Object:** A `static ncnn::Net bgnet;` object is declared, representing the neural network responsible for background segmentation.
    *   **Model Initialization (`modelInit`)**: This method is critical for configuring and loading the pre-trained `mobilenetv2` model. It sets NCNN `ncnn::Option` parameters for optimization, such as `opt.lightmode = true` and `opt.num_threads = 4`, indicating a configuration optimized for mobile execution. It then loads the model's structure (`.param` file) and weights (`.bin` file) into `bgnet`. A return value of `false` indicates a failure in loading either component.
    *   **Photo Processing (`photoProcess`)**: This method executes the background removal pipeline:
        *   It accepts raw pixel data (`uint8_t* pixel`), image dimensions (`width`, `height`), and an array of integers representing the desired `background` color.
        *   Input pixel data (RGBA format) is converted into an `ncnn::Mat` in RGB format.
        *   The image is then resized to `512x512` pixels using `ncnn::Mat::from_pixels_resize`.
        *   **Normalization**: A crucial step involves normalizing the pixel values of the resized image using `in_resize.substract_mean_normalize(meanVals, normVals)` with specific mean and norm values (`127.5f` and `0.0078431f` respectively). This normalization aligns the input data with the training parameters of the neural network.
        *   An `ncnn::Extractor` is instantiated from `bgnet`, the normalized input is fed via `ex.input("input", in_resize)`, and the segmentation mask is extracted as "output" via `ex.extract("output", out)`.
        *   The resulting segmentation mask (`out`) is then resized back to the original image dimensions using bilinear interpolation (`ncnn::resize_bilinear`) to generate the `alpha` mask.
        *   **Pixel Blending**: The core blending operation iterates through each pixel of the image. For each pixel, a new color is computed by blending the original pixel's color (`rgb.at<cv::Vec3b>(i, j)`) with the new `background` color based on the corresponding `alpha_` value from the generated mask. The formula used is `original_pixel * alpha_ + (1 - alpha_) * background_color`.
        *   Finally, the method manages memory by releasing all temporary `ncnn::Mat` and `cv::Mat` objects. The blended `cv::Mat` is returned.

#### **2. Orchestration and iOS Integration (`MMYPhotoKitManager.m`)**
This Objective-C class acts as the primary interface between the iOS application and the underlying C++/OpenCV/NCNN computational layer.
*   **Initialization (`init`)**: Upon instantiation, the manager attempts to locate and load the `mobilenetv2` model files (`.bin` and `.param`) from the `ModelRes.bundle` within its own framework. It then calls the `modelInit` method of the `MMYCVPhoto` C++ object (`self->photo`). A `self.isLoaded` property tracks the success of model loading.
*   **Deallocation (`dealloc`)**: When the `MMYPhotoKitManager` instance is released, its `dealloc` method ensures the proper destruction of the C++ `MMYCVPhoto` object by calling its destructor (`self->photo->~MMYCVPhoto()`), preventing memory leaks.
*   **Face Frontality Assessment (`isFaceFrontal`)**: This private method utilizes **Apple's Vision framework** to evaluate the orientation of a detected face. It extracts `roll`, `yaw`, and `pitch` values from a `VNFaceObservation` and converts them to degrees. A face is considered "frontal" if its `rollDegrees`, `yawDegrees`, and `pitchDegrees` are all within an `acceptableRange` of **+/- 10.0 degrees**.
*   **Face Occupancy Check (`isFaceOccupyingMajorSpace`)**: This private method calculates the proportional area a detected face occupies within the image. While present, its direct application within the public `detectFace` method is not explicitly shown in the provided source. It also includes a check for `isFaceFrontal` and returns `true` if the face area is less than 50% and the angle is valid.
*   **Face Detection Logic (`detectFace`)**: This public method takes a `UIImage`, converts it to a `CIImage`, and uses `VNDetectFaceRectanglesRequest` from the Vision framework to identify faces. The completion handler analyzes the `request.results` to determine the appropriate `MMYFaceStatus`:
    *   It assigns **`MMY_FS_NONE`** if no faces are found.
    *   It assigns **`MMY_FS_ONE`** if exactly one frontal face is detected by calling `isFaceFrontal`.
    *   It assigns **`MMY_FS_NOFRONTAL`** if one face is detected but `isFaceFrontal` indicates it is not frontal.
    *   It assigns **`MMY_FS_EXCESSIVE`** if more than one face is detected.
    *   Error logging is performed if the Vision request fails.
*   **Image Processing Bridge (`photoProcess`)**: This method orchestrates the background removal process:
    *   It first verifies that the NCNN model has been successfully loaded (`!self.isLoaded`).
    *   The input `UIImage` is converted into a raw `unsigned char* rgba` pixel buffer using **Core Graphics** (`CGContextRef`).
    *   The `backgroundColor` (an `UIColor`) is decomposed into its individual RGB integer components.
    *   The raw pixel data, dimensions, and background color are then passed to the C++ `self->photo->photoProcess` method.
    *   Upon receiving the processed `cv::Mat` from the C++ layer, the manager converts it back into an `UIImage` suitable for iOS display. This conversion involves creating a `CGDataProviderRef`, `CGColorSpaceRef`, and `CGImageRef`.
    *   Thorough cleanup of all temporary Core Graphics and OpenCV resources is performed, including releasing `CGContextRef`, `CGImageRef`, `CGDataProviderRef`, `CGColorSpaceRef`, `CGColorSpaceRef` (from `kCGColorSpaceSRGB`), and deleting the `rgba` pixel buffer.

### **Usage Example: MMYPhotoKitSimpleDemo**
We've included a simple demo project, **`MMYPhotoKitSimpleDemo`**, to show you how to integrate and use the library in a modern SwiftUI application. It's the quickest way to see **`MMYPhotoKit`** in action.

First, an **`AppManager`** class acts as the view model, holding the state and interfacing with **`MMYPhotoKitManager`**.

The **`ContentView`** provides the UI, displaying the original and processed images, along with a button to trigger the background removal.

### **Potential Applications**

This library is a perfect fit for a variety of applications, including:

* **ID Photo Apps:** Automatically replace the background of a user's photo with a solid white, blue, or red background as required for official documents.

* **E-commerce Product Photos:** Allow users to quickly clean up product images by removing distracting backgrounds.

* **Creative Photo Editors:** Use it as a foundational tool for creating stickers, memes, or artistic compositions.

* **Profile Picture Generators:** Ensure all user profile pictures are clean, professional, and contain a valid face.

### **Roadmap & Potential Extensions**

MMYPhotoKit provides a solid foundation. Here are some ideas for future development:

* **Video Processing:** Extend the functionality to support real-time background removal in video streams.

* **Advanced Masking:** Expose the alpha mask to allow for more advanced effects, like blurred or transparent backgrounds.

* **Swift Support:** Create a Swift-friendly wrapper to improve integration with modern iOS projects.

* **Additional Models:** Integrate other models for tasks like style transfer, super-resolution, or object detection.

License

Distributed under the MIT License. See LICENSE for more information.
