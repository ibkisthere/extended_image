import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http_client_helper/http_client_helper.dart';
import 'package:loading_more_list_library/loading_more_list_library.dart';

import 'mock_data.dart';
import 'tu_chong_source.dart';

Future<bool> onLikeButtonTap(bool isLiked, TuChongItem item) {
  ///send your request here
  return Future<bool>.delayed(const Duration(milliseconds: 50), () {
    item.isFavorite = !item.isFavorite!;
    item.favorites =
        item.isFavorite! ? item.favorites! + 1 : item.favorites! - 1;
    return item.isFavorite!;
  });
}

class TuChongRepository extends LoadingMoreBase<TuChongItem> {
  TuChongRepository({this.maxLength = 300});
  int _pageIndex = 1;
  bool _hasMore = true;
  bool forceRefresh = false;
  @override
  bool get hasMore => (_hasMore && length < maxLength) || forceRefresh;
  final int maxLength;

  @override
  Future<bool> refresh([bool notifyStateChanged = false]) async {
    _hasMore = true;
    _pageIndex = 1;
    //force to refresh list when you don't want clear list before request
    //for the case, if your list already has 20 items.
    forceRefresh = !notifyStateChanged;
    final bool result = await super.refresh(notifyStateChanged);
    forceRefresh = false;
    return result;
  }

  @override
  Future<bool> loadData([bool isLoadMoreAction = false]) async {
    String url = '';
    if (isEmpty) {
      url = 'https://api.tuchong.com/feed-app';
    } else {
      final int? lastPostId = this[length - 1].postId;
      url =
          'https://api.tuchong.com/feed-app?post_id=$lastPostId&page=$_pageIndex&type=loadmore';
    }
    bool isSuccess = false;
    try {

      //to show loading more clearly, in your app,remove this
      //await Future.delayed(const Duration(milliseconds: 500));
      // i got this error in my terminal,maybe we can even try to fix it 
//       type 'Null' is not a subtype of
// type 'Response' in type cast
// [   +1 ms] I/flutter (15777): #0      TuChongRepository.loadData
// (package:example/common/data/tu_chong_repository.dart:59:56)
// [        ] I/flutter (15777): <asynchronous suspension>
// [        ] I/flutter (15777): #1
// LoadingMoreBase._innerloadData
// (package:loading_more_list_library/src/loading_more_list_library
// .dart:52:28)
// [        ] I/flutter (15777): <asynchronous suspension>
// [        ] I/flutter (15777): #2      LoadingMoreBase.refresh
// (package:loading_more_list_library/src/loading_more_list_library
// .dart:80:12)
// [        ] I/flutter (15777): <asynchronous suspension>
// [        ] I/flutter (15777): #3      TuChongRepository.refresh
// (package:example/common/data/tu_chong_repository.dart:37:25)
// [        ] I/flutter (15777): <asynchronous suspension>
      List<TuChongItem>? feedList;
      if (!kIsWeb) {
        final Response result =
            await HttpClientHelper.get(Uri.parse(url)) as Response;
        feedList = TuChongSource.fromJson(
                json.decode(result.body) as Map<String, dynamic>)
            .feedList;
      } else {
        feedList = mockSource.feedList!.getRange(length, length + 20).toList();
      }

      if (_pageIndex == 1) {
        clear();
      }

      for (final TuChongItem item in feedList!) {
        if (item.hasImage && !contains(item) && hasMore) {
          add(item);
        }
      }

      _hasMore = feedList.isNotEmpty;
      _pageIndex++;
      isSuccess = true;
    } catch (exception, stack) {
      isSuccess = false;
      print(exception);
      print(stack);
    }
    return isSuccess;
  }
}
