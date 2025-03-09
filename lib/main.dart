import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const InfiniteScrollList(),
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<dynamic> _cart = [];

  List<dynamic> get cartItems => _cart;

  double get totalAmount => _cart.fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble());

  void addToCart(dynamic item) {
    _cart.add(item);
    notifyListeners();
  }

  void removeFromCart(BuildContext context, dynamic item) {
    _cart.remove(item);
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item['title']} removed from cart"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class InfiniteScrollList extends StatefulWidget {
  const InfiniteScrollList({super.key});

  @override
  _InfiniteScrollListState createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<InfiniteScrollList> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await Dio().get('https://fakestoreapi.com/products');
      if (response.statusCode == 200) {
        setState(() {
          _items.addAll(response.data);
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !_isLoading) {
      _fetchData();
    }
  }

  void _goToCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll List'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _goToCartPage,
              ),
              if (cartProvider.cartItems.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cartProvider.cartItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index < _items.length) {
            final item = _items[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Image.network(
                  item['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                title: Text(
                  item['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Price: \$${item['price'].toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () => cartProvider.addToCart(item),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text("Add"),
                ),
              ),
            );
          } else {
            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartProvider.cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartProvider.cartItems[index];
                return ListTile(
                  leading: Image.network(item['image'], width: 50, height: 50),
                  title: Text(item['title']),
                  subtitle: Text("Price: \$${item['price']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => cartProvider.removeFromCart(context, item),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Total: \$${cartProvider.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
