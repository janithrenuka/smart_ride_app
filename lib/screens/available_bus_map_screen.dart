import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_ride_app/constants.dart';
import 'package:smart_ride_app/screens/fare_rates_screen.dart';
import 'package:smart_ride_app/screens/past_travel_screen.dart';
import 'package:smart_ride_app/screens/start_screen.dart';
import 'package:smart_ride_app/widgets/bottom_nav_item.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:convert';
import 'dart:core';

class AvailableBusMap extends StatefulWidget {
  const AvailableBusMap({Key key}) : super(key: key);
  @override
  _AvailableBusMapState createState() => _AvailableBusMapState();
}

class _AvailableBusMapState extends State<AvailableBusMap> {
  List<Marker> locations = [];
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this.fetchLocation();
    this.getCurrentStartLocation();
    this.setCustomMapPin();
    this.setCustomBusMapPin();
  }

  // get user current location
  LatLng userCurrent;
  BitmapDescriptor pinLocationIcon;

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 0.5),
        'assets/images/usernew.png');
  }

  getCurrentStartLocation() async {
    final geoposition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);

    setState(() {
      userCurrent = LatLng(geoposition.latitude, geoposition.longitude);
      locations.add(
        Marker(
          markerId: MarkerId('Me'),
          infoWindow: InfoWindow(title: 'My Location'),
          position: LatLng(userCurrent.latitude, userCurrent.longitude),
          icon: pinLocationIcon,
        ),
      );
    });

  }


  BitmapDescriptor busLocationIcon;

  void setCustomBusMapPin() async {
    busLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/busicon.png');
  }

  Future<Set<Marker>> fetchLocation() async {

    var url = "http://192.168.1.102:5000/passenger/buslocations";
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var items = List<Map<String, dynamic>>.from(json.decode(response.body));

      if (items.length > 0) {
        for (int i = 0; i < items.length; i++) {
          Map<String, dynamic> map = items[i];
          var x = (map['latitude']);
          var y = (map['longitude']);
          locations.add(
            Marker(
              markerId: MarkerId('Bus'),
              infoWindow: InfoWindow(title: items[i]['bus_number']),
              position: LatLng(x, y),
              icon: busLocationIcon,
            ),
          );
        }
      }
    }
    setState(() {
      isLoading = true;
    });
    return locations.toSet();

  }

  static const _initialcameraposition = CameraPosition(
    target: LatLng(6.0535, 80.2210),
  );

  GoogleMapController _controller;
  location.Location _location = location.Location();

  void _onMapCreated(GoogleMapController _cntlr) {
    _controller = _cntlr;
    _location.onLocationChanged.listen((l) {
      _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(l.latitude, l.longitude), zoom: 16),
        ),
      );
    });
    Future.delayed(
        const Duration(milliseconds: 550),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            height: size.height,

            child: FutureBuilder(
              future: fetchLocation(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                return (
                    AnimatedOpacity(
                        curve: Curves.fastOutSlowIn,
                        opacity: snapshot.hasData ? 1.0 : 0,
                        duration: Duration(milliseconds: 600),
                          child: GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: _initialcameraposition,
                            onMapCreated: _onMapCreated,
                            myLocationEnabled: true,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: false,
                            zoomControlsEnabled: false,
                            markers: snapshot.data,
                          )
                    )
                );
              },
            ),
          ),

          //back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      icon: new Icon(Icons.arrow_back),
                      color: Colors.black,
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return StartScreen();
                        }));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // my location button
      floatingActionButton: FloatingActionButton(
        backgroundColor: KMyLocation,
        foregroundColor: Colors.black,
        onPressed: () => _controller.animateCamera(
          CameraUpdate.newCameraPosition(_initialcameraposition),
        ),
        child: const Icon(Icons.my_location),
      ),

      //navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          color: KLightNavBarColor,
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 65,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              BottomNavItem(
                title: "Past Travels",
                botIcon: Icons.history,
                press: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return PastTravels();
                  }));
                },
              ),
              BottomNavItem(
                title: "Available Busses",
                botIcon: Icons.directions_bus,
                press: () {},
              ),
              BottomNavItem(
                title: "Fare Rates",
                botIcon: Icons.corporate_fare,
                press: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return FareRates();
                  }));
                },
              ),
            ]),
      ),
    );
  }
}
