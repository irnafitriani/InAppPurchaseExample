const String googlePlayPurchaseProduct = r'''
mutation googlePlayPurchaseProduct($purchase_token: String!, $productId: String!){
  googlePlayPurchaseProduct(purchase_token: $purchase_token, id: $productId){
    id
  }
}''';
