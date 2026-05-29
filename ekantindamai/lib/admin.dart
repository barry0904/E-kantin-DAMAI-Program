import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard Utama Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red[900],
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _logout(context))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.red[900], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panel Kendali Kantin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('Semua perubahan data langsung tersimpan ke Firebase', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
            child: Text('Menu Manajemen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              children: [
                _buildMenuCard(context, 'Kelola Menu & Stok', Icons.fastfood, Colors.orange, const ManageMenuScreen()),
                _buildMenuCard(context, 'Pesanan Masuk', Icons.receipt_long, Colors.blue, const OrderListAdminScreen()),
                _buildMenuCard(context, 'Riwayat Penjualan', Icons.history_edu, Colors.green, const SalesHistoryScreen()),
                _buildMenuCard(context, 'Pengaturan QRIS', Icons.qr_code_scanner, Colors.purple, const QrisSettingsScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Card(
      elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 35, color: color)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({Key? key}) : super(key: key);
  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final _nama = TextEditingController(); final _harga = TextEditingController();
  final _stok = TextEditingController(); final _deskripsi = TextEditingController();
  File? _imageFile; bool _isLoading = false; final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batal memilih gambar.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal akses galeri: $e'), backgroundColor: Colors.red));
    }
  }

  // LOGIKA UPLOAD KE IMGBB (Sudah Terintegrasi API Key)
  Future<String?> _uploadToImgBB(File imageFile) async {
    String apiKey = '2729ec2d540b1c3be0057b3753643aa7';
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResult = jsonDecode(responseData);

        // 1. Ambil URL asli dari ImgBB
        String urlAsli = jsonResult['data']['url'];

        // 2. PERBAIKAN: Otomatis ubah i.ibb.co menjadi i.ibb.co.com agar tidak diblokir ISP Indonesia
        String urlAmanIndonesia = urlAsli.replaceAll('i.ibb.co', 'i.ibb.co.com');

        return urlAmanIndonesia;
      }
      return null;
    } catch (e) { return null; }
  }

  Future<void> _tambahMenuKeFirebase() async {
    int? hargaValid = int.tryParse(_harga.text.replaceAll('.', '').replaceAll(',', ''));
    int? stokValid = int.tryParse(_stok.text.replaceAll('.', '').replaceAll(',', ''));

    if (_nama.text.isEmpty || hargaValid == null || stokValid == null || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi form dan gambar!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String? downloadUrl = await _uploadToImgBB(_imageFile!);
      if (downloadUrl == null) throw Exception('Gagal mengunggah gambar ke ImgBB, periksa koneksi.');

      await FirebaseFirestore.instance.collection('menus').add({
        'nama_menu': _nama.text, 'harga': hargaValid, 'stok': stokValid,
        'deskripsi': _deskripsi.text.isEmpty ? 'Tidak ada deskripsi' : _deskripsi.text,
        'url_gambar': downloadUrl,
      });

      _nama.clear(); _harga.clear(); _stok.clear(); _deskripsi.clear();
      setState(() { _imageFile = null; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sukses simpan menu baru!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu'), backgroundColor: Colors.red[900]),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Tambah Menu Baru', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            iconColor: Colors.red,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Menu', border: OutlineInputBorder())), const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _harga, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder()))), const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _stok, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()))),
                      ],
                    ), const SizedBox(height: 8),
                    TextField(controller: _deskripsi, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())), const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                        child: _imageFile != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, fit: BoxFit.cover))
                            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image, size: 50, color: Colors.grey), Text('Pilih Gambar', style: TextStyle(color: Colors.grey))]),
                      ),
                    ), const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 45,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                        onPressed: _isLoading ? null : _tambahMenuKeFirebase,
                        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload, color: Colors.white),
                        label: Text(_isLoading ? 'MENGUNGGAH...' : 'SIMPAN DATA'),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const Divider(thickness: 2),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menus').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var menu = docs[index];
                    Map<String, dynamic> data = menu.data() as Map<String, dynamic>;
                    String imageUrl = data.containsKey('url_gambar') ? data['url_gambar'] : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          // PERBAIKAN: Proteksi ekstra agar tidak crash jika link data lama salah format
                          child: (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                              ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.red),
                          )
                              : const Icon(Icons.fastfood, color: Colors.orange),
                        ),
                        title: Text(data['nama_menu'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Rp ${data['harga']} | Stok: ${data['stok']}'),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('menus').doc(menu.id).delete()),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class OrderListAdminScreen extends StatelessWidget {
  const OrderListAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Masuk'), backgroundColor: Colors.red[900]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('status', isNotEqualTo: 'Selesai').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var orders = snapshot.data!.docs;
          if (orders.isEmpty) return const Center(child: Text('Tidak ada pesanan aktif.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12), itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              Map<String, dynamic> data = order.data() as Map<String, dynamic>;
              String studentId = data.containsKey('student_id') && data['student_id'] != null ? data['student_id'].toString() : 'Anonim';
              String shortId = studentId.length > 6 ? studentId.substring(0, 6) : studentId;
              int totalHarga = data.containsKey('total_harga') && data['total_harga'] != null ? (data['total_harga'] as num).toInt() : 0;
              String currentStatus = data.containsKey('status') && data['status'] != null ? data['status'].toString() : 'Menunggu Pembayaran';

              List<String> statusOptions = ['Menunggu Pembayaran', 'Menunggu Pembayaran (Kasir)', 'Sudah Bayar', 'Diproses', 'Selesai'];
              if (!statusOptions.contains(currentStatus)) statusOptions.add(currentStatus);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('ID: $shortId...', style: const TextStyle(fontWeight: FontWeight.bold)), Text('Rp $totalHarga', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))],
                      ), const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          DropdownButton<String>(
                            value: currentStatus,
                            style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
                            items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': val});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penjualan'), backgroundColor: Colors.red[900]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'Selesai').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          int total = docs.fold(0, (sum, doc) => sum + ((doc.data() as Map)['total_harga'] as num? ?? 0).toInt());
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), width: double.infinity,
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green.shade300)),
                child: Column(children: [const Text('TOTAL PENDAPATAN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), Text('Rp $total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green))]),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length, padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String id = data['student_id']?.toString() ?? 'Anon';
                    return Card(child: ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text('Siswa ID: ${id.length>6?id.substring(0,6):id}'), trailing: Text('Rp ${data['total_harga']}')));
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class QrisSettingsScreen extends StatefulWidget {
  const QrisSettingsScreen({Key? key}) : super(key: key);
  @override
  State<QrisSettingsScreen> createState() => _QrisSettingsScreenState();
}

class _QrisSettingsScreenState extends State<QrisSettingsScreen> {
  File? _qrisImage; bool _isLoading = false; final ImagePicker _picker = ImagePicker();

  Future<void> _pickQris() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) setState(() => _qrisImage = File(pickedFile.path));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  Future<void> _simpanQris() async {
    if (_qrisImage == null) return;
    setState(() => _isLoading = true);
    try {
      String apiKey = '2729ec2d540b1c3be0057b3753643aa7';
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'));
      request.files.add(await http.MultipartFile.fromPath('image', _qrisImage!.path));
      var res = await request.send();
      if (res.statusCode == 200) {
        var data = jsonDecode(await res.stream.bytesToString());

        // PERBAIKAN DI SINI JUGA:
        String qrisUrlAsli = data['data']['url'];
        String qrisUrlAman = qrisUrlAsli.replaceAll('i.ibb.co', 'i.ibb.co.com');

        await FirebaseFirestore.instance.collection('settings').doc('qris_payment').set({'qris_url': qrisUrlAman});
        setState(() => _qrisImage = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QRIS Diupdate!'), backgroundColor: Colors.green));
      }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRIS Kantin'), backgroundColor: Colors.red[900]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              onTap: _pickQris,
              child: Container(
                height: 200, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(12)),
                child: _qrisImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_qrisImage!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 50, color: Colors.red), Text('Pilih Foto QRIS Baru', style: TextStyle(color: Colors.red, fontSize: 12))]),
              ),
            ), const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(onPressed: _isLoading ? null : _simpanQris, child: Text(_isLoading ? 'PROSES MENGUNGGAH...' : 'UPDATE DATA QRIS')),
            ),
            const Divider(height: 40),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('settings').doc('qris_payment').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Belum ada QRIS aktif'));
                  String qrisUrl = snapshot.data!['qris_url'] ?? '';
                  if(qrisUrl.isEmpty || !qrisUrl.startsWith('http')) return const Center(child: Text('Link QRIS tidak valid'));
                  return Image.network(qrisUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 50, color: Colors.red));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}