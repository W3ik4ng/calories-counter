import 'package:charts_flutter/flutter.dart' as charts;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'ui/fancy_card.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:async';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

enum Options { none, imagev5, imagev8, frame }

late List<CameraDescription> cameras;

/// Homepage definitions
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late FlutterVision vision;
  Options option = Options.none;
  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    _initializeKcalDays();
    _startMidnightReset();
  }

  @override
  void dispose() async {
    super.dispose();
    await vision.closeYoloModel();
    _timer.cancel();
  }

  List<KcalDay> kcalDays = [
    KcalDay(
      DateTime(2024, 11, 1), // 1st October 2024
      [
        FoodItem("Apple", 52, 100, FoodType.fruits), // 52 cal per 100g
        FoodItem("Banana", 89, 120, FoodType.fruits), // 89 cal per 100g
      ],
    ),
    KcalDay(
      DateTime(2024, 11, 2), // 2nd October 2024
      [
        FoodItem("Chicken Breast", 165, 150, FoodType.meat), // 165 cal per 100g
        FoodItem("Rice", 130, 200, FoodType.starch), // 130 cal per 100g
      ],
    ),
    KcalDay(
      DateTime(2024, 11, 5), // 5th October 2024
      [
        FoodItem("Salmon", 208, 180, FoodType.meat), // 208 cal per 100g
        FoodItem("Broccoli", 55, 80, FoodType.vegetables), // 55 cal per 100g
      ],
    ),
    KcalDay(
      DateTime(2024, 11, 10), // 10th October 2024
      [
        FoodItem("Yogurt", 59, 150, FoodType.other), // 59 cal per 100g
        FoodItem("Granola", 471, 50, FoodType.starch), // 471 cal per 100g
      ],
    ),
    KcalDay(
      DateTime(2024, 11, 15), // 15th October 2024
      [
        FoodItem("Eggs", 155, 120, FoodType.meat), // 155 cal per 100g
        FoodItem("Spinach", 23, 100, FoodType.vegetables), // 23 cal per 100g
      ],
    ),
    KcalDay(
      DateTime(2024, 11, 20), // 20th October 2024
      [
        FoodItem("Burger", 295, 200, FoodType.meat), // 295 cal per 100g
        FoodItem("Fries", 365, 150, FoodType.starch), // 365 cal per 100g
      ],
    ),
  ];

  late Timer _timer;

  void _initializeKcalDays() {
    DateTime today = DateTime.now();
    KcalDay? todayKcalDay = kcalDays.firstWhere(
      (kcalDay) => isSameDay(kcalDay.day, today),
      orElse: () => KcalDay(today, []),
    );

    if (todayKcalDay.foodItems.isEmpty) {
      setState(() {
        kcalDays.add(todayKcalDay);
      });
    }
  }

  // Start the timer to reset at midnight
  void _startMidnightReset() {
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (DateTime.now().hour == 0 && DateTime.now().minute == 0) {
        _addNewDay();
      }
    });
  }

  // Add a new day to the KcalDay list at midnight
  void _addNewDay() {
    DateTime now = DateTime.now();
    if (kcalDays.isEmpty || !isSameDay(kcalDays.last.day, now)) {
      setState(() {
        kcalDays.add(KcalDay(now, []));
      });
    }
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Function to add a food item to today's list
  void addFoodItem(FoodItem food) {
    DateTime today = DateTime.now();
    KcalDay? todayKcalDay = kcalDays.firstWhere(
      (kcalDay) => isSameDay(kcalDay.day, today),
      orElse: () => KcalDay(today, []),
    );

    setState(() {
      todayKcalDay.foodItems.add(food);
    });
  }

  void removeFoodItem(FoodItem food) {
    DateTime today = DateTime.now();
    KcalDay todayKcalDay = kcalDays.firstWhere(
      (kcalDay) => isSameDay(kcalDay.day, today),
      orElse: () => KcalDay(today, []),
    );

    setState(() {
      todayKcalDay.foodItems.remove(food); // Remove food item from the list
    });
  }

  // Get today's food items to pass to the widgets
  List<FoodItem> getTodaysFoodItems() {
    DateTime today = DateTime.now();
    KcalDay? todayKcalDay = kcalDays.firstWhere(
      (kcalDay) => isSameDay(kcalDay.day, today),
      orElse: () => KcalDay(today, []),
    );
    return todayKcalDay.foodItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: task(option),
      appBar: null,
      floatingActionButton: SpeedDial(
        //margin bottom
        icon: Icons.menu, //icon on Floating action button
        activeIcon: Icons.close, //icon when menu is expanded on button
        backgroundColor: Colors.pink, //background color of button
        foregroundColor: Colors.white, //font color, icon color in button
        activeBackgroundColor:
            Colors.deepPurpleAccent, //background color when menu is expanded
        activeForegroundColor: Colors.white,
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        buttonSize: const Size(56.0, 56.0),
        children: [
          SpeedDialChild(
            //speed dial child
            child: const Icon(Icons.video_call),
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            label: 'Live Detection',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.frame;
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera),
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            label: 'Vietnamese Food',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.imagev8;
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera),
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            label: 'Image Detection',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.imagev5;
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.home),
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            label: 'Home',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.none;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget task(Options option) {
    if (option == Options.frame) {
      return YoloVideo(vision: vision);
    }
    if (option == Options.imagev5) {
      return YoloImageV5(vision: vision);
    }
    if (option == Options.imagev8) {
      return YoloImageV8(vision: vision);
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TodayCounter(
            foodItems: getTodaysFoodItems(),
            addFoodItem: addFoodItem,
            removeFoodItem: removeFoodItem,
          ),
          TodayStats(foodItems: getTodaysFoodItems()),
          // Define a height for the graph
          KcalGraph(
            kcalDays: kcalDays,
          ),
        ],
      ),
    );
  }
}

Future<int?> readCalForDish(String name) async {
  DatabaseReference dishesRef = FirebaseDatabase.instance.ref().child("dishes");

  // Reference to the dish in the database
  DatabaseReference dishRef = dishesRef.child(name);

  // Fetch the data from Firebase
  DataSnapshot snapshot = await dishRef.get();

  // Check if the dish exists and get the cal value
  if (snapshot.exists) {
    var dishData =
        snapshot.value as Map; // The value is now a Map with multiple fields
    int cal = dishData["cal"]; // Read the 'cal' value
    return cal;
  } else {
    debugPrint("No data found for '$name'.");
    return null;
  }
}

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  const YoloVideo({super.key, required this.vision});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  bool isCapturing = false;
  int _seclectedCameraIndex = 0;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  String result = "";
  File? captureImage;

  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    // controller = CameraController(cameras[0], ResolutionPreset.low);
    // controller.initialize().then((value) {
    //   loadYoloModel().then((value) {
    //     setState(() {
    //       isLoaded = true;
    //       isDetecting = false;
    //       yoloResults = [];
    //     });
    //   });
    //   if (!mounted) {
    //     return;
    //   }
    // });
    init();
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
        });
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
  }

  void _toggleFlashLight() {
    if (_isFlashOn) {
      controller.setFlashMode(FlashMode.off);
      setState(() {
        _isFlashOn = false;
      });
    } else {
      controller.setFlashMode(FlashMode.torch);
      setState(() {
        _isFlashOn = true;
      });
    }
  }

  void _switchCamera() async {
    await controller.dispose();
    if (_seclectedCameraIndex == 0) {
      _seclectedCameraIndex = 2;
    } else {
      _seclectedCameraIndex = 0;
    }

    _initCamera(_seclectedCameraIndex);
  }

  Future<void> _initCamera(int cameraIndex) async {
    controller =
        CameraController(cameras[cameraIndex], ResolutionPreset.medium);
    try {
      await controller.initialize();
      setState(() {
        if (cameraIndex == 0) {
          _isFrontCamera = false;
        } else {
          _isFrontCamera = true;
        }
      });
    } catch (e) {
      debugPrint("Error message: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  void capturePhoto() async {
    controller.takePicture().then((value) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageDisplayWidget(
            imagePath: value.path,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(
            controller,
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size),
        topPanel(),
        bottomPanel(),
        // Positioned(
        //   bottom: 75,
        //   width: MediaQuery.of(context).size.width,
        //   child: Container(
        //     height: 80,
        //     width: 80,
        //     decoration: BoxDecoration(
        //       shape: BoxShape.circle,
        //       border: Border.all(
        //           width: 5, color: Colors.white, style: BorderStyle.solid),
        //     ),
        //     child: isDetecting
        //         ? IconButton(
        //             onPressed: () async {
        //               stopDetection();
        //             },
        //             icon: const Icon(
        //               Icons.stop,
        //               color: Colors.red,
        //             ),
        //             iconSize: 50,
        //           )
        //         : IconButton(
        //             onPressed: () async {
        //               await startDetection();
        //             },
        //             icon: const Icon(
        //               Icons.play_arrow,
        //               color: Colors.white,
        //             ),
        //             iconSize: 50,
        //           ),
        //   ),
        // ),
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: 'assets/labels1.txt',
        modelPath: 'assets/best_float32_en.tflite',
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    // Ensure cameraImage is not null
    if (cameraImage == null) {
      return []; // If no camera image, return empty list
    }

    double factorX = screen.width / cameraImage!.height;
    double factorY = screen.height / cameraImage!.width;

    Color colorPick = const Color.fromARGB(255, 233, 30, 99);

    return yoloResults.map((result) {
      String tag = result["tag"];
      double confidence = result["box"][4] * 100;

      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Stack(
          clipBehavior: Clip.none, // Allow text overflow
          children: [
            // The bounding box (just a border)
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                border: Border.all(color: Colors.pink, width: 2.0),
              ),
            ),
            // Positioned text above the bounding box
            Positioned(
              left: 0,
              bottom: (result["box"][3] - result["box"][1]) * factorY +
                  5, // Text above the box
              child: FutureBuilder<int?>(
                future: readCalForDish(tag), // Fetch calorie data for the dish
                builder: (context, snapshot) {
                  String displayText = "$tag ${confidence.toStringAsFixed(0)}%";
                  Color backgroundColor =
                      colorPick.withOpacity(0.7); // Semi-transparent background

                  // Handle the states of the FutureBuilder
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error fetching calories',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    // No calorie data, display only tag and confidence
                    return Container(
                      padding: const EdgeInsets.all(4.0),
                      color: backgroundColor,
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  } else {
                    // Calorie data available, display it
                    int cal = snapshot.data!;
                    displayText =
                        "$tag ${confidence.toStringAsFixed(0)}% - $cal cal";
                    return Container(
                      padding: const EdgeInsets.all(4.0),
                      color: backgroundColor,
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          overflow:
                              TextOverflow.ellipsis, // Handle text overflow
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Positioned topPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            flashLight(),
            isDetecting
                ? IconButton(
                    onPressed: () async {
                      stopDetection();
                    },
                    icon: const Icon(
                      Icons.stop,
                      color: Colors.red,
                    ),
                    iconSize: 50,
                  )
                : IconButton(
                    onPressed: () async {
                      await startDetection();
                      // checkFileAccess();
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                    iconSize: 50,
                  ),
          ],
        ),
      ),
    );
  }

  Positioned bottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: _isFrontCamera == false ? Colors.black : Colors.transparent,
        ),
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(10.0),
            //   child: modePicker(),
            // ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _switchCamera();
                          },
                          child: const Icon(
                            Icons.cameraswitch_sharp,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      cameraButton(),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded cameraButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          capturePhoto();
        },
        child: Center(
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                width: 4,
                color: Colors.white,
                style: BorderStyle.solid,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding flashLight() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          _toggleFlashLight();
        },
        child: _isFlashOn == false
            ? const Icon(
                Icons.flash_off,
                color: Colors.white,
              )
            : const Icon(
                Icons.flash_on,
                color: Colors.white,
              ),
      ),
    );
  }
}

class ImageDisplayWidget extends StatelessWidget {
  final String imagePath;

  const ImageDisplayWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                await GallerySaver.saveImage(imagePath);
                // Navigator.pop(context);
              },
              icon: const Icon(Icons.save))
        ],
      ),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}

class YoloImageV5 extends StatefulWidget {
  final FlutterVision vision;
  const YoloImageV5({super.key, required this.vision});

  @override
  State<YoloImageV5> createState() => _YoloImageV5State();
}

class _YoloImageV5State extends State<YoloImageV5> {
  late List<Map<String, dynamic>> yoloResults;
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadYoloModel().then((value) {
      setState(() {
        yoloResults = [];
        isLoaded = true;
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        imageFile != null ? Image.file(imageFile!) : const SizedBox(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  pickImage();
                  setState(() {
                    yoloResults.clear();
                  });
                },
                child: const Text("Pick image"),
              ),
              ElevatedButton(
                onPressed: yoloOnImage,
                child: const Text("Detect"),
              )
            ],
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size),
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: 'assets/labels1.txt',
        modelPath: 'assets/best_float32_en.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Capture a photo
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);
      });
    }
  }

  yoloOnImage() async {
    yoloResults.clear();
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;
    final result = await widget.vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / imageWidth;
    double imgRatio = imageWidth / imageHeight;
    double factorY = (screen.width / imgRatio) / imageHeight;
    double pady = (screen.height - (imageWidth * factorX) / imgRatio) / 2;

    Color colorPick = const Color.fromARGB(255, 233, 30, 99);

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX;
      double top = result["box"][1] * factorY + pady;
      double width = (result["box"][2] - result["box"][0]) * factorX;
      double height = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                border: Border.all(color: Colors.pink, width: 2.0),
              ),
            ),
            Positioned(
              left: 0,
              bottom: height + 5,
              child: FutureBuilder<int?>(
                future: readCalForDish(result["tag"]),
                builder: (context, snapshot) {
                  String displayText =
                      "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%";
                  Color backgroundColor = colorPick.withOpacity(0.7);

                  if (snapshot.hasData && snapshot.data != null) {
                    displayText += " - ${snapshot.data} cal";
                  } else if (snapshot.hasError) {
                    displayText = "Error fetching calories";
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text(
                      displayText.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class YoloImageV8 extends StatefulWidget {
  final FlutterVision vision;
  const YoloImageV8({super.key, required this.vision});

  @override
  State<YoloImageV8> createState() => _YoloImageV8State();
}

class _YoloImageV8State extends State<YoloImageV8> {
  late List<Map<String, dynamic>> yoloResults;
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadYoloModel().then((value) {
      setState(() {
        yoloResults = [];
        isLoaded = true;
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        imageFile != null ? Image.file(imageFile!) : const SizedBox(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: pickImage,
                child: const Text("Pick image"),
              ),
              ElevatedButton(
                onPressed: yoloOnImage,
                child: const Text("Detect"),
              )
            ],
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size),
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/best_float32_vn.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Capture a photo
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);
      });
    }
  }

  yoloOnImage() async {
    yoloResults.clear();
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;
    final result = await widget.vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / imageWidth;
    double imgRatio = imageWidth / imageHeight;
    double factorY = (screen.width / imgRatio) / imageHeight;
    double pady = (screen.height - (imageWidth * factorX) / imgRatio) / 2;

    Color colorPick = const Color.fromARGB(255, 233, 30, 99);

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX;
      double top = result["box"][1] * factorY + pady;
      double width = (result["box"][2] - result["box"][0]) * factorX;
      double height = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                border: Border.all(color: Colors.pink, width: 2.0),
              ),
            ),
            Positioned(
              left: 0,
              bottom: height + 5,
              child: FutureBuilder<int?>(
                future: readCalForDish(result["tag"]),
                builder: (context, snapshot) {
                  String displayText =
                      "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%";
                  Color backgroundColor = colorPick.withOpacity(0.7);

                  if (snapshot.hasData && snapshot.data != null) {
                    displayText += " - ${snapshot.data} cal";
                  } else if (snapshot.hasError) {
                    displayText = "Error fetching calories";
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text(
                      displayText.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

enum FoodType { vegetables, fruits, starch, meat, other }

class FoodItem {
  String foodName;
  int calories;
  int foodMass;
  FoodType foodType;

  FoodItem(this.foodName, this.calories, this.foodMass, this.foodType);
}

class KcalDay {
  DateTime day;
  List<FoodItem> foodItems;
  KcalDay(this.day, this.foodItems);
}

class TodayCounter extends StatefulWidget {
  final List<FoodItem> foodItems;
  final Function(FoodItem) addFoodItem;
  final Function(FoodItem) removeFoodItem;

  const TodayCounter(
      {super.key,
      required this.foodItems,
      required this.addFoodItem,
      required this.removeFoodItem});

  @override
  State<TodayCounter> createState() => _TodayCounterState();
}

class _TodayCounterState extends State<TodayCounter> {
  int getTotalCalories(List<FoodItem> foodItems) {
    return foodItems.fold(0,
        (sum, item) => sum + ((item.calories * item.foodMass) / 100).round());
  }

  void _showAddFoodItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full-screen height
      backgroundColor: Colors.transparent, // Transparent to customize container
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.9, // Occupy 90% of screen
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header Row with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Add Food Item",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the modal
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AddFoodForm(
                        foodItems: widget.foodItems,
                        addFoodItem: widget.addFoodItem,
                        removeFoodItem: widget.removeFoodItem),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FancyCard(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 15),
      borderRadius: 15,
      gradient: Gradients.blush,
      boxShadow: BoxShadow(
        color: Colors.red[200]!,
        blurRadius: 5.0,
        offset: const Offset(1, 1),
      ),
      child: Row(children: [
        IconButton(
          onPressed: () {
            // Example of adding a new food item when clicked
            _showAddFoodItemDialog(context);
          },
          icon: Icon(
            Icons.add,
            size: 50,
            color: Colors.white.withAlpha(200),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${getTotalCalories(widget.foodItems)}',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
              const Text(
                "calories today",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class AddFoodForm extends StatefulWidget {
  final List<FoodItem> foodItems;
  final Function addFoodItem;
  final Function removeFoodItem;

  const AddFoodForm(
      {super.key,
      required this.foodItems,
      required this.addFoodItem,
      required this.removeFoodItem});

  @override
  State<AddFoodForm> createState() => _AddFoodFormState();
}

class _AddFoodFormState extends State<AddFoodForm> {
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _foodMassController = TextEditingController();
  FoodType _foodType = FoodType.other; // Default type

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Avoid keyboard overlap
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Food Name Input
                  TextFormField(
                    controller: _foodNameController,
                    decoration: const InputDecoration(labelText: 'Food Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter food name';
                      }
                      return null;
                    },
                  ),

                  // Calories Input
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _caloriesController,
                    decoration:
                        const InputDecoration(labelText: 'Calories (per 100g)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter calories';
                      }
                      return null;
                    },
                  ),

                  // Food Mass Input
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _foodMassController,
                    decoration:
                        const InputDecoration(labelText: 'Food Mass (grams)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter food mass';
                      }
                      return null;
                    },
                  ),

                  // Food Type Dropdown
                  const SizedBox(height: 10),
                  DropdownButtonFormField<FoodType>(
                    value: _foodType,
                    onChanged: (FoodType? newType) {
                      setState(() {
                        _foodType = newType!;
                      });
                    },
                    items: FoodType.values.map((FoodType type) {
                      return DropdownMenuItem<FoodType>(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Food Type'),
                  ),

                  // Submit Button
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // Create a new FoodItem
                        final newFoodItem = FoodItem(
                          _foodNameController.text,
                          int.parse(_caloriesController.text),
                          int.parse(_foodMassController.text),
                          _foodType,
                        );
                        widget.addFoodItem(newFoodItem); // Add the food item
                        Navigator.of(context).pop(); // Close the modal
                      }
                    },
                    child: const Text('Add Food'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Column(
          children: widget.foodItems.map((foodItem) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                title: Text(foodItem.foodName),
                subtitle: Text('${foodItem.calories} kcal'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      widget.removeFoodItem(foodItem);
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class TodayStats extends StatefulWidget {
  final List<FoodItem> foodItems;

  const TodayStats({super.key, required this.foodItems});

  @override
  State<TodayStats> createState() => _TodayStatsState();
}

class _TodayStatsState extends State<TodayStats> {
  int getTotalMass() {
    return widget.foodItems.fold(0, (sum, item) => sum + item.foodMass);
  }

  // Method to calculate total food mass by FoodType
  int getMassByFoodType(FoodType foodType) {
    int totalMass = 0;

    // Iterate over the foodItems list, accessing each item's foodType
    for (var item in widget.foodItems) {
      // Ensure comparison is made between FoodType enum values
      if (item.foodType == foodType) {
        totalMass += item.foodMass; // Add mass if foodType matches
      }
    }

    return totalMass;
  }

  @override
  Widget build(BuildContext context) {
    return FancyCard(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 15),
      borderRadius: 10,
      backgroundColor: Colors.white,
      boxShadow: BoxShadow(
        color: Colors.grey[400]!,
        blurRadius: 3.0,
        offset: const Offset(1, 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                const Expanded(child: Text("Total food mass today:")),
                Text(
                  "${getTotalMass()}g",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: Colors.grey[300]!,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(FontAwesomeIcons.seedling, color: Colors.green),
                  ),
                  const Text("Vegetables"),
                  Expanded(
                      child: Text("${getMassByFoodType(FoodType.vegetables)}g",
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: Colors.grey[300]!,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(FontAwesomeIcons.appleWhole,
                        color: Colors.red[400]),
                  ),
                  const Text("Fruits"),
                  Expanded(
                      child: Text("${getMassByFoodType(FoodType.fruits)}g",
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: Colors.grey[300]!,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(FontAwesomeIcons.breadSlice,
                        color: Colors.yellow[700]),
                  ),
                  const Text("Starch"),
                  Expanded(
                      child: Text("${getMassByFoodType(FoodType.starch)}g",
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: Colors.grey[300]!,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(FontAwesomeIcons.drumstickBite,
                        color: Colors.orange[700]),
                  ),
                  const Text("Meat"),
                  Expanded(
                      child: Text("${getMassByFoodType(FoodType.meat)}g",
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: Colors.grey[300]!,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(FontAwesomeIcons.candyCane, color: Colors.pink),
                  ),
                  const Text("Other"),
                  Expanded(
                      child: Text("${getMassByFoodType(FoodType.other)}g",
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class KcalGraph extends StatefulWidget {
  final List<KcalDay> kcalDays;

  const KcalGraph({
    super.key,
    required this.kcalDays,
  });

  @override
  State<KcalGraph> createState() => _KcalGraphState();
}

class _KcalGraphState extends State<KcalGraph> {
  @override
  Widget build(BuildContext context) {
    // Calculate total calories per day
    final List<MapEntry<DateTime, int>> totalCaloriesPerDay =
        widget.kcalDays.map((kcalDay) {
      // Calculate total calories for the day
      int totalCalories = kcalDay.foodItems.fold(0, (sum, item) {
        // Calculate calories for each item based on food mass
        final itemCalories = ((item.calories * item.foodMass) / 100).round();
        return sum + itemCalories;
      });
      return MapEntry(kcalDay.day, totalCalories);
    }).toList();

    // Calculate min and max calories
    const int minCalories = 0; // Always 0
    final int maxCalories = totalCaloriesPerDay.isEmpty
        ? 1000
        : totalCaloriesPerDay.fold<int>(0, (prev, entry) {
            return entry.value > prev ? entry.value : prev;
          });

    // Adjust maxCalories to be dynamic based on the range
    final int adjustedMaxCalories =
        maxCalories > 1000 ? (maxCalories + 100) : 1000;

    // Create the series for the graph
    final seriesList = _createSeries(totalCaloriesPerDay);

    return FancyCard(
      borderRadius: 10,
      padding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      boxShadow: BoxShadow(
        color: Colors.grey[400]!,
        blurRadius: 3.0,
        offset: const Offset(1, 1),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text("Last 30 days"),
              Expanded(
                child: Text(
                  "${_calculateAverageCalories(totalCaloriesPerDay)} kcal avg",
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Adjust height as needed
          SizedBox(
            height: 250, // Give the chart a fixed height
            child: ClipRect(
              child: charts.TimeSeriesChart(
                seriesList,
                animate: true,
                defaultRenderer: charts.LineRendererConfig(includeArea: true),
                primaryMeasureAxis: charts.NumericAxisSpec(
                  viewport:
                      charts.NumericExtents(minCalories, adjustedMaxCalories),
                  tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                    desiredTickCount: 10, // Adjust tick count if necessary
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Create the series list
  List<charts.Series<MapEntry<DateTime, int>, DateTime>> _createSeries(
      List<MapEntry<DateTime, int>> totalCaloriesPerDay) {
    return [
      charts.Series<MapEntry<DateTime, int>, DateTime>(
        id: 'Calories',
        domainFn: (MapEntry<DateTime, int> data, _) =>
            data.key, // Access the DateTime
        measureFn: (MapEntry<DateTime, int> data, _) =>
            data.value, // Access the total calories
        data:
            totalCaloriesPerDay, // Pass the list of DateTime and total calories
      ),
    ];
  }

  // Calculate the average calories for display
  int _calculateAverageCalories(
      List<MapEntry<DateTime, int>> totalCaloriesPerDay) {
    if (totalCaloriesPerDay.isEmpty) return 0;
    int totalCalories =
        totalCaloriesPerDay.fold(0, (sum, item) => sum + item.value);
    return (totalCalories / totalCaloriesPerDay.length).round();
  }
}
