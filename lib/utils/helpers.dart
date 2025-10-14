import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as Math;

class AppHelpers {
  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // String helpers
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // UI helpers
  static void showSnackBar(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, color: Colors.red);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, color: Colors.green);
  }

  // Distance calculation
  static double calculateDistance(
    double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_degreesToRadians(lat1)) * Math.cos(_degreesToRadians(lat2)) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);
    
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (Math.pi / 180);
  }

  // File size formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Status helpers
  static String getStatusEmoji(String status) {
    switch (status) {
      case 'Pending':
        return '⏳';
      case 'In Progress':
        return '🔧';
      case 'Resolved':
        return '✅';
      default:
        return '❓';
    }
  }

  static String getIssueTypeEmoji(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'pothole':
        return '🕳️';
      case 'garbage':
        return '🗑️';
      case 'water leak':
        return '💧';
      case 'street light':
        return '💡';
      case 'traffic':
        return '🚦';
      case 'road damage':
        return '🛣️';
      case 'sewage':
        return '🚰';
      default:
        return '📋';
    }
  }

  // Map helpers
  static Future<void> openInMap(BuildContext context, double lat, double lng, String label) async {
    // Try to open in Google Maps app first, fallback to browser
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    try {
      // Try Google Maps URL scheme for Android
      final Uri googleMapsApp = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      if (await canLaunchUrl(googleMapsApp)) {
        await launchUrl(googleMapsApp, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Fallback to browser
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
      
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not open map application');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Error opening map: ${e.toString()}');
      }
    }
  }
}
