import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Impactly'**
  String get app_title;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcome_back;

  /// No description provided for @sign_in_to_account.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get sign_in_to_account;

  /// No description provided for @email_address.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email_address;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dont_have_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dont_have_account;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get sign_up;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @continue_text.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_text;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @join_community.
  ///
  /// In en, this message translates to:
  /// **'Join our community to start making an impact'**
  String get join_community;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get already_have_account;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @explore_categories.
  ///
  /// In en, this message translates to:
  /// **'Explore Categories'**
  String get explore_categories;

  /// No description provided for @recently_added_events.
  ///
  /// In en, this message translates to:
  /// **'Recently Added Events'**
  String get recently_added_events;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get see_all;

  /// No description provided for @hi_user.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}! 👋'**
  String hi_user(Object name);

  /// No description provided for @ready_to_impact.
  ///
  /// In en, this message translates to:
  /// **'Ready to make an impact?'**
  String get ready_to_impact;

  /// No description provided for @no_events_added.
  ///
  /// In en, this message translates to:
  /// **'No events added yet'**
  String get no_events_added;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// No description provided for @workshops.
  ///
  /// In en, this message translates to:
  /// **'Workshops'**
  String get workshops;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @impact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impact;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @share_profile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get share_profile;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @settings_and_privacy.
  ///
  /// In en, this message translates to:
  /// **'Settings and Privacy'**
  String get settings_and_privacy;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @current_password.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get current_password;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirm_new_password;

  /// No description provided for @password_changed_success.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get password_changed_success;

  /// No description provided for @password_change_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password. Please check your current password.'**
  String get password_change_failed;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwords_do_not_match;

  /// No description provided for @join_event.
  ///
  /// In en, this message translates to:
  /// **'Join Event'**
  String get join_event;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @created_by_you.
  ///
  /// In en, this message translates to:
  /// **'Created By You'**
  String get created_by_you;

  /// No description provided for @your_event.
  ///
  /// In en, this message translates to:
  /// **'Your Event'**
  String get your_event;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get when;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @about_event.
  ///
  /// In en, this message translates to:
  /// **'About this Event'**
  String get about_event;

  /// No description provided for @organized_by.
  ///
  /// In en, this message translates to:
  /// **'Organized by'**
  String get organized_by;

  /// No description provided for @event_not_found.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get event_not_found;

  /// No description provided for @joined_successfully.
  ///
  /// In en, this message translates to:
  /// **'Joined successfully! 🚀'**
  String get joined_successfully;

  /// No description provided for @no_date.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get no_date;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @points_unit.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points_unit;

  /// No description provided for @search_impact_events.
  ///
  /// In en, this message translates to:
  /// **'Search impact events...'**
  String get search_impact_events;

  /// No description provided for @no_events_found.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get no_events_found;

  /// No description provided for @impactly_feed.
  ///
  /// In en, this message translates to:
  /// **'Impactly Feed'**
  String get impactly_feed;

  /// No description provided for @feed_empty.
  ///
  /// In en, this message translates to:
  /// **'Your Feed is Empty'**
  String get feed_empty;

  /// No description provided for @follow_causes.
  ///
  /// In en, this message translates to:
  /// **'Follow some causes to see their updates!'**
  String get follow_causes;

  /// No description provided for @search_users.
  ///
  /// In en, this message translates to:
  /// **'Search Users'**
  String get search_users;

  /// No description provided for @add_friend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get add_friend;

  /// No description provided for @remove_friend.
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get remove_friend;

  /// No description provided for @friend_added.
  ///
  /// In en, this message translates to:
  /// **'Friend added!'**
  String get friend_added;

  /// No description provided for @friend_removed.
  ///
  /// In en, this message translates to:
  /// **'Friend removed.'**
  String get friend_removed;

  /// No description provided for @no_users_found.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get no_users_found;

  /// No description provided for @search_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter name or username...'**
  String get search_hint;

  /// No description provided for @likes_count.
  ///
  /// In en, this message translates to:
  /// **'{count} likes'**
  String likes_count(int count);

  /// No description provided for @view_all_comments.
  ///
  /// In en, this message translates to:
  /// **'View all comments'**
  String get view_all_comments;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @no_comments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get no_comments;

  /// No description provided for @add_comment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get add_comment;

  /// No description provided for @post_comment.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post_comment;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @logout_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout_tooltip;

  /// No description provided for @user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get user_not_found;

  /// No description provided for @discover_events.
  ///
  /// In en, this message translates to:
  /// **'Discover Events'**
  String get discover_events;

  /// No description provided for @search_events.
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get search_events;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @volunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get volunteering;

  /// No description provided for @create_event.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get create_event;

  /// No description provided for @create_new_event.
  ///
  /// In en, this message translates to:
  /// **'Create New Event'**
  String get create_new_event;

  /// No description provided for @event_title.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get event_title;

  /// No description provided for @event_title_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Beach Cleanup Drive'**
  String get event_title_hint;

  /// No description provided for @description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description_label;

  /// No description provided for @description_hint.
  ///
  /// In en, this message translates to:
  /// **'Tell users about the event...'**
  String get description_hint;

  /// No description provided for @location_label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location_label;

  /// No description provided for @location_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Marine Drive, Mumbai'**
  String get location_hint;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @points_reward.
  ///
  /// In en, this message translates to:
  /// **'Points Reward'**
  String get points_reward;

  /// No description provided for @points_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100'**
  String get points_hint;

  /// No description provided for @event_date.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get event_date;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get select_date;

  /// No description provided for @event_created.
  ///
  /// In en, this message translates to:
  /// **'Event Created 🎉'**
  String get event_created;

  /// No description provided for @please_select_date.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get please_select_date;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get field_required;

  /// No description provided for @valid_number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get valid_number;

  /// No description provided for @impact_points.
  ///
  /// In en, this message translates to:
  /// **'Impact Points'**
  String get impact_points;

  /// No description provided for @level_text.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level_text(int level);

  /// No description provided for @view_ranking.
  ///
  /// In en, this message translates to:
  /// **'View Ranking'**
  String get view_ranking;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @community_feed.
  ///
  /// In en, this message translates to:
  /// **'Community Feed'**
  String get community_feed;

  /// No description provided for @no_posts_yet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get no_posts_yet;

  /// No description provided for @be_the_first_to_share.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share an update!'**
  String get be_the_first_to_share;

  /// No description provided for @new_post.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get new_post;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @event_update.
  ///
  /// In en, this message translates to:
  /// **'Event Update'**
  String get event_update;

  /// No description provided for @select_joined_event.
  ///
  /// In en, this message translates to:
  /// **'Select joined event'**
  String get select_joined_event;

  /// No description provided for @join_event_to_post.
  ///
  /// In en, this message translates to:
  /// **'Join an event to post updates!'**
  String get join_event_to_post;

  /// No description provided for @whats_the_update.
  ///
  /// In en, this message translates to:
  /// **'What\'s the update from this event?'**
  String get whats_the_update;

  /// No description provided for @add_photo.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get add_photo;

  /// No description provided for @post_published.
  ///
  /// In en, this message translates to:
  /// **'Post published! ✨'**
  String get post_published;

  /// No description provided for @write_something_error.
  ///
  /// In en, this message translates to:
  /// **'Please write something and select an event'**
  String get write_something_error;

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @joined_at.
  ///
  /// In en, this message translates to:
  /// **'Joined: {eventTitle}'**
  String joined_at(String eventTitle);

  /// No description provided for @post_update.
  ///
  /// In en, this message translates to:
  /// **'Post Update'**
  String get post_update;

  /// No description provided for @points_count.
  ///
  /// In en, this message translates to:
  /// **'+{count} pts'**
  String points_count(int count);

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @art.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get art;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @animal_care.
  ///
  /// In en, this message translates to:
  /// **'Animal Care'**
  String get animal_care;

  /// No description provided for @no_interests_specified.
  ///
  /// In en, this message translates to:
  /// **'No interests specified.'**
  String get no_interests_specified;

  /// No description provided for @profile_caption.
  ///
  /// In en, this message translates to:
  /// **'Capture your impact and share it with the community.'**
  String get profile_caption;

  /// No description provided for @points_and_level.
  ///
  /// In en, this message translates to:
  /// **'{points} Points • Level {level}'**
  String points_and_level(int points, int level);

  /// No description provided for @experience_impactly.
  ///
  /// In en, this message translates to:
  /// **'Experience Impactly in your preferred language'**
  String get experience_impactly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
