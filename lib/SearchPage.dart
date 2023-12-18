
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Product.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controller for handling scrolling
  final ScrollController _scrollController = ScrollController();
  // Controller for handling text input in the search bar
  final TextEditingController _searchController = TextEditingController();
  // List to store search results (products)
  List<Product> results = [];
  // List to store product quantities with their respective barcodes
  List<Tuple2<String, int>> productQuantities = [];

  // Method to increment the quantity of a product in the cart
  void _incrementQuantity(String barcode) {
    setState(() {
      // Find the index of the product in the productQuantities list
      int index = productQuantities.indexWhere((tuple) => tuple.item1 == barcode);
      if (index != -1) {
        productQuantities[index] = Tuple2(barcode, productQuantities[index].item2 + 1);
      } else {
        // If the product is not in the list, add it with quantity 1
        productQuantities.add(Tuple2(barcode, 1));
      }
    });
  }

//   // Method to update the quantity of a product in the cart
// void _updateQuantity(String barcode, int newQuantity) {
//   setState(() {
//     // Find the index of the product in the productQuantities list
//     int index = productQuantities.indexWhere((tuple) => tuple.item1 == barcode);
//     if (index != -1) {
//       // If the product is in the list, update the quantity
//       productQuantities[index] = Tuple2(barcode, newQuantity);
//     } else {
//       // If the product is not in the list, add it with the new quantity
//       productQuantities.add(Tuple2(barcode, newQuantity));
//     }
//   });
// }


// Method to decrement the quantity of a product in the cart
void _decrementQuantity(String barcode) {
  setState(() {
    // Find the index of the product in the productQuantities list
    int index = productQuantities.indexWhere((tuple) => tuple.item1 == barcode);
    if (index != -1) {
      if (productQuantities[index].item2 > 0) {
        // If the quantity is greater than 0, decrement the quantity
        productQuantities[index] = Tuple2(barcode, productQuantities[index].item2 - 1);
      } else {
        // If the quantity becomes 0 or less, remove the product from the list
        productQuantities.removeAt(index);
      }
    }
  });
}

  // Method to add the products with quantities to the cart
  void _addToCart() {
    // Implement the logic to send a POST request with productQuantities to the API
    // ...

    // After successfully adding to the cart, clear the productQuantities
    setState(() {
      productQuantities.clear();
    });
  }

  // Method to search for products based on the provided query
  void _searchProducts(String query) async {
    const apiUrl = 'http://10.0.2.2:8000/api/products';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // Decode the response body into a list of dynamic objects
      final List<dynamic> data = json.decode(response.body);
      // Convert the dynamic objects into a list of Product objects using the factory method
      final List<Product> products =
          List.from(data.map((product) => Product.fromJson(product)));

      // Filter products based on the provided search query
      final filteredProducts = products.where((product) {
        // Convert the search query and product attributes to lowercase for case-insensitive comparison
        final lowerCaseQuery = query.toLowerCase();
        return product.name.toLowerCase().contains(lowerCaseQuery) ||
            product.manufacturer.toLowerCase().contains(lowerCaseQuery);
      }).toList();

      // Update the state with the filtered products
      setState(() {
        results = filteredProducts;
      });
    } else {
      // Handle errors when fetching products
      throw ('Failed to load products. Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build a column widget containing search bar, results, and cart sections
    return Column(
      children: [
        // Search bar section
        Padding(
          padding: const EdgeInsets.all(8.0), //pading from the sides 
          child: TextField(
            controller: _searchController,
            onChanged: (query) { //all the serch methode
              _searchProducts(query);
            },
            decoration: const InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        // Results section
        // Expanded widget ensures that the child takes up all available vertical space
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: results
                  .map(
                    (product) => Column(
                      children: [
                        ListTile(
                          title: Text(product.name),
                          subtitle: Text(product.manufacturer),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(product.imageLink),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  _decrementQuantity(product.barcode);
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  // Display the quantity of the product
                                  productQuantities
                                      .firstWhere(
                                        (tuple) => tuple.item1 == product.barcode,
                                        orElse: () => Tuple2(product.barcode, 0),
                                      )
                                      .item2
                                      .toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _incrementQuantity(product.barcode);
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        // Add to Cart button
        ElevatedButton(
          onPressed: _addToCart,
          child: const Text('ADD TO CART'),
        ),
      ],
    );
  }
}

// Tuple class to store pairs of values
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
