# ISM Video Reel Player SDK

Flutter SDK for video reels, posts, collections, comments, and social features. Integrate reels feeds, create/edit posts, manage saved posts, and open SDK screens from your app.

---

## Table of Contents

- [Installation](#installation)
- [SDK Initialization](#sdk-initialization)
- [Data Providers](#data-providers)
- [Config & Callbacks](#config--callbacks)
- [Navigator – Opening SDK Pages](#navigator--opening-sdk-pages)
- [Utilities](#utilities)

---

## Installation

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  ism_video_reel_player: <version>
```

Then run:

```bash
flutter pub get
```

---

## SDK Initialization

### When to call `initializeSdk`

Call **`IsrVideoReelConfig.initializeSdk`** in these cases:

1. **App opened** – Once at app startup (e.g. in `main()` or before showing any SDK UI).
2. **User changed** – When the active user switches (e.g. account switch).
3. **User logged in / logged out** – After login or logout so headers and user context are updated.

Repeated calls are safe: the first call does one-time setup (Hive, RudderStack, DI); later calls update headers, user info, and configs.

### API

```dart
import 'package:ism_video_reel_player/isr_video_reel_config.dart';

await IsrVideoReelConfig.initializeSdk(
  baseUrl: 'https://your-api.example.com',
  rudderStackWriteKey: 'your_rudder_write_key',
  rudderStackDataPlaneUrl: 'https://your-dataplane.rudderstack.com',
  userInfoClass: userInfo,           // see below
  defaultHeaders: headers,           // see below
  googleServiceJsonPath: null,       // optional, Android
  getCurrentBuildContext: () => navigatorKey.currentContext,
  // Optional config overrides (null = keep existing/default)
  socialConfig: socialConfig,
  postConfig: postConfig,
  tabConfig: tabConfig,
  commentConfig: commentConfig,
  createEditPostConfig: createEditPostConfig,
  tagDetailsConfig: tagDetailsConfig,
  searchScreenConfig: searchScreenConfig,
);
```

### User info (`UserInfoClass`)

Pass the current user (or `null` when logged out). Used for API context and stored for SDK use.

| Field          | Type    | Description                |
|----------------|---------|----------------------------|
| `userId`       | String? | Unique user ID             |
| `userName`     | String? | Username                   |
| `firstName`    | String? | First name                 |
| `lastName`     | String? | Last name                  |
| `profilePic`   | String? | Profile image URL          |
| `email`        | String? | Email                      |
| `dialCode`     | String? | Phone dial code            |
| `mobileNumber` | String? | Phone number               |

Example:

```dart
final userInfo = UserInfoClass(
  userId: 'user_123',
  userName: 'johndoe',
  firstName: 'John',
  lastName: 'Doe',
  profilePic: 'https://cdn.example.com/avatar.jpg',
  email: 'john@example.com',
  dialCode: '+1',
  mobileNumber: '9876543210',
);
```

For logout, pass `userInfoClass: null` (and update `defaultHeaders` if needed).

### Default headers (`defaultHeaders`)

Headers are stored and sent with SDK API requests. Typically include auth and tenant/project.

| Key               | Type    | Description                    |
|-------------------|---------|--------------------------------|
| `Authorization`   | String? | Bearer token                  |
| `lan`             | String? | Language code                 |
| `city`            | String? | City                          |
| `state`           | String? | State                         |
| `country`         | String? | Country                       |
| `ipaddress`       | String? | Client IP                     |
| `version`         | String? | App/SDK version               |
| `currencySymbol`   | String? | Currency symbol               |
| `currencyCode`    | String? | Currency code                 |
| `platform`        | String? | Platform identifier           |
| `latitude`        | double? | Latitude                      |
| `longitude`       | double? | Longitude                     |
| `x-tenant-id`     | String? | Tenant ID                     |
| `x-project-id`    | String? | Project ID                    |

Example:

```dart
final defaultHeaders = <String, dynamic>{
  'Authorization': 'Bearer $accessToken',
  'x-tenant-id': tenantId,
  'x-project-id': projectId,
  'lan': 'en',
  'version': '1.0.0',
  'platform': 'flutter',
  // ... other keys as needed
};
```

### Bloc providers

If your app uses a single `BlocProvider` tree, add the SDK’s singleton providers so SDK screens have access to `IsmSocialActionCubit`:

```dart
IsrVideoReelConfig.getIsmSingletonBlocProviders()
```

---

## Data Providers

Use **`IsmDataProvider.instance`** to fetch user posts, saved posts, collections, and to perform create/edit/delete and collection operations. All methods use callbacks: `onSuccess(responseJson, statusCode)` and `onError(errorMessage, statusCode)`.

### Collections

- **`fetchCollectionList`** – List collections (paginated).  
  Params: `page`, `pageSize`, `isLoading`, `isPublicOnly`.  
  Callbacks: `onSuccess`, `onError`.

- **`fetchCollectionPostList`** – Posts in a collection.  
  Params: `page`, `pageSize`, `collectionId`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`createCollection`** – Create collection.  
  Params: `requestMap` (e.g. `name`, `description`, `is_private`), `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`updateCollection`** – Update collection.  
  Params: `collectionId`, `requestMap`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`deleteCollection`** – Delete collection.  
  Params: `collectionId`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`movePostToCollection`** – Move a post into a collection.  
  Params: `postId`, `collectionId`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`removePostFromCollection`** – Remove post from saved/collection (unsave).  
  Params: `postId`.  
  Callbacks: `onSuccess`, `onError`.

### Posts

- **`getUserPosts`** – Posts for a user (profile).  
  Params: `userId`, `page`, `pageSize`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`getSavedPosts`** – Current user’s saved posts.  
  Params: `page`, `pageSize`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`getTaggedPosts`** – Posts by tag (hashtag, place, product, mention).  
  Params: `tagType` (`TagType.hashtag` / `place` / `product` / `mention`), `tagValue`, `page`, `pageSize`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`createPost`** – Create post.  
  Params: `createPostRequest` (map), `isLoading`.  
  Success status: 201. Callbacks: `onSuccess`, `onError`.

- **`editPost`** – Edit post.  
  Params: `postId`, `editPostRequest` (map), `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

- **`deletePost`** – Delete post.  
  Params: `postId`, `isLoading`.  
  Callbacks: `onSuccess`, `onError`.

### Example

```dart
import 'package:ism_video_reel_player/data/ism_data_provider.dart';

// User posts
IsmDataProvider.instance.getUserPosts(
  userId: currentUserId,
  page: 1,
  pageSize: 20,
  onSuccess: (json, code) => _handlePosts(json),
  onError: (msg, code) => _handleError(msg),
);

// Saved posts
IsmDataProvider.instance.getSavedPosts(
  page: 1,
  pageSize: 20,
  onSuccess: (json, code) => _handleSavedPosts(json),
  onError: (msg, code) => _handleError(msg),
);

// Tagged posts (e.g. hashtag)
IsmDataProvider.instance.getTaggedPosts(
  tagType: TagType.hashtag,
  tagValue: 'travel',
  page: 1,
  pageSize: 20,
  onSuccess: (json, code) => _handleTaggedPosts(json),
  onError: (msg, code) => _handleError(msg),
);
```

---

## Config & Callbacks

Config and callbacks are set via **`IsrVideoReelConfig`** (or passed into `initializeSdk`). All configs are optional; omit or pass `null` to use defaults.

| Config                    | Purpose |
|---------------------------|--------|
| **`socialConfig`**        | Theme, toasts, dialogs, buttons, fonts, colors; **SocialCallBackConfig**: `onLoginInvoked` (when login is required). |
| **`postConfig`**          | Post UI (overlay, actions, media indicator, profile, description, location, shop, follow button); **PostCallBackConfig**: save/like/follow/share/comment/profile/tag-product/post-changed. |
| **`tabConfig`**           | Tab bar, back button, loading, status bar; **TabCallBackConfig**: `onChangeOfTab`, `onReelsLoaded`, `getEmptyScreen`. |
| **`commentConfig`**       | Comment bottom sheet, header, item, reply field, placeholder, more options. |
| **`createEditPostConfig`**| Create/edit post UI (media selection, edit, attributes, tag people, search location, schedule); **CreateEditPostCallBackConfig**: `onLinkProduct`. |
| **`tagDetailsConfig`**     | Tag/hashtag/place details screen (scaffold, back button, profile, grid, cards, empty/error/loading). |
| **`searchScreenConfig`**   | Search screen (scaffold, app bar, search bar, tabs, grids, tags/places/accounts lists, empty/loading). |

### Key callbacks (summary)

- **SocialCallBackConfig**: `onLoginInvoked` → `Future<bool>` (login success/failure).
- **PostCallBackConfig**: `onSaveChanged`, `onLikeChanged`, `onSaveClicked`, `onLikeClick`, `onFollowClick`, `onShareClicked`, `onCommentClick`, `onProfileClick`, `onTagProductClick`, `onPostChanged`.
- **TabCallBackConfig**: `onChangeOfTab`, `onReelsLoaded`, `getEmptyScreen`.
- **CreateEditPostCallBackConfig**: `onLinkProduct`.

You can customize each config’s sub-properties (e.g. `ThemeConfig`, `ToastConfig`, `ButtonConfig`, `PostUIConfig`, etc.) as needed; see the respective model classes in the SDK for full options.

---

## Navigator – Opening SDK Pages

Use **`IsrAppNavigator`** with a valid `BuildContext` (e.g. from your navigator or `getCurrentBuildContext`) to open SDK screens.

### Reels / feed

- **`navigateToReelsPlayer`** – Full-screen reels with a list of posts.  
  Params: `context`, `postDataList`, `startingPostIndex`, `postSectionType`, optional `tagValue`, `tagType`, `tabConfig`, `postConfig`, `onTapPlace`, `transitionType`.

### Post listing & schedule

- **`navigateToPostListing`** – Post list by tag.  
  Params: `context`, `tagValue`, `tagType`, optional `transitionType`.

- **`navigateToSchedulePostListing`** – Scheduled posts.  
  Params: `context`, optional `transitionType`.

### Create / edit post

- **`goToCreatePostView`** – Create post flow. Returns `Future<String?>` (e.g. created post id).  
  Params: `context`, optional `transitionType`.

- **`goToEditPostView`** – Edit existing post. Returns `Future<String?>`.  
  Params: `context`, `postData` (`TimeLineData`), optional `transitionType`.

- **`goToCreatePostAttributionView`** – Post attribution (e.g. caption, options) for new media.  
  Params: `context`, `newMediaDataList`, `transitionType`.

### Tag people & search

- **`goToTagPeopleScreen`** – Tag people on post. Returns `Future<List<MentionData>?>`.  
  Params: `context`, `mentionDataList`, `mediaDataList`, `postId`, optional `transitionType`.

- **`goToSearchUserScreen`** – Search and select users. Returns `Future<List<SocialUserData>>`.  
  Params: `context`, `socialUserList`, optional `transitionType`.

### Location

- **`goToSearchLocation`** – Search and select location. Returns `Future<List<TaggedPlace>?>`.  
  Params: `context`, `taggedPlaceList`, optional `transitionType`.

### Media picker

- **`goToMediaPickerScreen`** – Pick/capture media. Returns `Future<List<MediaAssetData>?>`.  
  Params: `context`, `mediaSelectionConfig`, `selectedMedia`, `onComplete`, `onCaptureMedia`, optional `transitionType`.

### Place & tag details

- **`navigateToPlaceDetails`** – Place details.  
  Params: `context`, `placeId`, `placeName`, `latitude`, `longitude`, optional `transitionType`.

- **`navigateTagDetails`** – Tag/hashtag/place details.  
  Params: `context`, `tagValue`, `tagType`, optional `transitionType`.

### Insights & collections

- **`goToPostInsight`** – Post insights.  
  Params: `context`, `postId`, optional `postData`, `transitionType`.

- **`navigateCollectionDetailsView`** – Collection details. Returns `Future<CollectionData?>`.  
  Params: `context`, `collectionData`, optional `transitionType`.

### Common

- **`pop(context, result)`** – Pop current route with optional `result`.

### Enums

- **TagType**: `hashtag`, `place`, `product`, `mention`.
- **PostSectionType**: `forYou`, `following`, `trending`, `myPost`, `savedPost`, `tagPost`, etc.
- **TransitionType**: `bottomToTop`, `topToBottom`, `fade`, `leftToRight`, `rightToLeft`, `none`.

Example:

```dart
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';

// Open reels
IsrAppNavigator.navigateToReelsPlayer(
  context,
  postDataList: posts,
  startingPostIndex: 0,
  postSectionType: PostSectionType.forYou,
  transitionType: TransitionType.rightToLeft,
);

// Create post
final postId = await IsrAppNavigator.goToCreatePostView(context);

// Post listing by hashtag
IsrAppNavigator.navigateToPostListing(
  context,
  tagValue: 'travel',
  tagType: TagType.hashtag,
);
```

---

## Utilities

- **`IsrVideoReelConfig.precacheVideos(mediaUrls)`** – Best-effort precache of video URLs (async, no need to await).
- **`IsrVideoReelConfig.disposeVideoPlayers()`** – Dispose all video players (e.g. before hot restart in development).
- **`IsrVideoReelConfig.logEvent(eventName, eventData)`** – Log analytics event via RudderStack.
- **`IsrVideoReelConfig.isSdkInitialize`** – Whether the SDK has been initialized at least once.
- **`IsrVideoReelConfig.isContextAvailable`** – Whether a build context is available (e.g. from `getCurrentBuildContext`).

---

## Summary

1. Call **`initializeSdk`** on app open, user change, and login/logout with `baseUrl`, RudderStack keys, **`userInfoClass`**, and **`defaultHeaders`**.
2. Use **`IsmDataProvider.instance`** for user posts, saved posts, tagged posts, collections, and create/edit/delete post and collection APIs.
3. Set **configs and callbacks** on **`IsrVideoReelConfig`** (or in `initializeSdk`) to theme and react to social/post/tab/comment/create-edit/tag/search events.
4. Use **`IsrAppNavigator`** with your `BuildContext` to open reels, post listing, create/edit post, tag people, search user/location, media picker, place/tag details, insights, and collection details.

For detailed config properties (e.g. every `ThemeConfig` or `PostUIConfig` field), refer to the corresponding classes in `lib/domain/models/` and `lib/isr_video_reel_config.dart`.
