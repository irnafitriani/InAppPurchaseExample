import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_flutter_example/src/google_play_store.dart';

import '../store_config.dart';

class PurchaseTester extends StatelessWidget {
  const PurchaseTester({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RevenueCat Sample',
      home: InitialScreen(),
    );
  }
}

// ignore: public_member_api_docs
class InitialScreen extends StatefulWidget {
  const InitialScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<InitialScreen> {
  CustomerInfo _customerInfo;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await Purchases.setDebugLogsEnabled(true);

    PurchasesConfiguration configuration;
    if (StoreConfig.isForAmazonAppstore()) {
      configuration = AmazonConfiguration(StoreConfig.instance.apiKey);
    } else {
      configuration = PurchasesConfiguration(StoreConfig.instance.apiKey);
    }
    await Purchases.configure(configuration);

    await Purchases.enableAdServicesAttributionTokenCollection();

    final customerInfo = await Purchases.getCustomerInfo();

    Purchases.addReadyForPromotedProductPurchaseListener(
        (productID, startPurchase) async {
      print('Received readyForPromotedProductPurchase event for '
          'productID: $productID');

      try {
        final purchaseResult = await startPurchase.call();
        print('Promoted purchase for productID '
            '${purchaseResult.productIdentifier} completed, or product was'
            'already purchased. customerInfo returned is:'
            ' ${purchaseResult.customerInfo}');
      } on PlatformException catch (e) {
        print('Error purchasing promoted product: ${e.message}');
      }
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _customerInfo = customerInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_customerInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RevenueCat Sample App')),
        body: const Center(
          child: Text('Loading...'),
        ),
      );
    } else {
      final isPro = _customerInfo.entitlements.active.containsKey('pro_cat');
      if (isPro) {
        return const CatsScreen();
      } else {
        return const UpsellScreen();
      }
    }
  }
}

// ignore: public_member_api_docs
class UpsellScreen extends StatefulWidget {
  const UpsellScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UpsellScreenState();
}

class _UpsellScreenState extends State<UpsellScreen> {
  Offerings _offerings;
  List<Offering> _listOffering;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    Offerings offerings;
    List<Offering> listOffering;
    try {
      offerings = await Purchases.getOfferings();
      listOffering = offerings.all.values.toList();

    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _offerings = offerings;
      _listOffering = listOffering;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_listOffering != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Upsell Screen')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _PurchaseButton(package: _listOffering[0].lifetime),
                  _PurchaseButton(package: _listOffering[1].lifetime)
                ],
              ),
            ),
          );
        
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Upsell Screen')),
      body: const Center(
        child: Text('Loading...'),
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final Package package;

  // ignore: public_member_api_docs
  const _PurchaseButton({Key key, @required this.package}) : super(key: key);

  Future<QueryResult<Object>> mutateWithVariables(
      {Map<String, dynamic> variables}) async {
        print('mulai');
    final HttpLink httpLink = HttpLink(
      'https://api.dev.munalively.com/graphql',
      defaultHeaders: {
        'Authorization' : 'Bearer eyJ0eXAiOiJKV1QiLCJraWQiOiJ3VTNpZklJYUxPVUFSZVJCL0ZHNmVNMVAxUU09IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJjYmIzYmJjZi0yZjM2LTQ0YzYtYTEzMS1hMDRlOTQ2NWQ3ZWIiLCJjdHMiOiJPQVVUSDJfR1JBTlRfU0VUIiwiYXV0aF9sZXZlbCI6MCwiYXVkaXRUcmFja2luZ0lkIjoiNDU5ZTBjOGQtMWU2Yy00NWViLWI2MjUtMTk1MGIxYTE5YWMzLTEwNjM3MSIsImlzcyI6Imh0dHBzOi8vY2lhbWFtcHJlcGRhcHAuY2lhbS50ZWxrb21zZWwuY29tOjEwMDAzL29wZW5hbS9vYXV0aDIvdHNlbC9maXRhL21vYmlsZSIsInRva2VuTmFtZSI6ImFjY2Vzc190b2tlbiIsInRva2VuX3R5cGUiOiJCZWFyZXIiLCJhdXRoR3JhbnRJZCI6Im5vbVBhbGg4dHdyck94b0QtYkxVYWxfdjEtQS43aEdBSWZZN1lsUjFNakxRTGVpdVVkRHJiN1kiLCJub25jZSI6InRydWUiLCJhdWQiOiIxZmRkYmNiZmYzNmE0ZWMwOGI1NWRkYjdiMjI3ZDYwYyIsIm5iZiI6MTY2OTI2NjY0NCwiZ3JhbnRfdHlwZSI6ImF1dGhvcml6YXRpb25fY29kZSIsInNjb3BlIjpbIm9wZW5pZCIsInByb2ZpbGUiXSwiYXV0aF90aW1lIjoxNjY5MjY2NjQzLCJyZWFsbSI6Ii90c2VsL2ZpdGEvbW9iaWxlIiwiZXhwIjoxNjY5MzUzMDQ0LCJpYXQiOjE2NjkyNjY2NDQsImV4cGlyZXNfaW4iOjg2NDAwLCJqdGkiOiJub21QYWxoOHR3cnJPeG9ELWJMVWFsX3YxLUEuY3EyelRkU0d4RldFVi1talNmaFdzRmMyLWhBIn0.ZPLFl4RAqS_2AfXnufLdUN0UWt9sKWSP7rTXvG58Bj-XDeW0uv9JPkw461Z_BPyq8TN8EFCiy1x-SjP7NpwGMg6KDp-Zy42xrwUxXaDbyZrnyZuX7H91ji_L7KVAr7Pcw6-i9avoxZfvFRsf7TSf-IGpnAHSEDYf1Y6aQLdyJxgvCS2pd-kmG4Z9SqK51X0zX6EIsdstV8xDwrratZc2W6zgh4wBlGZHAsR2pjHWXzO7SBVXBRh2LBswQiGnQ5mqZK8PVmk-tZxJgsXK4I5Bw8P44_M-B_3ni-hUStVdvUoS_02op8FbFt3odd2x6hctuPVOoac8Qx9Ndh4NVFidzQ'
      }
    );
    final GraphQLClient client = GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: httpLink,
    );
    const Duration requestTimeout = Duration(seconds: 10);
    final MutationOptions<Object> options = MutationOptions<String>(
        document: gql(googlePlayPurchaseProduct),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly);
    final Future<QueryResult<Object>> result =
        client.mutate(options).timeout(requestTimeout, onTimeout: _onTimeout);

        print('result $result');
    return result;
  }

  QueryResult<String> _onTimeout() {
    final QueryResult<String> queryResult = QueryResult<String>.internal(
      source: QueryResultSource.network,
      exception: OperationException(graphqlErrors: [
        const GraphQLError(
          extensions: {'error': 'error timeout'},
          message: 'error timeout',
        )
      ]),
      parserFn: (Map<String, dynamic> data) => null,
    );

    return queryResult;
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: () async {
          try {
            final customerInfo = await Purchases.purchasePackage(package);
            mutateWithVariables(variables: {'productId': package.identifier});
            final isPro = customerInfo.entitlements.all['pro_cat'].isActive;
            if (isPro) {
              return const CatsScreen();
            }
          } on PlatformException catch (e) {
            final errorCode = PurchasesErrorHelper.getErrorCode(e);
            if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
              print('User cancelled');
            } else if (errorCode ==
                PurchasesErrorCode.purchaseNotAllowedError) {
              print('User not allowed to purchase');
            } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
              print('Payment is pending');
            }
          }
          return const InitialScreen();
        },
        child: Text('Buy ${package.storeProduct.title} - (${package.storeProduct.priceString})'),
      );
}

// ignore: public_member_api_docs
class CatsScreen extends StatelessWidget {
  const CatsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cats Screen')),
        body: const Center(
          child: Text('User is pro'),
        ),
      );
}
