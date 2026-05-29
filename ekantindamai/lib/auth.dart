import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // Pastikan DamaiTheme ada di sini
import 'admin.dart';
import 'student.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _uidSiswa = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    String inputId = _uidSiswa.text.trim();
    String inputPassword = _password.text.trim();

    if (inputId.isEmpty || inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UID Siswa dan Password tidak boleh kosong!'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String loginEmail = '';

      // 1. LOGIKA PENCARIAN EMAIL
      if (inputId.contains('@')) {
        loginEmail = inputId;
      } else {
        var userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('uid_siswa', isEqualTo: inputId)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('UID Siswa belum terdaftar!'), backgroundColor: Colors.red)
          );
          setState(() => _isLoading = false);
          return;
        }

        loginEmail = userQuery.docs.first.get('email');
      }

      // 2. PROSES LOGIN KE FIREBASE AUTH
      UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginEmail,
          password: inputPassword
      );

      // 3. CEK ROLE DI FIRESTORE
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).get();
      String role = 'siswa';

      if (doc.exists && doc.data() != null) {
        role = doc.get('role');
      } else {
        // UBAH: Deteksi spesifik email admin OSIS jika dokumen Firestore kosong
        if (loginEmail.toLowerCase() == 'danus.osis@damai.sch.id') role = 'admin';
      }

      // 4. NAVIGASI BERDASARKAN ROLE
      // UBAH: Validasi navigasi admin menggunakan email spesifik
      if (role == 'admin' || loginEmail.toLowerCase() == 'danus.osis@damai.sch.id') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHome()));
      }

    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan saat masuk.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') pesanError = 'Akun tidak ditemukan!';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') pesanError = 'Password yang Anda masukkan salah!';
      if (e.code == 'network-request-failed') pesanError = 'Koneksi internet terputus!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesanError), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo-damai.png',
                height: 150,
                // UBAH: Icon error menggunakan warna biru tetap (bukan DamaiTheme)
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 100, color: Colors.blue),
              ),
              const SizedBox(height: 20),

              // UBAH: Judul teks menggunakan warna biru cerah
              const Text(
                'KANTIN SEKOLAH DAMAI',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                  controller: _uidSiswa,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'UID Siswa / Email', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // UBAH: Background tombol LOGIN diganti menjadi biru
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _login,
                  child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Siswa Baru? Registrasi di sini', style: TextStyle(color: Colors.grey))
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nama = TextEditingController();
  final _uidSiswa = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegistering = false;

  void _register() async {
    String emailInput = _email.text.trim().toLowerCase();
    String uidInput = _uidSiswa.text.trim();

    if (_nama.text.isEmpty || uidInput.isEmpty || emailInput.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!')));
      return;
    }

    setState(() => _isRegistering = true);

    try {
      var checkUid = await FirebaseFirestore.instance.collection('users').where('uid_siswa', isEqualTo: uidInput).get();
      if (checkUid.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UID Siswa ini sudah terdaftar!'), backgroundColor: Colors.red));
        setState(() => _isRegistering = false);
        return;
      }

      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailInput,
          password: _password.text
      );

      // UBAH: Role otomatis admin terkunci mutlak hanya jika email persis 'danus.osis@damai.sch.id'
      String roleOtomatis = (emailInput == 'danus.osis@damai.sch.id') ? 'admin' : 'siswa';

      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
        'nama': _nama.text,
        'uid_siswa': uidInput,
        'email': emailInput,
        'role': roleOtomatis,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Silakan Login menggunakan UID Siswa.'), backgroundColor: Colors.green)
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun Kantin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset(
              'assets/logo-damai.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            TextField(
                controller: _nama,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person))
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _uidSiswa,
                decoration: const InputDecoration(labelText: 'UID Siswa (NIS)', hintText: 'contoh: 123456', prefixIcon: Icon(Icons.badge))
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email Resmi Sekolah', hintText: 'contoh: siswa@damai.sch.id', prefixIcon: Icon(Icons.mail))
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru', prefixIcon: Icon(Icons.lock))
            ),
            const SizedBox(height: 32),
            _isRegistering
                ? const CircularProgressIndicator()
                : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: DamaiTheme.primaryColor),
                    onPressed: _register,
                    child: const Text('DAFTAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                )
            ),
          ],
        ),
      ),
    );
  }
}