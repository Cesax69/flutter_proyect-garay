import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final allProducts = await DatabaseHelper().getAllProducts();
    setState(() {
      products = allProducts;
      isLoading = false;
    });
  }

  Future<void> _showAddEditProductDialog([Map<String, dynamic>? product]) async {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(
        text: product?['price']?.toString() ?? '');
    final stockController = TextEditingController(
        text: product?['stock']?.toString() ?? '');
    final imageController = TextEditingController(text: product?['image'] ?? '');
    final descriptionController = TextEditingController(
        text: product?['description'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Agregar Producto' : 'Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'URL de la imagen'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text;
              final price = double.tryParse(priceController.text) ?? 0.0;
              final stock = int.tryParse(stockController.text) ?? 0;
              final image = imageController.text;
              final description = descriptionController.text;

              bool success;
              if (product == null) {
                success = await DatabaseHelper().addProduct(
                  name,
                  price,
                  stock,
                  image,
                  description,
                );
              } else {
                success = await DatabaseHelper().updateProduct(
                  product['id'],
                  name,
                  price,
                  stock,
                  image,
                  description,
                );
              }

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                loadProducts();
                Fluttertoast.showToast(
                  msg: product == null
                      ? "Producto agregado exitosamente"
                      : "Producto actualizado exitosamente",
                  backgroundColor: Colors.green,
                );
              } else {
                Fluttertoast.showToast(
                  msg: "Error al ${product == null ? 'agregar' : 'actualizar'} el producto",
                  backgroundColor: Colors.red,
                );
              }
            },
            child: Text(product == null ? 'Agregar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Productos'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditProductDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade100, Colors.purple.shade200],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Image.network(
                          product['image'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                        ListTile(
                          title: Text(product['name']),
                          subtitle: Text(
                            '\$${product['price'].toStringAsFixed(2)} - Stock: ${product['stock']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showAddEditProductDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar eliminación'),
                                      content: const Text(
                                          '¿Está seguro de eliminar este producto?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final success = await DatabaseHelper()
                                        .deleteProduct(product['id']);
                                    if (success) {
                                      loadProducts();
                                      Fluttertoast.showToast(
                                        msg: "Producto eliminado exitosamente",
                                        backgroundColor: Colors.green,
                                      );
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: "Error al eliminar el producto",
                                        backgroundColor: Colors.red,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}