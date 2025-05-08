import 'dart:async';

import 'package:cleadr/src/services/services.dart';
import 'package:cleadr/src/util/place.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class MapsSearchScreen extends StatefulWidget {
  final Function(LatLng) onDestinationClicked;
  final Place destinationPlace;

  const MapsSearchScreen({
    super.key,
    required this.onDestinationClicked,
    required this.destinationPlace,
  });

  @override
  State<StatefulWidget> createState() => _MapsSearchScreenState();
}

class _MapsSearchScreenState extends State<MapsSearchScreen> {
  bool _isSearching = false;

  late final TextEditingController _searchBarController;
  late final FocusNode _searchBar;
  late List<Place> _placePredictionsBuffer;
  late List<Place> _placePredictions;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initSearchBar();
  }

  @override
  void dispose() {
    _disposeSearchBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isSearching
            ? Scaffold(
                body: Column(
                  // Search results
                  children: [
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _placePredictions.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.place,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              // Place
                              title: Text(
                                _placePredictions[index].name!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Address
                              subtitle: Text(
                                _placePredictions[index].formatted_address ??
                                    "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.blueGrey),
                              ),
                              onTap: () {
                                _isSearching = false;
                                widget.onDestinationClicked(
                                  LatLng(
                                    latitude: _placePredictions[index].lat!,
                                    longitude: _placePredictions[index].lng!,
                                  ),
                                );
                                _searchBar.unfocus();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Container(),

        // Search bar
        Positioned(
          left: 12,
          right: 12,
          top: 60,
          child: Container(
            decoration: BoxDecoration(
              color: _isSearching
                  ? const Color.fromARGB(255, 240, 240, 240)
                  : Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            height: 50,
            child: Row(
              children: [
                // Back / Search (Left)
                _isSearching
                    ? IconButton(
                        style: IconButton.styleFrom(
                          highlightColor: Colors.transparent,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchBar.unfocus();
                          setState(() {});
                        },
                      )
                    : IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.transparent,
                        ),
                        icon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        onPressed: null,
                      ),

                // Search textfield
                Expanded(
                  child: TextField(
                    controller: _searchBarController,
                    focusNode: _searchBar,
                    decoration: const InputDecoration(
                      hintText: 'Search Places...',
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    onTap: () {
                      _isSearching = true;
                      setState(() {});
                    },
                    onChanged: (text) {
                      if (text.isNotEmpty) {
                        if (kDebugMode) {
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 400), () {
                            _fetchPlacePredictions(text);
                          });
                        } else {
                          _fetchPlacePredictions(text);
                        }
                      } else {
                        _placePredictions.clear();
                        setState(() {});
                      }
                    },
                    onEditingComplete: () {
                      if (_searchBarController.text.isNotEmpty) {
                        _fetchPlacePredictions(_searchBarController.text);
                      } else {
                        _placePredictions.clear();
                        setState(() {});
                      }
                    },
                  ),
                ),

                // Cancel
                _searchBarController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchBarController.clear();
                          _placePredictionsBuffer.clear();
                          _placePredictions.clear();
                          setState(() {});
                        },
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _initSearchBar() {
    _searchBarController = TextEditingController();
    _searchBar = FocusNode();
    _placePredictions = [];
    _searchBar.addListener(() {
      _isSearching = _searchBar.hasFocus;
      setState(() {});
    });
  }

  void _disposeSearchBar() {
    _searchBar.dispose();
    _searchBarController.dispose();
  }

  Future<void> _fetchPlacePredictions(String query) async {
    _placePredictionsBuffer = await Services.fetchPlacePredictions(query);

    if (_searchBarController.text.isNotEmpty) {
      _placePredictions = _placePredictionsBuffer;
    }

    setState(() {});
  }
}
