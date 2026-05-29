import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'main.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({Key? key}) : super(key: key);
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _bukaDetailMenu(BuildContext context, DocumentSnapshot menu) {
    int jumlahPesan = 1;
    Map<String, dynamic> data = menu.data() as Map<String, dynamic>;
    int stokTersedia = data['stok'] ?? 0;
    String imageUrl = data['url_gambar'] ?? '';
    String namaMenu = data['nama_menu'] ?? 'Tanpa Nama';
    int hargaMenu = data['harga'] ?? 0;
    String deskripsi = data['deskripsi'] ?? '-';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 180, color: Colors.red[50], child: Text('Error muat: $e', style: const TextStyle(color: Colors.red))))
                        : Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 60, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(namaMenu, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), Text('Rp $hargaMenu', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DamaiTheme.primaryColor))]),
                const SizedBox(height: 10), Text(deskripsi), const SizedBox(height: 10),
                Text('Sisa Stok: $stokTersedia', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(onPressed: () { if (jumlahPesan > 1) setModalState(() => jumlahPesan--); }, icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 30)),
                    Text('$jumlahPesan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () { if (jumlahPesan < stokTersedia) setModalState(() => jumlahPesan++); }, icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 30)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          int index = globalCart.indexWhere((e) => e['id_menu'] == menu.id);
                          if (index != -1) {
                            int totalBaru = globalCart[index]['jumlah'] + jumlahPesan;
                            globalCart[index]['jumlah'] = totalBaru <= stokTersedia ? totalBaru : stokTersedia;
                          } else {
                            globalCart.add({'id_menu': menu.id, 'nama_menu': namaMenu, 'harga': hargaMenu, 'jumlah': jumlahPesan, 'stok_asli': stokTersedia, 'url_gambar': imageUrl});
                          }
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.shopping_cart), label: const Text('TAMBAH'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Kantin'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          IconButton(
              icon: Stack(children: [const Icon(Icons.shopping_cart), if (globalCart.isNotEmpty) Positioned(right: 0, top: 0, child: CircleAvatar(radius: 7, backgroundColor: Colors.red, child: Text('${globalCart.length}', style: const TextStyle(fontSize: 9, color: Colors.white))))]),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())).then((_) => setState(() {}))
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').where('stok', isGreaterThan: 0).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('Kantin kosong.'));
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var menu = snapshot.data!.docs[index];
              var data = menu.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  onTap: () => _bukaDetailMenu(context, menu),
                  leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(data['url_gambar'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fastfood, color: Colors.orange))),
                  title: Text(data['nama_menu'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rp ${data['harga']} | Stok: ${data['stok']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    int total = globalCart.fold(0, (sum, item) => sum + ((item['harga'] as num).toInt() * (item['jumlah'] as int)));
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: globalCart.isEmpty ? const Center(child: Text('Keranjang kosong')) : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: globalCart.length,
              itemBuilder: (context, index) {
                var item = globalCart[index];
                return ListTile(
                  title: Text(item['nama_menu']), subtitle: Text('${item['jumlah']} Porsi x Rp ${item['harga']}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('Rp ${item['harga'] * item['jumlah']}'), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => globalCart.removeAt(index)))]),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16), color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: Rp $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CheckoutScreen(totalHarga: total))), child: const Text('Checkout'))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final int totalHarga;
  const CheckoutScreen({Key? key, required this.totalHarga}) : super(key: key);
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _metodePembayaran = 'QRIS';

  void _buatPesanan() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('orders').add({
        'student_id': uid, 'items': globalCart, 'total_harga': widget.totalHarga,
        'metode_pembayaran': _metodePembayaran,
        'status': _metodePembayaran == 'Tunai' ? 'Menunggu Pembayaran (Kasir)' : 'Menunggu Pembayaran',
        'created_at': FieldValue.serverTimestamp(),
      });
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var item in globalCart) {
        DocumentReference menuRef = FirebaseFirestore.instance.collection('menus').doc(item['id_menu']);
        batch.update(menuRef, {'stok': item['stok_asli'] - item['jumlah']});
      }
      await batch.commit();
      globalCart.clear();
      Navigator.pop(context); Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(value: 'QRIS', groupValue: _metodePembayaran, onChanged: (v) => setState(() => _metodePembayaran = v.toString())), const Text('QRIS'),
                  Radio(value: 'Tunai', groupValue: _metodePembayaran, onChanged: (v) => setState(() => _metodePembayaran = v.toString())), const Text('Tunai'),
                ],
              ),
              const SizedBox(height: 20),
              if (_metodePembayaran == 'QRIS') ...[
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('settings').doc('qris_payment').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) return const Icon(Icons.qr_code, size: 100);
                    return Image.network((snapshot.data!.data() as Map)['qris_url'] ?? '', height: 200);
                  },
                ),
              ] else ...[
                const Icon(Icons.payments, size: 80, color: Colors.orange), const Text('Bayar langsung ke kasir kantin.')
              ],
              const SizedBox(height: 24),
              Text('Total Bayar: Rp ${widget.totalHarga}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(onPressed: _buatPesanan, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('BUAT PESANAN SEKARANG')),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('student_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('Belum ada riwayat.'));
          return ListView.builder(
            itemCount: snapshot.data!.docs.length, padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(child: ListTile(title: Text('Rp ${data['total_harga']}'), subtitle: Text(data['status'] ?? ''), trailing: Text(data['metode_pembayaran'] ?? '')));
            },
          );
        },
      ),
    );
  }
}