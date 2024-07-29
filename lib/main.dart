import 'dart:convert';

import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const Home(),
    );
  }
}

class TextItem extends AppFlowyGroupItem {
  final String s;
  TextItem(this.s);

  @override
  String get id => s;
}

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoaded = false;
  Map<int, List<Map<String, dynamic>>> items = {};
  late AppFlowyBoardController controller = AppFlowyBoardController(
    onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move item from $fromIndex to $toIndex');
    },
    onMoveGroupItem: (groupId, fromIndex, toIndex) async {
      debugPrint('Move $groupId:$fromIndex to $groupId:$toIndex');
      int parentId = int.parse(groupId);
      if (items.containsKey(parentId)) {
        var element = items[parentId]![fromIndex];
        await saveItem(element['indicator_to_mo_id'].toString(),
            groupId.toString(), toIndex.toString());
        items[parentId]!.removeAt(fromIndex);
        items[parentId]!.insert(toIndex, element);
        print('DONE');
        setState(() {}); // Ensure the UI updates
      }
    },
    onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) async {
      debugPrint('Move $fromGroupId:$fromIndex to $toGroupId:$toIndex');
      int parentId = int.parse(fromGroupId);
      if (items.containsKey(parentId)) {
        var element = items[parentId]![fromIndex];
        await saveItem(element['indicator_to_mo_id'].toString(),
            toGroupId.toString(), toIndex.toString());
        items[parentId]!.removeAt(fromIndex);
        items[int.parse(toGroupId)]!.insert(toIndex, element);
        print('DONE');
        setState(() {}); // Ensure the UI updates
      }
    },
  );

  getAllItems() async {
    try {
      var uri = Uri.parse(
          'https://development.kpi-drive.ru/_api/indicators/get_mo_indicators');

      var request = http.MultipartRequest('POST', uri)
        ..fields['period_start'] = '2024-06-01'
        ..fields['period_end'] = '2024-06-30'
        ..fields['period_key'] = 'month'
        ..fields['requested_mo_id'] = '478'
        ..fields['behaviour_key'] = 'task,kpi_task'
        ..fields['with_result'] = 'false'
        ..fields['response_fields'] = 'name,indicator_to_mo_id,parent_id,order'
        ..fields['auth_user_id'] = '2'
        ..headers['Authorization'] = 'Bearer 48ab34464a5573519725deb5865cc74c'
        ..headers['Content-Type'] = 'multipart/form-data; charset=UTF-8';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var body = jsonDecode(utf8.decode(response.bodyBytes));
        print(body);
        var lists = body['DATA']['rows'];
        for (var item in lists) {
          int parentId = item['parent_id'];
          if (items.containsKey(parentId)) {
            items[parentId]!.add(item);
          } else {
            items[parentId] = [item];
          }
        }

        items.forEach((key, value) {
          controller.addGroup(AppFlowyGroupData(
              id: key.toString(),
              items: List<AppFlowyGroupItem>.from(
                  value.map((e) => TextItem(e['name']))),
              name: key.toString()));
        });
      } else {
        print('Error: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  saveItem(indicatorToMoId, parentId, order) async {
    try {
      var uri = Uri.parse(
          'https://development.kpi-drive.ru/_api/indicators/save_indicator_instance_field');

      var request = http.MultipartRequest('POST', uri)
        ..fields['period_start'] = '2024-06-01'
        ..fields['period_end'] = '2024-06-30'
        ..fields['period_key'] = 'month'
        ..fields['indicator_to_mo_id'] = indicatorToMoId
        ..fields['field_name'] = 'parent_id'
        ..fields['field_value'] = parentId
        ..fields['field_name'] = 'order'
        ..fields['field_value'] = order
        ..fields['auth_user_id'] = '2'
        ..headers['Authorization'] = 'Bearer 48ab34464a5573519725deb5865cc74c'
        ..headers['Content-Type'] = 'multipart/form-data; charset=UTF-8';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var body = jsonDecode(utf8.decode(response.bodyBytes));
        print(body);
      } else {
        print('Error: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  @override
  initState() {
    super.initState();
    getAllItems().then((value) {
      isLoaded = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Text('ЕЖ'),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Жирняков Е.А.',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Консультант',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: AppFlowyBoard(
          controller: controller,
          cardBuilder: (context, group, groupItem) {
            final textItem = groupItem as TextItem;
            return AppFlowyGroupCard(
              key: ObjectKey(textItem),
              decoration: BoxDecoration(
                color: Colors.grey[800],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(child: Text(textItem.s)),
              ),
            );
          },
          groupConstraints: const BoxConstraints.tightFor(width: 400),
          headerBuilder: (context, groupData) {
            return Text(groupData.id);
          },
        ),
      ),
    );
  }
}
