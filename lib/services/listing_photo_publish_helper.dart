import '../models/donation_models.dart';
import '../models/listing.dart';
import '../widgets/listing_photo_picker.dart';
import 'auth_session_service.dart';
import 'listing_api_service.dart';

/// Shared helpers so donate / request forms reuse the same photo + API path
/// as the shop and browse create sheets.
class ListingPhotoPublishHelper {
  ListingPhotoPublishHelper._();

  static String conditionKey(ItemCondition condition) {
    return switch (condition) {
      ItemCondition.excellent => 'likeNew',
      ItemCondition.good => 'good',
      ItemCondition.fair => 'fair',
      ItemCondition.needsRepair => 'fair',
      ItemCondition.notDonatable => 'fair',
    };
  }

  static List<String> uploadedPaths(List<ListingPhotoDraft> photos) {
    return [
      for (final photo in photos)
        if (photo.uploadedPath != null) photo.uploadedPath!,
    ];
  }

  static Future<String> upload(ListingPhotoDraft draft) async {
    final result = await ListingApiService.instance.uploadPhoto(
      bytes: draft.bytes,
      contentType: draft.contentType,
    );
    final path = result.data;
    if (!result.success || path == null) throw Exception(result.message);
    return path;
  }

  /// Publishes when a session exists; returns `null` when the user is signed out
  /// so local-only donate flows can continue without blocking.
  static Future<ListingApiResult<Listing>?> createIfSignedIn({
    required String title,
    required String category,
    String? description,
    String? condition,
    String? sizeNote,
    int quantity = 1,
    String urgency = 'normal',
    String? postalCode,
    List<String> photos = const [],
  }) async {
    await AuthSessionService.instance.ensureLoaded();
    final token = AuthSessionService.instance.token;
    if (token == null || token.isEmpty) return null;

    return ListingApiService.instance.create(
      title: title,
      category: category,
      description: description,
      condition: condition,
      sizeNote: sizeNote,
      quantity: quantity,
      urgency: urgency,
      postalCode: postalCode,
      photos: photos,
    );
  }
}
