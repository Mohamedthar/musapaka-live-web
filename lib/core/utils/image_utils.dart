import 'dart:typed_data';
import 'package:image/image.dart' as img;

Uint8List compressImage(Uint8List bytes, {int maxWidth = 800, int quality = 75}) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;
  img.Image resized = image;
  if (image.width > maxWidth) {
    resized = img.copyResize(image, width: maxWidth);
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}
