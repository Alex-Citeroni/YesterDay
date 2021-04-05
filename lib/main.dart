/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:android_intent/android_intent.dart';

void main() => runApp(OutSun());

class OutSun extends StatefulWidget {
  @override
  _OutSunState createState() => _OutSunState();
}

class _OutSunState extends State<OutSun> {
  var temperature,
      weather = 'cielosereno',
      currently,
      location,
      icon,
      errorMessage,
      position,
      latitude,
      longitude;
  List minTemperatureForecast = [],
      maxTemperatureForecast = [],
      iconForecast = [],
      iconHistory = ['', '', '', '', ''],
      minTemperatureHistory = [0, 1, 2, 3, 4],
      maxTemperatureHistory = [0, 1, 2, 3, 4];
  int clearSky = 0,
      fewClouds = 0,
      scatteredClouds = 0,
      brokenClouds = 0,
      showerRain = 0,
      rain = 0,
      thunderstorm = 0,
      snow = 0,
      mist = 0,
      minTemp,
      maxTemp,
      minTempHistory,
      maxTempHistory;

  @override
  void initState() {
    super.initState();
    requestPermission();
    initializeDateFormatting();
  }

  void openLocationSetting() async {
    final AndroidIntent intent = new AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  void requestPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || await Permission.location.isRestricted) {
      await Permission.location.request();
      determinePosition();
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      determinePosition();
    } else
      determinePosition();

    if (await Permission.contacts.request().isGranted ||
        await Permission.locationWhenInUse.serviceStatus.isEnabled)
      determineLastPosition();

    if (await Permission.speech.isPermanentlyDenied) {
      openAppSettings();
      determinePosition();
    }
  }

  void data(result) {
    setState(() {
      location = result['name'];
      temperature = result['main']['temp'].round();
      weather =
          result['weather'][0]['description'].replaceAll(' ', '').toLowerCase();
      currently = result['weather'][0]['main'];
      icon = result['weather'][0]['icon'];
      errorMessage = '';
      latitude = result['coord']['lat'];
      longitude = result['coord']['lon'];
    });
  }

  void fetchSearch(String input) async {
    var searchResult = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$input,it&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
    var result = json.decode(searchResult.body);
    if (result['message'] != null) {
      searchResult = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$input&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
      result = json.decode(searchResult.body);
      if (result['message'] != null)
        setState(() {
          errorMessage = 'Purtroppo non abbiamo dati su questa città';
        });
      else
        data(result);
    } else
      data(result);
  }

  void fetchPosition(String lat, String lon) async {
    var searchResult = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
    var result = json.decode(searchResult.body);
    setState(() {
      location = result['name'];
      temperature = result['main']['temp'].round();
      weather =
          result['weather'][0]['description'].replaceAll(' ', '').toLowerCase();
      currently = result['weather'][0]['main'];
      icon = result['weather'][0]['icon'];
      errorMessage = '';
    });
  }

  void icona(String element) {
    if (element == '01d' || element == '01n')
      clearSky++;
    else if (element == '02d' || element == '02n')
      fewClouds++;
    else if (element == '03d' || element == '03n')
      scatteredClouds++;
    else if (element == '04d' || element == '04n')
      brokenClouds++;
    else if (element == '09d' || element == '09n')
      showerRain++;
    else if (element == '10d' || element == '10n')
      rain++;
    else if (element == '11d' || element == '11n')
      thunderstorm++;
    else if (element == '13d' || element == '13n')
      snow++;
    else
      mist++;
  }

  AssetImage wallpaper(String element) {
    if (element == '01d' ||
        element == '02d' ||
        element == '03d' ||
        element == '04d' ||
        element == '04n' ||
        element == '09d' ||
        element == '10d' ||
        element == '11d' ||
        element == '11n' ||
        element == '13d' ||
        element == '50d' ||
        element == '50n')
      return AssetImage('images/$weather.png');
    else if (element == '01n')
      return AssetImage('images/cieloserenonotturno.png');
    else if (element == '02n')
      return AssetImage('images/pochenuvolenotturno.png');
    else if (element == '03n')
      return AssetImage('images/nubisparsenotturno.png');
    else if (element == '09n')
      return AssetImage('images/pioggiamoderatanotturno.png');
    else if (element == '10n')
      return AssetImage('images/fortepioggianotturno.png');
    else
      return AssetImage('images/nevenotturno.png');
  }

  void reset() {
    clearSky = 0;
    fewClouds = 0;
    scatteredClouds = 0;
    brokenClouds = 0;
    showerRain = 0;
    rain = 0;
    thunderstorm = 0;
    snow = 0;
    mist = 0;
    minTemp = null;
    maxTemp = null;
    minTempHistory = null;
    maxTempHistory = null;
  }

  String maxIcon() {
    int max = 0;
    if (clearSky > max) max = clearSky;
    if (fewClouds > max) max = fewClouds;
    if (scatteredClouds > max) max = scatteredClouds;
    if (brokenClouds > max) max = brokenClouds;
    if (showerRain > max) max = showerRain;
    if (rain > max) max = rain;
    if (thunderstorm > max) max = thunderstorm;
    if (snow > max) max = snow;
    if (mist > max) max = mist;
    if (clearSky == max)
      return '01d';
    else if (fewClouds == max)
      return '02d';
    else if (scatteredClouds == max)
      return '03d';
    else if (brokenClouds == max)
      return '04d';
    else if (showerRain == max)
      return '09d';
    else if (rain == max)
      return '10d';
    else if (thunderstorm == max)
      return '11d';
    else if (snow == max)
      return '13d';
    else
      return '50d';
  }

  void fetchLatLonDay(String lat, String lon) async {
    var locationDayResult = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
    var result = json.decode(locationDayResult.body);
    List icone = [],
        minTemperature = [],
        maxTemperature = [],
        giorno = ['', '', '', '', '', '', '', ''],
        min = ['', '', '', '', '', '', '', ''],
        max = ['', '', '', '', '', '', '', ''];
    if (result['message'] == 0)
      setState(() {
        iconForecast.clear();
        maxTemperatureForecast.clear();
        minTemperatureForecast.clear();
        min.clear();
        max.clear();
        giorno.clear();
        giorno = ['', '', '', '', '', '', '', ''];
        min = ['', '', '', '', '', '', '', ''];
        max = ['', '', '', '', '', '', '', ''];
        result['list'].forEach((element) {
          minTemperature.add(element['main']['temp_min'].round());
          maxTemperature.add(element['main']['temp_max'].round());
          icone.add(element['weather'][0]['icon']);
        });
        int j = 0;
        for (var i = 0; i < 5; i++) {
          giorno.setRange(0, 8, icone, j);
          giorno.forEach((element) => icona(element.toString()));
          min.setRange(0, 8, minTemperature, j);
          min.forEach((element) {
            if (minTemp == null) minTemp = element;
            if (element > minTemp) minTemp = element;
          });
          max.setRange(0, 8, maxTemperature, j);
          max.forEach((element) {
            if (maxTemp == null) maxTemp = element;
            if (element < maxTemp) maxTemp = element;
          });
          minTemperatureForecast.add(minTemp.toString());
          maxTemperatureForecast.add(maxTemp.toString());
          iconForecast.add(maxIcon());
          reset();
          j = j + 8;
        }
      });
  }

  void fetchLocationDay(String input) async {
    var locationDayResult = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$input,it&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
    var result = json.decode(locationDayResult.body);
    if (result['message'] != 0) {
      locationDayResult = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$input&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
      result = json.decode(locationDayResult.body);
    }
    if (result['message'] == 0)
      setState(() {
        iconForecast.clear();
        maxTemperatureForecast.clear();
        minTemperatureForecast.clear();
        List icone = [],
            minTemperature = [],
            maxTemperature = [],
            giorno = ['', '', '', '', '', '', '', ''],
            min = ['', '', '', '', '', '', '', ''],
            max = ['', '', '', '', '', '', '', ''];
        result['list'].forEach((element) {
          minTemperature.add(element['main']['temp_min'].round());
          maxTemperature.add(element['main']['temp_max'].round());
          icone.add(element['weather'][0]['icon']);
        });
        int j = 0;
        for (var i = 0; i < 5; i++) {
          giorno.setRange(0, 8, icone, j);
          giorno.forEach((element) => icona(element.toString()));
          min.setRange(0, 8, minTemperature, j);
          min.forEach((element) {
            if (minTemp == null) minTemp = element;
            if (element > minTemp) minTemp = element;
          });
          max.setRange(0, 8, maxTemperature, j);
          max.forEach((element) {
            if (maxTemp == null) maxTemp = element;
            if (element < maxTemp) maxTemp = element;
          });
          minTemperatureForecast.add(minTemp.toString());
          maxTemperatureForecast.add(maxTemp.toString());
          iconForecast.add(maxIcon());
          reset();
          j = j + 8;
        }
      });
  }

  void yesterday(lat, lon) async {
    DateTime now = new DateTime.now();
    for (var i = 0; i < 5; i++) {
      var time =
          (DateTime(now.year, now.month, now.day - i).millisecondsSinceEpoch /
                  1000)
              .round();
      var locationDayResult = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/onecall/timemachine?lat=$lat&lon=$lon&dt=$time&units=metric&lang=it&appid=856822fd8e22db5e1ba48c0e7d69844a'));
      var result = json.decode(locationDayResult.body);
      setState(() {
        List icone = [], temperature = [], min = [], max = [];
        result['hourly'].forEach((element) {
          temperature.add(element['temp'].round());
          icone.add(element['weather'][0]['icon']);
        });
        icone.forEach((element) => icona(element.toString()));
        temperature.forEach((element) {
          min.add(element);
          max.add(element);
        });
        min.forEach((element) {
          if (minTempHistory == null) minTempHistory = element;
          if (element > minTempHistory) minTempHistory = element;
        });
        max.forEach((element) {
          if (maxTempHistory == null) maxTempHistory = element;
          if (element < maxTempHistory) maxTempHistory = element;
        });
        minTemperatureHistory[i] = minTempHistory.toString();
        maxTemperatureHistory[i] = maxTempHistory.toString();
        iconHistory[i] = maxIcon();
        reset();
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    fetchSearch(input);
    fetchLocationDay(input);
    yesterday(latitude, longitude);
  }

  void determineLastPosition() async {
    position = await Geolocator.getLastKnownPosition();
    latitude = position.latitude.toString();
    longitude = position.longitude.toString();
    fetchPosition(latitude, longitude);
    fetchLatLonDay(latitude, longitude);
    yesterday(latitude, longitude);
  }

  void determinePosition() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    latitude = position.latitude.toString();
    longitude = position.longitude.toString();
    fetchPosition(latitude, longitude);
    fetchLatLonDay(latitude, longitude);
    yesterday(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue[800],
        accentColor: Colors.cyan[600],
      ),
      home: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: wallpaper(icon),
                  fit: BoxFit.cover,
                  colorFilter: new ColorFilter.mode(
                      Colors.black.withOpacity(0.6), BlendMode.dstATop))),
          child: temperature == null
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Scaffold(
                  appBar: AppBar(
                    actions: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              width: 300,
                              child: TextField(
                                onSubmitted: (String input) =>
                                    onTextFieldSubmitted(input),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2.0, 1.5),
                                      blurRadius: 3.0,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ],
                                ),
                                decoration: InputDecoration(
                                    hintText: 'Cerca una località...',
                                    hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2.0, 1.5),
                                          blurRadius: 3.0,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                        child: GestureDetector(
                          onTap: () => determinePosition(),
                          child: Icon(
                            Icons.location_city,
                            size: 36.0,
                          ),
                        ),
                      )
                    ],
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                  ),
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: Platform.isAndroid ? 15.0 : 20.0,
                              shadows: [
                                Shadow(
                                  offset: Offset(2.0, 1.5),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: icon == null
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Image.network(
                                    'http://openweathermap.org/img/wn/$icon@2x.png',
                                    width: 100,
                                  ),
                          ),
                          Center(
                              child: Text(
                            temperature.toString() + '°C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 60.0,
                              shadows: [
                                Shadow(
                                  offset: Offset(2.0, 1.5),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ],
                            ),
                          )),
                          Center(
                            child: Text(
                              location,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2.0, 1.5),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              DateFormat.EEEE('it').format(DateTime.now()),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2.0, 1.5),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              DateTime.now().hour.toString() +
                                  ' : ' +
                                  DateTime.now().minute.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2.0, 1.5),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: Center(
                              child: Text(
                                'GIORNI PRECEDENTI',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19.0,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2.0, 1.5),
                                      blurRadius: 3.0,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      iconForecast.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // box(iconHistory, minTemperatureHistory,
                                  //     maxTemperatureHistory),
                                  for (var i = 0; i < 5; i++)
                                    historyElement(
                                        i + 1,
                                        iconHistory[i],
                                        minTemperatureHistory[i],
                                        maxTemperatureHistory[i]),
                                  //   boxTomorrow(
                                  //     iconForecast,
                                  //   minTemperatureForecast,
                                  // maxTemperatureForecast)
                                ],
                              ),
                            ),
                    ],
                  ),
                )),
    );
  }
}

Widget boxTomorrow(icon, min, max) {
  return Padding(
    padding: const EdgeInsets.only(left: 10.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Giorni futuri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  forecastElement(i + 1, icon[i], min[i], max[i]),
              ],
            )
          ],
        ),
      ),
    ),
  );
}

Widget box(icon, min, max) {
  return Padding(
    padding: const EdgeInsets.only(left: 10.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Giorni precedenti',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                //  for (var i = 4; i >= 0; i--)
                //  historyElement(i + 1, icon[i], min[i], max[i])
              ],
            )
          ],
        ),
      ),
    ),
  );
}

Widget historyElement(daysFromNow, icon, maxTemperature, minTemperature) {
  DateTime now = new DateTime.now();
  var yesterday = now.add(new Duration(days: -daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              new DateFormat.E('it').format(yesterday),
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Text(
              new DateFormat.MMMd().format(yesterday),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: icon == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Image.network(
                      'http://openweathermap.org/img/wn/$icon@2x.png',
                      width: 50,
                    ),
            ),
            Text(
              'Max: ' + maxTemperature.toString() + ' °C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Text(
              'Min: ' + minTemperature.toString() + ' °C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ),
  );
}

Widget forecastElement(daysFromNow, icon, maxTemperature, minTemperature) {
  DateTime now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: daysFromNow));
  initializeDateFormatting();
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              new DateFormat.E('it').format(oneDayFromNow),
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Text(
              new DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: icon == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Image.network(
                      'http://openweathermap.org/img/wn/$icon@2x.png',
                      width: 50,
                    ),
            ),
            Text(
              'Max: ' + maxTemperature.toString() + ' °C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Text(
              'Min: ' + minTemperature.toString() + ' °C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 1.5),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ),
  );
}
