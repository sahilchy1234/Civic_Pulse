class CloudinaryConfig {
  // Cloudinary configuration - get these from your Cloudinary dashboard
  // Sign up at https://cloudinary.com (free tier available)
  
  static const String cloudName = 'dyfgmaxeo'; // Your cloud name
  static const String apiKey = '225787416864971'; // Your API key
  static const String apiSecret = 'pQU9zKBQLF7Z8c02HM3Ubg2irfg'; // Your API secret
  
  // Upload preset for unsigned uploads (leave empty to use signed uploads)
  static const String uploadPreset = 'civicsense'; // Try a simple preset name
  
  // Base URL for Cloudinary
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
  
  // Get upload URL
  static String get uploadUrl => '$baseUrl/$cloudName/image/upload';
  
  // Get resource URL
  static String getResourceUrl(String publicId, {String? transformation}) {
    if (transformation != null) {
      return 'https://res.cloudinary.com/$cloudName/image/upload/$transformation/$publicId';
    }
    return 'https://res.cloudinary.com/$cloudName/image/upload/$publicId';
  }
}
