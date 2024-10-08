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
      title: 'Новости Саратова',
      home: MyHomePage(),
    );
  }
}

//скелет основного экрана с 3-мя вкладками
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
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
        backgroundColor: const Color(0xFF0f1b25),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            iconSize: 33.0,
            icon: const Icon(Icons.info_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Information(),
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
          unselectedLabelColor: Colors.white,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 2.5,
          indicatorPadding: const EdgeInsets.all(7.0),
          labelStyle: const TextStyle(fontFamily: 'Time', fontSize: 22),
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'лента'),
            Tab(text: 'важное'),
            Tab(text: 'статьи'),
          ],
        ),
      ),
      body: TabBarView(
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
    testX = await GetApi('0', widget.tipCont).getContent();
    setState(() {});
  }

  Future<void> refresh() async {
    isRefreshing = true;
    loadNews();

    await Future.delayed(const Duration(seconds: 1));
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
                  testX?.addAll(await GetApi(
                          testX?[testX!.length - 1]['date'], widget.tipCont)
                      .getContent());
                  setState(() {});

                  return true;
                },
                child: ListView.separated(
                  itemBuilder: (context, index) => ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Contentwidget(idContent: testX?[index]['id']),
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
                                  ConvDateTime()
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
                          const SizedBox(width: 3),
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

class Contentwidget extends StatefulWidget {
  final String idContent;
  const Contentwidget({super.key, required this.idContent});

  @override
  State<Contentwidget> createState() => _ContentwidgetState();
}

class _ContentwidgetState extends State<Contentwidget> {
  Map? apiContent;

  @override
  void initState() {
    loadNews();
    super.initState();
  }

  void loadNews() async {
    apiContent = await GetApiContent(widget.idContent).getContent();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return (apiContent == null)
        ? const Scaffold(body: Center(child: Text('Загрузка')))
        : Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF0f1b25),
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
                ImageNet(apiContent?['data']['img']),
                const SizedBox(height: 32),
                Text(
                    style: const TextStyle(
                      color: Color(0xFFAE0F38),
                      fontSize: 16,
                    ),
                    ConvDateTime().convStrToDate(apiContent?['data']['date'])),
                Text(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    apiContent?['data']['title']),
                const SizedBox(height: 24),
                const Divider(),
                HtmlWidget(
                  apiContent?['data']['text'],
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ],
            ));
  }
}

class GetApi {
  GetApi(this.dateCont, this.tipCont);
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

class GetApiContent {
  GetApiContent(this.idCont);
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

class ConvDateTime {
  String convStrToDate(String dateTimeString) {
    final formatter = DateFormat('dd-MM-yy-HH-mm-SS');
    final List<String> d = dateTimeString.split('');
    final String dateFormat =
        '${d[0]}${d[1]}-${d[2]}${d[3]}-${d[4]}${d[5]}-${d[6]}${d[7]}-${d[8]}${d[9]}-${d[10]}${d[11]}';
    final datetime = formatter.parse(dateFormat);
    final formattedFormatter = DateFormat('dd MMMM, ');
    final formattedFormatter1 = DateFormat('HH:mm');
    final nowDate = DateFormat('dd MMMM, ').format(DateTime.now());
    String ddMMMM = ((formattedFormatter.format(datetime) == nowDate)
        ? ''
        : formattedFormatter.format(datetime));

    return ddMMMM + formattedFormatter1.format(datetime);
  }
}

class ImageNet extends StatelessWidget {
  const ImageNet(this.urlimage, {super.key});
  final dynamic urlimage;

  @override
  Widget build(BuildContext context) {
    return (urlimage == null)
        ? const SizedBox(height: 1)
        : SizedBox(
            height: 250,
            child: ClipRect(
              child: Image.network(
                urlimage,
                fit: BoxFit.cover,
              ),
            ));
  }
}

class Information extends StatelessWidget {
  const Information({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0f1b25),
          foregroundColor: Colors.white,
        ),
        body: const Center(
            child:
                Text('Тестовое мобильная разработка: новостное приложение')));
  }
}
