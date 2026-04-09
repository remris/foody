import 'package:kokomu/models/inventory_item.dart';
import 'package:kokomu/models/product_details.dart';

abstract class ScannerRepository {
  Future<Ingredient?> lookupBarcode(String barcode);
  Future<ProductDetails?> lookupProductDetails(String barcode);
}

