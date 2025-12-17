import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateTimeUtil {
  static bool isTodayDate(DateTime date) {
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day) ==
        DateTime(now.year, now.month, now.day);
  }

  static String getIsoDate(int timestamp, {bool isUtc = false}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: isUtc);
    debugPrint('getIsoDate...${date.toIso8601String()}');
    return date.toIso8601String();
  }

  // get time ago
  static String getTimeAgoFromDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7}w';
    }

    if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30}mo';
    }

    return '${difference.inDays ~/ 365}y';
  }

  // get time ago
  static String getTimeAgo(int timeStamp) =>
      timeago.format(DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000));

  static String getCustomTimeAgo(int timeStamp) {
    // Convert the timestamp to DateTime
    final eventTime = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);

    // Get the current time
    final now = DateTime.now();

    // Calculate the difference
    final difference = now.difference(eventTime);

    // Get the number of minutes, hours, and days
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    // For months and years
    final years = now.year - eventTime.year;
    var months = now.month - eventTime.month + (years * 12);

    // Adjust for cases where the month has not yet reached the same day
    if (now.day < eventTime.day) {
      months--;
    }

    var agoString = '';
    if (years > 0) {
      agoString = 'about a year ago';
    } else if (months > 0) {
      final remainingDays = days % 30;
      if (remainingDays > 25) {
        agoString = 'about ${months + 1} month ago';
      } else {
        agoString = 'about a month ago';
      }
    } else if (days > 0) {
      agoString = 'about a day ago';
    } else if (hours > 0) {
      agoString = 'about a hour ago';
    } else if (minutes > 0) {
      agoString = 'about a minute ago';
    } else {
      agoString = 'about few seconds ago';
    }
    return agoString;
  }
}
