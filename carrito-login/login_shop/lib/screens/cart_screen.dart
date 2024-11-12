import 'package:flutter/material.dart';
import 'package:login_shop/helpers/email_service.dart';
import '../helpers/db_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  bool isProcessingPayment = false;
  double total = 0.0;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    loadCartItems();
    loadUserEmail();
  }

  Future<void> loadUserEmail() async {
    final user = await DatabaseHelper().getUserById(widget.userId);
    if (user != null) {
      setState(() {
        userEmail = user['email'] as String;
      });
    }
  }

  Future<void> loadCartItems() async {
    final items = await DatabaseHelper().getCartItems(widget.userId);
    double sum = 0.0;
    for (var item in items) {
      sum += (item['price'] as double) * (item['quantity'] as int);
    }
    setState(() {
      cartItems = items;
      total = sum;
      isLoading = false;
    });
  }

  Future<void> _processPurchase() async {
    if (userEmail == null) {
      Fluttertoast.showToast(
        msg: "Error: No se pudo obtener el email del usuario",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Enviar correo de confirmación
      await EmailService.sendPurchaseConfirmation(
        userEmail!,
        cartItems,
        total,
      );

      // Limpiar el carrito
      await DatabaseHelper().clearCart(widget.userId);

      // Recargar los items del carrito
      await loadCartItems();

      Fluttertoast.showToast(
        msg: "¡Compra realizada con éxito! Revisa tu correo para ver los detalles.",
        backgroundColor: Colors.green,
        timeInSecForIosWeb: 4,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al procesar la compra: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.blue.shade200],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : cartItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay productos en el carrito',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Image.network(
                                    item['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.error),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '\$${item['price'].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () async {
                                          final success = await DatabaseHelper()
                                              .updateCartItemQuantity(
                                            widget.userId,
                                            item['product_id'],
                                            item['quantity'] - 1,
                                          );
                                          if (success) {
                                            loadCartItems();
                                          }
                                        },
                                      ),
                                      Text(
                                        item['quantity'].toString(),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () async {
                                          final success = await DatabaseHelper()
                                              .updateCartItemQuantity(
                                            widget.userId,
                                            item['product_id'],
                                            item['quantity'] + 1,
                                          );
                                          if (success) {
                                            loadCartItems();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            if (cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessingPayment
                                ? null
                                : () async {
                                    final success = await DatabaseHelper()
                                        .clearCart(widget.userId);
                                    if (success) {
                                      loadCartItems();
                                      Fluttertoast.showToast(
                                        msg: "Carrito vaciado",
                                        backgroundColor: Colors.green,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Vaciar Carrito'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessingPayment ? null : _processPurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: isProcessingPayment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Pagar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}