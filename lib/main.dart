import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'Topic.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'MyColors.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:share_plus/share_plus.dart';

import 'package:html/parser.dart' as parser;
import 'package:webview_flutter/webview_flutter.dart';

import 'dart:ui' as ui;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'خبر گردون',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a blue toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          primarySwatch: MyColors.primaryColor,
          primaryColor: MyColors.appbar,
          fontFamily: 'IranSans',
          colorScheme: ColorScheme.fromSeed(seedColor: MyColors.primaryColor),
          useMaterial3: true,
        ),
        home: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: MyHomePage(),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool isSplashing = true;
  late AnimationController _animationController;
  late AnimationController _controllerAnim;
  WebViewController? _webViewController;
  late TabController _controller = TabController(length: 9, vsync: this);
  late ScrollController _scrollController;
  late List<RssItem> feeds = [];
  late List<DateTime?> dates = [];

  String? url;
  String? html;

  String RssMostViewed = "https://www.khabargardoon.ir/fa/rss/all/mostvisited";
  List<RssItem> mostViewedfeeds = [];

  Topic topic1 = Topic(
      name: "آخرین اخبار", url: "https://www.khabargardoon.ir/fa/rss/allnews");
  Topic topic2 =
      Topic(name: "اقتصادی", url: "https://www.khabargardoon.ir/fa/rss/2");
  Topic topic3 =
      Topic(name: "جامعه", url: "https://www.khabargardoon.ir/fa/rss/3");
  Topic topic4 =
      Topic(name: "حوادث", url: "https://www.khabargardoon.ir/fa/rss/3/14");

  Topic topic5 =
      Topic(name: "سلامت", url: "https://www.khabargardoon.ir/fa/rss/3/15");

  Topic topic6 =
      Topic(name: "ورزشی", url: "https://www.khabargardoon.ir/fa/rss/4");

  Topic topic7 =
      Topic(name: "ویدئو", url: "https://www.khabargardoon.ir/fa/rss/5");

  Topic topic8 =
      Topic(name: "فرهنگ و هنر", url: "https://www.khabargardoon.ir/fa/rss/6");

  Topic topic9 =
      Topic(name: "گوناگون", url: "https://www.khabargardoon.ir/fa/rss/7");

  late List<Topic> topics_list = [
    topic1,
    topic2,
    topic3,
    topic4,
    topic5,
    topic6,
    topic7,
    topic8,
    topic9
  ];

  int _selectedIndex = 0;
  bool isLoading = false;

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  DateTime? convertDate(String? originalDateString) {
    if (originalDateString == null) return null;

    DateFormat originalFormat = DateFormat('dd MMM yyyy HH:mm:ss Z');
    DateTime dateTime = originalFormat.parse(originalDateString!, true).toUtc();

    //DateFormat desiredFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
    // String formattedDateString = desiredFormat.format(dateTime);

    return dateTime;
  }

  Future<void> loadHtml(String? _url) async {
    if (_url == null) {
      return;
    }

    await loadMostViewed();

    await fetchHtmlContent(_url!).then((htmlContent) {
      setState(() {
        url = _url;
      });
      setState(() => html = extractContent(htmlContent));
    });
  }

  Future<String> fetchHtmlContent(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load HTML content');
    }
  }

  String updateLinks(String htmlContent) {
    var withImage =
        htmlContent.replaceAll('/files', 'https://www.khabargardoon.ir/files');
    ;
    return withImage;
  }

  Widget displayHtmlContent(String htmlContent) {
    String updatedHtmlContent = updateLinks(htmlContent);

    String encodedHtmlContent =
        base64Encode(const Utf8Encoder().convert(updatedHtmlContent));

    return WebView(
      initialUrl: 'data:text/html;base64,$encodedHtmlContent',
      javascriptMode: JavascriptMode.disabled,
      onWebViewCreated: (WebViewController webViewController) {
        _webViewController = webViewController;
      },
      navigationDelegate: (NavigationRequest request) async {
        if (request.url.startsWith('https://www.khabargardoon.ir')) {
          setState(() {
            url = null;
            isLoading = true;
          });

          await loadHtml(request.url);

          setState(() {
            isLoading = false;
          });
          return NavigationDecision.prevent;
        }

        return NavigationDecision.prevent;
      },
    );
  }

  String renderMostViewedTable() {
    return '<h3 class="mostVheader" >پربازدیدها</h3><div class="mostVtable">' +
        mostViewedfeeds
            .take(5)
            .map((e) => '&#x1F534; <a href="${e.link}">${e.title}</a>')
            .join('<br/>') +
        '</div>';
  }

  String extractContent(String htmlContent) {
    var document = parser.parse(htmlContent);

    // Extract content from the div with class "newsMainCnt"
    var newsMainCnt = document.querySelector('.newsMainCnt')?.innerHtml ?? '';

    // Extract content from the div with id "newsMainBody"
    var newsMainBody = document.querySelector('#newsMainBody')?.innerHtml ?? '';

    var relatedNews =
        document.querySelector('.newsContent .newsBoxes.mbNews16')?.innerHtml ??
            '';
    var relatedNewsList = relatedNews.replaceAll(
        '/fa/news', 'https://www.khabargardoon.ir/fa/news');

    return '<!DOCTYPE html><html><head><style>  .authorLabel , .authorName{font-size: 36px; font-weight: bold; color: #000;}  .mostVtable,.relatedNewsRow{padding: 25px; background-color: #D9D9D9; margin-top: 0px; margin-bottom: 35px; }  .mostVtable a  ,  .relatedNewsRow a{ text-decoration: none;  color: black; font-size: 34px; font-weight: bold; } *{font-family: Tahoma, Geneva, sans-serif;}  .mostVheader{ margin: 15px; width: 175px; line-height: 40px; padding: 15px; background-color: #ed1b24; color: white; font-size: 36px; height: 40px; font-weight: bold; margin-bottom: 0px; padding-bottom: 15px; text-align: center; }   .subtitle{padding: 25px; background-color: #D9D9D9;} .newsTagsRow ,.video_share_tag_box, .video-tool-box ,.newsBottomBar,.specialNewsBox,.headNewsTitle{display: none;} p { text-align: justify; font-size: 36px; font-weight: bold; } h1 { text-align: center; font-size: 46px; }  html, body { margin: 15px; padding: 15px; direction: rtl; } .subtitle{ font-size: 36px; font-weight: bold;} img { padding-top: 25px !important; padding-bottom: 25px; max-width: 100%; height: auto; }img{margin:0 auto;width:100%; text-align:center;} video{margin:0 auto;width:100%; text-align:center;} .newsTitle{text-align:right}</style></head><body>' +
        newsMainCnt +
        ' <br> ' +
        newsMainBody +
        renderMostViewedTable() +
        '<h3 class="mostVheader" >اخبار مرتبط</h3>' + relatedNewsList +
        '</body></html>';
  }

  @override
  void dispose() {
    _controllerAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(seconds: 1), curve: Curves.linear);
  }

  Future<void> _refresh() async {
    refresh(_selectedIndex);
  }

  TabBar get _tabBar => TabBar(
        isScrollable: true,
        indicatorColor: Colors.black,
        // indicatorColor:
        //     (_selectedIndex > 3) ? Colors.transparent : Colors.white,
        onTap: (index) {
          setState(() {
            url = null;
          });
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });
            refresh(_selectedIndex);
          }
        },
        controller: _controller,
        tabs: [
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![0].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 0)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![1].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 1)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![2].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 2)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![3].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 3)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![4].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 4)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![5].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 5)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![6].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 6)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![7].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 7)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
          Tab(
              child: (topics_list.isNotEmpty)
                  ? Text(topics_list![8].name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_selectedIndex == 8)
                            ? Colors.white
                            : MyColors.primaryColor.shade900,
                        fontSize: 13,
                      ))
                  : const SizedBox()),
        ],
      );

  String format1(Date d) {
    final f = d.formatter;

    return '${f.wN} ${f.d} ${f.mN} ${f.yyyy}';
  }

  String jalal(DateTime? pubDate) {
    if (pubDate == null) return "";

    Gregorian g1 =
        Gregorian(pubDate.year, pubDate.month, pubDate.day, 0, 0, 0, 0);
    Jalali j1 = g1.toJalali();
    return format1(j1);
  }

  List<DateTime?> getDates(String xmlString) {
    List<DateTime?> dates = [];

    var document = XmlDocument.parse(xmlString);
    var rss = document.findElements('rss').firstOrNull;
    var rdf = document.findElements('rdf:RDF').firstOrNull;
    if (rss == null && rdf == null) {
      throw ArgumentError('not a rss feed');
    }
    var channelElement = (rss ?? rdf)!.findElements('channel').firstOrNull;
    if (channelElement == null) {
      throw ArgumentError('channel not found');
    }

    dates = (rdf ?? channelElement)
        .findElements('item')
        .map((e) => convertDate(e.findElements('pubDate').firstOrNull?.text))
        .toList();

    return dates;
  }

  Future<void> loadMostViewed() async {
    final client = http.Client();

    final response = await client.get(Uri.parse(RssMostViewed));

    String decodedBody = utf8.decode(response.bodyBytes);

    var feed = await RssFeed.parse(decodedBody);

    if (feed.items != null) {
      setState(() {
        mostViewedfeeds = feed.items as List<RssItem>;
      });
    }
  }

  void refresh(int index) async {
    isLoading = true;
    setState(() {});
    final client = http.Client();

    final response = await client.get(Uri.parse(topics_list[index].url));

    String decodedBody = utf8.decode(response.bodyBytes);

    var feed = await RssFeed.parse(decodedBody);

    if (feed.items != null) {
      setState(() {
        feeds = feed.items as List<RssItem>;
      });
      List<DateTime?> _dates = await getDates(decodedBody);
      setState(() {
        dates = _dates;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this);

    isLoading = true;
    _controller.addListener(() {
      setState(() {
        _selectedIndex = _controller.index;
      });
      refresh(_selectedIndex);
    });

    _scrollController = ScrollController()..addListener(() {});

    refresh(_selectedIndex);

    _controller = TabController(vsync: this, length: topics_list.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToTab(2); // Always start at the first tab
    });
  }

  void scrollToTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _controller.length) {
      _controller.animateTo(tabIndex,
          duration: Duration(milliseconds: 500), curve: Curves.easeOut);
    }
  }

  Future<bool> _onWillPop() async {
    if (url == null) {
      return true;
    }

    setState(() {
      url = null;
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return (isSplashing)
        ? Center(
            child: Container(
              width: double.infinity, // Full width
              height: double.infinity, // Full height
              color: Colors.white, // Background color of the container
              child: Center(
                  // Center the text within the container
                  child: Lottie.asset(
                'images/logomotion.mp4.lottie.json',
                controller: _animationController,
                onLoaded: (composition) {
                  _animationController
                    ..duration = composition.duration
                    ..forward().whenComplete(() => setState(() {
                          isSplashing = false;
                        }));
                },
              )),
            ),
          )
        : WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
              appBar: AppBar(
                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.

                title: Row(children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          url = null;
                        });
                        refresh(_selectedIndex);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'images/logo.png',
                          width: 120.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: MyColors
                            .primaryColor.shade100, // Set the color here
                      ),
                      child: _tabBar, // Assuming _tabBar is your widget
                    ),
                  ),
                ]),
              ),

              body: (!isLoading)
                  ? (url == null)
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            displacement: 200.0,
                            child: SingleChildScrollView(
                                controller: _scrollController,
                                child: Column(children: [
                                  // Padding(
                                  //   padding: const EdgeInsets.all(8.0),
                                  //   child: Container(
                                  //     color: MyColors.primaryColor.shade50,
                                  //     child: ListTile(
                                  //       leading: const Icon(Icons.arrow_left),
                                  //       title: Text(
                                  //         rss_list[_selectedIndex].name.toString(),
                                  //         textScaleFactor: 1,
                                  //         textAlign: TextAlign.center,
                                  //         style: TextStyle(fontWeight: FontWeight.bold),
                                  //       ),
                                  //       trailing: const Icon(Icons.arrow_right),
                                  //       selected: true,
                                  //     ),
                                  //   ),
                                  // ),
                                  ...feeds.asMap().entries.map<Widget>((entry) {
                                    int index = entry
                                        .key; // This is the index of the current item
                                    var e = entry
                                        .value; // This is the current item itself

                                    return Container(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: GestureDetector(
                                          onTap: () => {
                                                // _launchInBrowser(Uri.parse(e.link!))

                                                loadHtml(e.link!)

                                                /*   Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              News(
                                                                  url:
                                                                      e.link!)),
                                                    )*/
                                              },
                                          child: Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            color: Colors.white,
                                            child: Container(
                                                padding:
                                                    new EdgeInsets.all(6.0),
                                                child: Row(children: [
                                                  Expanded(
                                                    flex: 4,
                                                    child: Container(
                                                        width: 150.0,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: (e.enclosure !=
                                                                      null &&
                                                                  e.enclosure!
                                                                          .url !=
                                                                      null)
                                                              ? Image.network(e
                                                                  .enclosure!
                                                                  .url!
                                                                  .toString())
                                                              : Image.asset(
                                                                  'images/logo.png',
                                                                  width: 150.0,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                        )),
                                                  ),
                                                  Expanded(
                                                      flex: 5,
                                                      child: Container(
                                                        width: 200.0,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Text(
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                              e.title!,
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                            ),
                                                            SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text(
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: MyColors
                                                                    .txtcolorlistcaption,
                                                              ),
                                                              jalal(
                                                                  dates[index]),
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                            )
                                                          ],
                                                        ),
                                                      )),
                                                  Expanded(
                                                      flex: 1,
                                                      child: SizedBox(
                                                          height: 18.0,
                                                          width: 18.0,
                                                          child: IconButton(
                                                            padding:
                                                                new EdgeInsets
                                                                    .all(0.0),
                                                            icon: const Icon(
                                                                Icons.share,
                                                                color: MyColors
                                                                    .txtcolorlistcaption,
                                                                size: 18.0),
                                                            tooltip:
                                                                'اشتراک گذاری',
                                                            onPressed: e.link ==
                                                                    null
                                                                ? null
                                                                : () => Share
                                                                    .share(e
                                                                        .link!),
                                                          ))),
                                                ])),
                                          )),
                                    );
                                  }).toList(),
                                ])),
                          ))
                      : ((html != null)
                          ? Column(children: [
                              Expanded(child: displayHtmlContent(html!)),
                              GestureDetector(
                                  onTap: url == null
                                      ? null
                                      : () => Share.share(url!),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.share,
                                            color: MyColors.txtcolorlistcaption,
                                            size: 18.0),
                                        SizedBox(
                                          width: 5.0,
                                        ),
                                        Text('اشتراک گذاری'),
                                      ]))
                            ])
                          : const Center(child: CircularProgressIndicator()))
                  : Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFed1b24))),
                        Text('درحال خواندن اخبار...')
                      ],
                    )),

              floatingActionButton: FloatingActionButton(
                backgroundColor: MyColors.primaryColor.shade100,
                foregroundColor: Colors.white,
                onPressed: () => {
                  _scrollToTop(),
                  refresh(_selectedIndex),
                  setState(() {
                    url = null;
                  })
                },
                child: (url == null)? Icon(Icons.refresh) :Icon(Icons.arrow_forward) ,
              ), // This trailing comma makes auto-formatting nicer for build methods.
            ));
    // This trailing comma makes auto-formatting nicer for build methods.
  }
}
