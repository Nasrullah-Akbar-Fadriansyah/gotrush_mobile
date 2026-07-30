import 'package:flutter/material.dart';
import 'full_image_page.dart';
import '../../models/order_detail_model.dart';
import '../../widgets/info_card.dart';

class PhotoCard extends StatelessWidget {
  final OrderDetailModel order;

  const PhotoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: "Foto Sampah",
      icon: Icons.photo_library,
      child: order.photoUrls.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Tidak ada foto.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.photoUrls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, index) {
                final imageUrl = order.photoUrls[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullImagePage(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Hero(
                    tag: imageUrl,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
