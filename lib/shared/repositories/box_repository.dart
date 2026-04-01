/*
====================================================
目的:
  - Riverpod プロバイダーの集約定義
  - 各 feature の Repository / UseCase の依存性注入

処理構造:
  - Repository プロバイダー定義
  - UseCase プロバイダー定義
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/box_detail/data/repositories/firestore_box_detail_repository.dart';
import '../../features/box_detail/domain/repositories/box_detail_repository.dart';
import '../../features/box_detail/domain/usecases/get_box_detail_usecase.dart';
import '../../features/box_list/data/repositories/firestore_box_list_repository.dart';
import '../../features/box_list/domain/repositories/box_list_repository.dart';
import '../../features/box_list/domain/usecases/get_all_boxes_usecase.dart';
import '../../features/seal/data/repositories/firestore_seal_repository.dart';
import '../../features/seal/domain/repositories/seal_repository.dart';
import '../../features/seal/domain/usecases/create_box_usecase.dart';
import '../../features/unseal/data/repositories/firestore_unseal_repository.dart';
import '../../features/unseal/domain/repositories/unseal_repository.dart';
import '../../features/unseal/domain/usecases/unseal_box_usecase.dart';
import '../../features/verify/data/repositories/firestore_verify_repository.dart';
import '../../features/verify/domain/repositories/verify_repository.dart';
import '../../features/verify/domain/usecases/get_box_usecase.dart';
import '../../features/friends/data/repositories/firestore_friends_repository.dart';
import '../../features/friends/domain/repositories/friends_repository.dart';
import '../../features/friends/domain/usecases/get_friends_usecase.dart';
import '../../features/friends/domain/usecases/send_friend_request_usecase.dart';
import '../../features/friends/domain/usecases/accept_friend_request_usecase.dart';
import '../../features/friends/domain/usecases/decline_friend_request_usecase.dart';
import '../../features/friends/domain/usecases/delete_friend_usecase.dart';
import '../../features/friends/domain/usecases/generate_invite_link_usecase.dart';
import '../../features/groups/data/repositories/firestore_groups_repository.dart';
import '../../features/groups/domain/repositories/groups_repository.dart';
import '../../features/groups/domain/usecases/get_groups_usecase.dart';
import '../../features/groups/domain/usecases/create_group_usecase.dart';
import '../../features/groups/domain/usecases/accept_group_invite_usecase.dart';
import '../../features/groups/domain/usecases/decline_group_invite_usecase.dart';
import '../../features/groups/domain/usecases/disband_group_usecase.dart';
import '../../features/groups/domain/usecases/leave_group_usecase.dart';
import '../../features/groups/domain/usecases/remove_member_usecase.dart';
import '../../features/groups/domain/usecases/invite_member_usecase.dart';
import '../../features/groups/domain/usecases/update_group_name_usecase.dart';
import '../../features/notifications/data/repositories/firestore_notifications_repository.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/get_unread_count_usecase.dart';
import '../../features/notifications/domain/usecases/mark_as_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_as_read_usecase.dart';

// ============================================================
// 認証
// ============================================================

/// 認証 Repository プロバイダー（AuthGate で再利用）
final authRepositoryImplProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// サインアウト UseCase プロバイダー
final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryImplProvider));
});

/// 現在のユーザーID を取得するヘルパー Provider
///
/// authStateProvider（Stream）を watch することで、
/// ログイン・ログアウト・ユーザー切り替え時に自動的に再計算される
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid).value;
});

/// Firestore からログイン中ユーザーのプロフィールを取得する Provider
///
/// authStateProvider でログイン状態を監視し、uid が変わると再取得する。
/// ホーム画面など Firestore の displayName を表示したい箇所で使う。
final currentUserProfileProvider = FutureProvider.autoDispose<Map<String, String?>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return {};

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return {};

  final data = doc.data()!;
  return {
    'displayName': data['displayName'] as String?,
    'email': data['email'] as String?,
    'photoUrl': data['photoUrl'] as String?,
  };
});

// ============================================================
// 封印（Seal）
// ============================================================

/// 封印 Repository プロバイダー
final sealRepositoryProvider = Provider<SealRepository>((ref) {
  return FirestoreSealRepository();
});

/// 封印 UseCase プロバイダー
final createBoxUseCaseProvider = Provider<CreateBoxUseCase>((ref) {
  return CreateBoxUseCase(ref.watch(sealRepositoryProvider));
});

// ============================================================
// 確認（Verify）
// ============================================================

/// 確認 Repository プロバイダー
final verifyRepositoryProvider = Provider<VerifyRepository>((ref) {
  return FirestoreVerifyRepository();
});

/// 確認 UseCase プロバイダー
final getBoxUseCaseProvider = Provider<GetBoxUseCase>((ref) {
  return GetBoxUseCase(ref.watch(verifyRepositoryProvider));
});

// ============================================================
// 開封（Unseal）
// ============================================================

/// 開封 Repository プロバイダー
final unsealRepositoryProvider = Provider<UnsealRepository>((ref) {
  return FirestoreUnsealRepository();
});

/// 開封 UseCase プロバイダー
final unsealBoxUseCaseProvider = Provider<UnsealBoxUseCase>((ref) {
  return UnsealBoxUseCase(ref.watch(unsealRepositoryProvider));
});

// ============================================================
// 箱詳細（Box Detail）
// ============================================================

/// 箱詳細 Repository プロバイダー
final boxDetailRepositoryProvider = Provider<BoxDetailRepository>((ref) {
  return FirestoreBoxDetailRepository();
});

/// 箱詳細 UseCase プロバイダー
final getBoxDetailUseCaseProvider = Provider<GetBoxDetailUseCase>((ref) {
  return GetBoxDetailUseCase(ref.watch(boxDetailRepositoryProvider));
});

// ============================================================
// 箱一覧（Box List）
// ============================================================

/// 箱一覧 Repository プロバイダー
final boxListRepositoryProvider = Provider<BoxListRepository>((ref) {
  return FirestoreBoxListRepository();
});

/// 箱一覧 UseCase プロバイダー
final getAllBoxesUseCaseProvider = Provider<GetAllBoxesUseCase>((ref) {
  return GetAllBoxesUseCase(ref.watch(boxListRepositoryProvider));
});

// ============================================================
// フレンド（Friends）
// ============================================================

/// フレンド Repository プロバイダー
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FirestoreFriendsRepository();
});

/// フレンド一覧取得 UseCase プロバイダー
final getFriendsUseCaseProvider = Provider<GetFriendsUseCase>((ref) {
  return GetFriendsUseCase(ref.watch(friendsRepositoryProvider));
});

/// フレンドリクエスト送信 UseCase プロバイダー
final sendFriendRequestUseCaseProvider =
    Provider<SendFriendRequestUseCase>((ref) {
  return SendFriendRequestUseCase(ref.watch(friendsRepositoryProvider));
});

/// フレンドリクエスト承認 UseCase プロバイダー
final acceptFriendRequestUseCaseProvider =
    Provider<AcceptFriendRequestUseCase>((ref) {
  return AcceptFriendRequestUseCase(ref.watch(friendsRepositoryProvider));
});

/// フレンドリクエスト拒否 UseCase プロバイダー
final declineFriendRequestUseCaseProvider =
    Provider<DeclineFriendRequestUseCase>((ref) {
  return DeclineFriendRequestUseCase(ref.watch(friendsRepositoryProvider));
});

/// フレンド削除 UseCase プロバイダー
final deleteFriendUseCaseProvider = Provider<DeleteFriendUseCase>((ref) {
  return DeleteFriendUseCase(ref.watch(friendsRepositoryProvider));
});

/// 招待リンク生成 UseCase プロバイダー
final generateInviteLinkUseCaseProvider =
    Provider<GenerateInviteLinkUseCase>((ref) {
  return GenerateInviteLinkUseCase(ref.watch(friendsRepositoryProvider));
});

// ============================================================
// グループ（Groups）
// ============================================================

/// グループ Repository プロバイダー
final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return FirestoreGroupsRepository();
});

/// グループ一覧取得 UseCase プロバイダー
final getGroupsUseCaseProvider = Provider<GetGroupsUseCase>((ref) {
  return GetGroupsUseCase(ref.watch(groupsRepositoryProvider));
});

/// グループ作成 UseCase プロバイダー
final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(ref.watch(groupsRepositoryProvider));
});

/// グループ招待承認 UseCase プロバイダー
final acceptGroupInviteUseCaseProvider =
    Provider<AcceptGroupInviteUseCase>((ref) {
  return AcceptGroupInviteUseCase(ref.watch(groupsRepositoryProvider));
});

/// グループ招待拒否 UseCase プロバイダー
final declineGroupInviteUseCaseProvider =
    Provider<DeclineGroupInviteUseCase>((ref) {
  return DeclineGroupInviteUseCase(ref.watch(groupsRepositoryProvider));
});

/// グループ解散 UseCase プロバイダー
final disbandGroupUseCaseProvider = Provider<DisbandGroupUseCase>((ref) {
  return DisbandGroupUseCase(ref.watch(groupsRepositoryProvider));
});

/// グループ脱退 UseCase プロバイダー
final leaveGroupUseCaseProvider = Provider<LeaveGroupUseCase>((ref) {
  return LeaveGroupUseCase(ref.watch(groupsRepositoryProvider));
});

/// メンバー除外 UseCase プロバイダー
final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  return RemoveMemberUseCase(ref.watch(groupsRepositoryProvider));
});

/// メンバー招待 UseCase プロバイダー
final inviteMemberUseCaseProvider = Provider<InviteMemberUseCase>((ref) {
  return InviteMemberUseCase(ref.watch(groupsRepositoryProvider));
});

/// グループ名変更 UseCase プロバイダー
final updateGroupNameUseCaseProvider =
    Provider<UpdateGroupNameUseCase>((ref) {
  return UpdateGroupNameUseCase(ref.watch(groupsRepositoryProvider));
});

// ============================================================
// 通知（Notifications）
// ============================================================

/// 通知 Repository プロバイダー
final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return FirestoreNotificationsRepository();
});

/// 通知一覧取得 UseCase プロバイダー
final getNotificationsUseCaseProvider =
    Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.watch(notificationsRepositoryProvider));
});

/// 未読数取得 UseCase プロバイダー
final getUnreadCountUseCaseProvider = Provider<GetUnreadCountUseCase>((ref) {
  return GetUnreadCountUseCase(ref.watch(notificationsRepositoryProvider));
});

/// 既読設定 UseCase プロバイダー
final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>((ref) {
  return MarkAsReadUseCase(ref.watch(notificationsRepositoryProvider));
});

/// 全既読設定 UseCase プロバイダー
final markAllAsReadUseCaseProvider = Provider<MarkAllAsReadUseCase>((ref) {
  return MarkAllAsReadUseCase(ref.watch(notificationsRepositoryProvider));
});
