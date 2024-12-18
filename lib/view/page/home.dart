import 'package:dscaption/view/tab/dataset_captioner.dart';
import 'package:dscaption/view/tab/image_captioner.dart';
import 'package:flutter/material.dart';

final GlobalKey<ImageCaptionerTabState> _key = GlobalKey<ImageCaptionerTabState>();

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatasetCaptionerTab _datasetCaptionerTab;
  late ImageCaptionerTab _imageCaptionerTab;

  Future<String> obtainImageCaption(String path) async
  {
    return await _key.currentState!.obtainImageCaption(path);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _datasetCaptionerTab = DatasetCaptionerTab( parentWidgetState: this);
    _imageCaptionerTab = ImageCaptionerTab(key: _key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DSCaption'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Images Manager'),
            Tab(text: 'Captioning Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _datasetCaptionerTab,
          _imageCaptionerTab,
        ],
      ),
    );
  }
}



// class HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;

//   List<Widget> _widgetOptions = <Widget>[
//     DatasetCaptionerTab(parentWidget: this),
//     ImageCaptionerTab(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('DSCaption'),
//       ),
//       body: Center(
//         child: _widgetOptions.elementAt(_selectedIndex),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.image),
//             label: 'Images Manager',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Captioning Settings',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.blue,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }