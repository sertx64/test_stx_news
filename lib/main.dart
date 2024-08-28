import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:loadmore/loadmore.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'новости саратова',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            iconSize: 35.0,
            icon: const Icon(Icons.info_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const infoWidget(),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
        title:
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
              style: TextStyle(
                color: Colors.white,
              ),
              '          Новости'),
          Text(
              style: TextStyle(
                color: Color(0xFFAE0F38),
              ),
              'Саратова')
        ]),
        bottom: TabBar(
          unselectedLabelColor: Colors.white60,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorWeight: 4.0,
          labelStyle: const TextStyle(fontSize: 22),
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'лента'),
            Tab(text: 'важное'),
            Tab(text: 'статьи'),
          ],
        ),
      ),
      body: TabBarView(
        //key: const PageStorageKey('tab_view_key'),
        controller: _tabController,
        children: const <Widget>[
          TestNewsStx(tipCont: ''),
          TestNewsStx(tipCont: '&catId=top'),
          TestNewsStx(tipCont: '&catId=article'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class TestNewsStx extends StatefulWidget {
  final String tipCont;
  const TestNewsStx({super.key, required this.tipCont});

  @override
  State<TestNewsStx> createState() => _TestNewsStxState();
}

class _TestNewsStxState extends State<TestNewsStx>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List? testX;
  bool isRefreshing = false;

  @override
  void initState() {
    loadNews();
    super.initState();
  }

  void loadNews() async {
    testX = await getApi('0', widget.tipCont).getContent();
    setState(() {});
  }

  Future<void> refresh() async {
    isRefreshing = true;
    loadNews();

    await Future.delayed(
        const Duration(seconds: 1)); // Симулируем загрузку данных
    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return (testX == null)
        ? const SizedBox()
        : RefreshIndicator(
            onRefresh: refresh,
            child: LoadMore(
                onLoadMore: () async {
                  testX?.addAll(await getApi(
                          testX?[testX!.length - 1]['date'], widget.tipCont)
                      .getContent());
                  setState(() {});

                  return true;
                },
                child: ListView.separated(
                  itemBuilder: (context, index) => ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                contentWidget(idContent: testX?[index]['id']),
                          ),
                        );
                      },
                      title: Row(
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  style: const TextStyle(
                                    color: Color(0xFFAE0F38),
                                    fontSize: 16,
                                  ),
                                  convDateTime()
                                      .convStrToDate(testX?[index]['date']),
                                ),
                                Text(
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          (testX?[index]['important'] == 1)
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                    testX?[index]['title']),
                              ])),
                          const SizedBox(width: 5),
                          Image.network(width: 100, errorBuilder:
                              (BuildContext context, Object exception,
                                  StackTrace? stackTrace) {
                            return const SizedBox(width: 5);
                          }, testX?[index]['img']),
                        ],
                      )),
                  separatorBuilder: (context, index) => const Divider(),
                  itemCount: testX!.length,
                )));
  }
}

class contentWidget extends StatefulWidget {
  final String idContent;
  const contentWidget({super.key, required this.idContent});

  @override
  State<contentWidget> createState() => _contentWidgetState();
}

class _contentWidgetState extends State<contentWidget> {
  Map? apiContent;

  @override
  void initState() {
    loadNews();
    super.initState();
  }

  void loadNews() async {
    apiContent = await getApiContent(widget.idContent).getContent();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return (apiContent == null)
        ? const Scaffold(body: Center(child: Text('Загрузка')))
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              actions: <Widget>[
                IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      await FlutterShare.share(
                        title: apiContent?['data']['title'],
                        // text: 'Example share text',
                        linkUrl: apiContent?['data']['url'],
                        //chooserTitle: 'Example Chooser Title'
                      );
                    }),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                imageNet(apiContent?['data']['img']),
                const SizedBox(height: 32),
                Text(
                    style: const TextStyle(
                      color: Color(0xFFAE0F38),
                      fontSize: 16,
                    ),
                    convDateTime().convStrToDate(apiContent?['data']['date'])),
                Text(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    apiContent?['data']['title']),
                const SizedBox(height: 24),
                const Divider(),
                HtmlWidget(apiContent?['data']['text']),
              ],
            ));
  }
}

class getApi {
  getApi(this.dateCont, this.tipCont);
  final String dateCont;
  final String tipCont;
  Future<List> getContent() async {
    final response = await Dio()
        .get('https://sarnovosti.ru/api/list.php?from=$dateCont$tipCont');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Error loading data from API');
    }
  }
}

class getApiContent {
  getApiContent(this.idCont);
  final String idCont;

  Future<Map> getContent() async {
    final response =
        await Dio().get('https://sarnovosti.ru/api/news.php?id=$idCont');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Error loading data from API');
    }
  }
}

class convDateTime {
  String convStrToDate(String dateTimeString) {
    final formatter = DateFormat('dd-MM-yy-HH-mm-SS');
    final List<String> d = dateTimeString.split('');
    final String dateFormat =
        '${d[0]}${d[1]}-${d[2]}${d[3]}-${d[4]}${d[5]}-${d[6]}${d[7]}-${d[8]}${d[9]}-${d[10]}${d[11]}';
    final datetime = formatter.parse(dateFormat);
    final formattedFormatter = DateFormat('dd.MM.yy HH:mm');

    return formattedFormatter.format(datetime);
  }
}

class imageNet extends StatelessWidget {
  const imageNet(this.urlImage, {super.key});
  final urlImage;

  @override
  Widget build(BuildContext context) {
    return (urlImage == null)
        ? const SizedBox(height: 1)
        : SizedBox(
            height: 250,
            child: ClipRect(
              child: Image.network(
                urlImage,
                fit: BoxFit.cover,
              ),
            ));
  }
}

class infoWidget extends StatelessWidget {
  const infoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
            child:
                Text('Тестовое мобильная разработка: новостное приложение')));
  }
}
