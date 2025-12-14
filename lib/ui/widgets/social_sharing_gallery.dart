import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialSharingGallery extends StatefulWidget {
  final List<String> imageUrls;
  final String title;
  final String description;
  final String heroTag;

  const SocialSharingGallery({
    super.key,
    required this.imageUrls,
    required this.title,
    required this.description,
    this.heroTag = 'gallery',
  });

  @override
  _SocialSharingGalleryState createState() => _SocialSharingGalleryState();
}

class _SocialSharingGalleryState extends State<SocialSharingGallery> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareItem() {
    final String text = '${widget.title}\n\n${widget.description}\n\n${widget.imageUrls.first}';
    Share.share(text);
  }

  void _shareToWhatsApp() async {
    final String text =
        'Check out this item on Baddel: *${widget.title}*\n\n${widget.imageUrls.first}';
    final Uri whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      _shareItem();
    }
  }

  void _shareToFacebook() {
    final String url = widget.imageUrls.first;
    final String quote = 'Check out this item on Baddel: ${widget.title}';
    final Uri facebookUri =
        Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$url&quote=$quote');
    launchUrl(facebookUri, mode: LaunchMode.externalApplication);
  }

  void _shareToMessenger() {
    final String url = widget.imageUrls.first;
    final Uri messengerUri = Uri.parse('fb-messenger://share?link=$url');
    launchUrl(messengerUri, mode: LaunchMode.externalApplication);
  }

  void _copyLink() {
    final String url = widget.imageUrls.first;
    Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showShareOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoGalleryScreen(
                      imageUrls: widget.imageUrls,
                      initialIndex: _currentIndex,
                      heroTag: widget.heroTag,
                    ),
                  ),
                );
              },
              child: PhotoViewGallery.builder(
                itemCount: widget.imageUrls.length,
                pageController: _pageController,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(widget.imageUrls[index]),
                    heroAttributes: PhotoViewHeroAttributes(tag: '${widget.heroTag}_$index'),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
              ),
            ),
          ),
          _buildImageIndicator(),
          _buildItemInfo(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImageIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.imageUrls.map((url) {
          int index = widget.imageUrls.indexOf(url);
          return Container(
            width: 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentIndex == index
                  ? const Color.fromRGBO(255, 255, 255, 0.9)
                  : const Color.fromRGBO(255, 255, 255, 0.4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border),
              color: Colors.white,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'MAKE OFFER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share this item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildShareOption(
                    icon: Icons.whatsapp,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(context);
                      _shareToWhatsApp();
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () {
                      Navigator.pop(context);
                      _shareToFacebook();
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'Messenger',
                    color: const Color(0xFF0084FF),
                    onTap: () {
                      Navigator.pop(context);
                      _shareToMessenger();
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.link,
                    label: 'Copy Link',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      _copyLink();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareItem();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'More Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PhotoGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTag;

  const PhotoGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.heroTag,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imageUrls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  widget.imageUrls[index],
                ),
                heroAttributes: PhotoViewHeroAttributes(
                  tag: '${widget.heroTag}_$index',
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
