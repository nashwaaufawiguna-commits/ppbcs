import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  
  // Controller untuk input cerita mimpi
  final _ceritaController = TextEditingController();
  
  // Variabel untuk Dropdown dan Slider
  String _kategoriTerpilih = 'Absurd';
  final List<String> _kategoriMimpi = ['Absurd', 'Seram', 'Lucu', 'Petualangan', 'Sedih'];
  double _tingkatKeanehan = 3.0;

  @override
  void dispose() {
    _ceritaController.dispose();
    super.dispose();
  }

  void _addData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _ceritaController.text.isNotEmpty) {
      // Menyimpan data ke collection 'jurnal_mimpi'
      await _firestore.collection('jurnal_mimpi').add({
        'cerita': _ceritaController.text,
        'kategori': _kategoriTerpilih,
        'keanehan': _tingkatKeanehan,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'userEmail': user.email,
      });
      
      // Reset input setelah berhasil disimpan
      _ceritaController.clear();
      setState(() {
        _kategoriTerpilih = 'Absurd';
        _tingkatKeanehan = 3.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mimpi berhasil dicatat!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Mimpi Absurd'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${user?.email?.split('@')[0] ?? 'Pemimpi'}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // --- BAGIAN INPUT DATA ---
            TextField(
              controller: _ceritaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ceritakan mimpimu yang aneh...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                const Text('Kategori: '),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _kategoriTerpilih,
                  items: _kategoriMimpi.map((String kategori) {
                    return DropdownMenuItem<String>(
                      value: kategori,
                      child: Text(kategori),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _kategoriTerpilih = newValue!;
                    });
                  },
                ),
              ],
            ),
            
            Row(
              children: [
                const Text('Level Keanehan:'),
                Expanded(
                  child: Slider(
                    value: _tingkatKeanehan,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _tingkatKeanehan.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _tingkatKeanehan = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Ke Jurnal'),
              ),
            ),
            const Divider(height: 30, thickness: 2),
            
            // --- BAGIAN MENAMPILKAN DATA ---
            const Text(
              'Riwayat Mimpimu:', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('jurnal_mimpi') 
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Belum ada mimpi yang dicatat.'));
                  }
                  
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final timestamp = data['createdAt'] as Timestamp;
                      final date = timestamp.toDate();
                      
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              data['keanehan'].round().toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            data['cerita'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Kategori: ${data['kategori']} • ${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}