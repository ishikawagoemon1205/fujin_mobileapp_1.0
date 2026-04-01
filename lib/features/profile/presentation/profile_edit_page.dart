/*
====================================================
目的:
  - ユーザープロフィール編集画面
  - 表示名の変更と保存

処理構造:
  - Firestore からプロフィール読み込み
  - 表示名の編集フォーム
  - Firestore への保存処理
  - エラーハンドリング
====================================================
*/

import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/box_repository.dart';

/// プロフィール編集画面
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _displayNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _email;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _displayNameController.text =
            (data['displayName'] as String?) ?? '';
        _email = data['email'] as String?;
        _photoUrl = data['photoUrl'] as String?;
      } else {
        _displayNameController.text = user.displayName ?? '';
        _email = user.email;
        _photoUrl = user.photoURL;
      }
    } catch (_) {
      _displayNameController.text = user.displayName ?? '';
      _email = user.email;
      _photoUrl = user.photoURL;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('表示名を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          'displayName': displayName,
          'updatedAt': Timestamp.now(),
        });
      } else {
        await docRef.set({
          'email': user.email ?? '',
          'displayName': displayName,
          'photoUrl': user.photoURL,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        // ホーム画面のプロフィール表示を最新化するためキャッシュを破棄する
        ref.invalidate(currentUserProfileProvider);
        // Beamer 管理下のため Navigator.pop() ではなくホームへ遷移する
        context.beamToNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: _photoUrl == null || _photoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (_email != null && _email!.isNotEmpty)
                    Text(
                      _email!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: '表示名',
                      hintText: 'あなたの名前を入力',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    maxLength: 50,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveProfile(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
