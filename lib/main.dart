import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

// struct 
class Receipt {
  final String title;
  final String user;
  final String imageUrl;
  final String description;
  final bool isFavorited;
  final int favoriteCount;

  Receipt({
    required this.title,
    required this.user,
    required this.imageUrl,
    required this.description,
    required this.isFavorited,
    this.favoriteCount = 0,
  });
}


final Receipt maham = Receipt(
  title: 'Pass causant Djanta !',
  user: 'PAR moi',
  imageUrl: 'https://media.gettyimages.com/id/1807564557/fr/vectoriel/doigt-dhonneur-style-pop-art.jpg?s=612x612&w=gi&k=20&c=RpaAUJTU0XyKrzRdwqC8kdtn3zzYPS_ViCcCVNcaGmU=', 
  description: '''Découvrez ma mentalité! 
Des classiques aux créations originales, il y en a pour tous les chat. BLA BLA BLA''',
  isFavorited: false,
  favoriteCount: -999,
);

final Receipt ander = Receipt(
  title: 'Pizza facile !',
  user: 'PAR Andy.CEO',
  imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=600&auto=format&fit=crop',
  description: '''Découvrez nos recettes de pizza faciles à réaliser chez vous! 
Des classiques aux créations originales, il y en a pour tous les goûts. BLA BLA BLA''',
  isFavorited: false,
  favoriteCount: 998,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mes recettes',
      theme: ThemeData(
        primaryColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const ReceiptListScreen(),
    );
  }
}

// 1 fucking screen later...
class ReceiptListScreen extends StatelessWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Les Recettes', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          ReceiptItemWidget(receipt: ander),
          ReceiptItemWidget(receipt: maham),
        ],
      ),
    );
  }
}

class ReceiptItemWidget extends StatelessWidget {
  final Receipt receipt;

  const ReceiptItemWidget({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(receipt: receipt),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4.0)),
              child: Image.network(
                receipt.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 100,
                  height: 100,
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receipt.user,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 2 fucking screens later...
class MyHomePage extends StatelessWidget {

  final Receipt receipt;

  const MyHomePage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(receipt.title, style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          Stack(
            children: [
              const SizedBox(
                width: 600,
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
              FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: receipt.imageUrl,
                width: 600,
                height: 240,
                fit: BoxFit.cover,
              ),
            ],
          ),

          _buildTitleSection(receipt),
          _buildButtonSection(),
          _buildDescriptionSection(receipt),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              receipt.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontSize: 20,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                receipt.user,
                style: const TextStyle(fontSize: 14),
              ),
              FavoriteWidget(
                initialFavoriteCount: receipt.favoriteCount,
                initialIsFavorited: receipt.isFavorited,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButtonColumn(Colors.red, Icons.comment, 'Commenter'),
        _buildButtonColumn(Colors.red, Icons.share, 'Partager'),
      ],
    );
  }

  Widget _buildDescriptionSection(Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Text(
        receipt.description,
        style: const TextStyle(fontSize: 16),
        softWrap: true,
      ),
    );
  }

  Widget _buildButtonColumn(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}


class FavoriteWidget extends StatefulWidget {
  final int initialFavoriteCount;
  final bool initialIsFavorited;

  const FavoriteWidget({
    super.key,
    required this.initialFavoriteCount,
    required this.initialIsFavorited,
  });

  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  late bool _isFavorited;
  late int _favoriteCount;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.initialIsFavorited;
    _favoriteCount = widget.initialFavoriteCount;
  }

  void _toggleFavorite() {
    setState(() {
      if (_isFavorited) {
        _isFavorited = false;
        _favoriteCount -= 1;
      } else {
        _isFavorited = true;
        _favoriteCount += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isFavorited ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
          onPressed: _toggleFavorite,
        ),
        SizedBox(
          width: 40, 
          child: Text('$_favoriteCount'),
        ),
      ],
    );
  }
}
