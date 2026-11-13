import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/backend_config.dart';

/// Outcome of a write, so screens can tell the user the truth.
///
/// [sent] means the data is in the store the app is built on (Postgres in
/// backend mode, SharedPreferences in local mode). [savedOnDevice] means the
/// server write failed and the item is queued on this device only — it has
/// not been shared yet.
enum SaveStatus { sent, savedOnDevice }

/// Application data store.
///
/// Two modes chosen by [BackendConfig.isConfigured]:
/// * Supabase mode — comments, inquiries and partner requests live in
///   Postgres and are shared across all devices. Writes that fail are queued
///   on the device instead of being silently lost, and retried on next load.
/// * Local mode — the same data in SharedPreferences (phase-1 behavior),
///   used by tests, demos and builds without keys.
///
/// The catalog (plans + resources) is always the bundled seed asset;
/// hosting it in Postgres/Storage is a later step.
/// Public API is identical in both modes.
class AppData {
  AppData._();
  static final AppData instance = AppData._();

  static const _seedAsset = 'assets/seed/seed_data.json';
  static const _prefsComments = 'local_comments';
  static const _prefsInquiries = 'local_inquiries';
  static const _prefsPartnerRequests = 'local_partner_requests';
  static const _prefsPendingComments = 'pending_comments';
  static const _prefsPendingInquiries = 'pending_inquiries';
  static const _prefsPendingPartnerRequests = 'pending_partner_requests';

  final List<BusinessPlan> plans = [];
  final List<ResourceCategory> resources = [];
  final List<PlanComment> comments = [];

  /// Inquiries carry `pending: true` while they are only stored on this
  /// device.
  final List<Map<String, dynamic>> inquiries = [];

  /// Partner requests carry `pending: true` while they are only stored on
  /// this device.
  final List<Map<String, dynamic>> partnerRequests = [];

  bool _loaded = false;

  bool get _useBackend => BackendConfig.isConfigured;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(_seedAsset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    plans.addAll(
      (map['business_plans'] as List)
          .map((e) => BusinessPlan.fromJson(e as Map<String, dynamic>)),
    );
    resources.addAll(
      (map['resources'] as List)
          .map((e) => ResourceCategory.fromJson(e as Map<String, dynamic>)),
    );

    if (_useBackend) {
      await _loadShared();
      await _loadPending();
      await _retryPending();
    } else {
      await _loadLocal();
    }
    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = prefs.getString(_prefsComments);
    if (commentsJson != null) {
      comments.addAll(
        (jsonDecode(commentsJson) as List)
            .map((e) => PlanComment.fromJson(e as Map<String, dynamic>)),
      );
    }
    final inquiriesJson = prefs.getString(_prefsInquiries);
    if (inquiriesJson != null) {
      inquiries.addAll(
        (jsonDecode(inquiriesJson) as List).cast<Map<String, dynamic>>(),
      );
    }
    final partnerJson = prefs.getString(_prefsPartnerRequests);
    if (partnerJson != null) {
      partnerRequests.addAll(
        (jsonDecode(partnerJson) as List).cast<Map<String, dynamic>>(),
      );
    }
  }

  Future<void> _loadShared() async {
    try {
      final rows =
          await BackendConfig.client.from('comments').select().order('id');
      comments.addAll(
        rows.map((e) => PlanComment.fromJson(Map<String, dynamic>.from(e))),
      );
    } catch (_) {
      // Offline or table not migrated yet — pending writes are restored below
      // and retried, so nothing is lost.
    }
    try {
      final rows =
          await BackendConfig.client.from('inquiries').select().order('id');
      inquiries.addAll(rows.map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {
      // Inbox is admin-only via RLS; non-admins simply see nothing.
    }
    try {
      final rows = await BackendConfig.client
          .from('partner_requests')
          .select()
          .order('id');
      partnerRequests.addAll(rows.map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {
      // Same as above — RLS hides other users' requests.
    }
  }

  /// Restores submissions that were queued while offline (or after a failed
  /// write) so they stay visible, flagged as pending, and get retried.
  Future<void> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();

    final commentsJson = prefs.getString(_prefsPendingComments);
    if (commentsJson != null) {
      comments.addAll(
        (jsonDecode(commentsJson) as List).map(
          (e) => PlanComment.fromJson(Map<String, dynamic>.from(e as Map))
              .copyWith(pending: true),
        ),
      );
    }

    final inquiriesJson = prefs.getString(_prefsPendingInquiries);
    if (inquiriesJson != null) {
      inquiries.addAll(
        (jsonDecode(inquiriesJson) as List).map(
          (e) => {
            ...Map<String, dynamic>.from(e as Map),
            'pending': true,
          },
        ),
      );
    }

    final partnerJson = prefs.getString(_prefsPendingPartnerRequests);
    if (partnerJson != null) {
      partnerRequests.addAll(
        (jsonDecode(partnerJson) as List).map(
          (e) => {
            ...Map<String, dynamic>.from(e as Map),
            'pending': true,
          },
        ),
      );
    }
  }

  /// Flushes the device queues, best effort, once per app start. Anything the
  /// server still rejects stays queued and keeps being reported as pending.
  Future<void> _retryPending() async {
    for (final pending in comments.where((c) => c.pending).toList()) {
      final row = await _sendComment(pending);
      if (row == null) continue;
      final index = comments.indexOf(pending);
      if (index != -1) comments[index] = row;
    }
    await _persistPendingComments();

    for (final pending in inquiries.where(_isPending).toList()) {
      if (!await _sendInquiry(pending)) continue;
      final index = inquiries.indexOf(pending);
      if (index != -1) inquiries[index] = {...pending, 'pending': false};
    }
    await _persistPendingInquiries();

    for (final pending in partnerRequests.where(_isPending).toList()) {
      final row = await _sendPartnerRequest(pending);
      if (row == null) continue;
      final index = partnerRequests.indexOf(pending);
      if (index != -1) partnerRequests[index] = {...row, 'pending': false};
    }
    await _persistPendingPartnerRequests();
  }

  static bool _isPending(Map<String, dynamic> row) => row['pending'] == true;

  // ---------------------------------------------------------------------------
  // Catalog queries (identical in both modes)
  // ---------------------------------------------------------------------------

  List<BusinessPlan> plansForResource(String resource) => resource.isEmpty
      ? List.unmodifiable(plans)
      : plans.where((p) => p.resourceName == resource).toList();

  List<String> get priceRanges =>
      plans.map((p) => p.priceRange).where((s) => s.isNotEmpty).toSet().toList()
        ..sort();

  List<String> get cities =>
      plans.map((p) => p.city).where((s) => s.isNotEmpty).toSet().toList()
        ..sort();

  List<PlanComment> commentsFor(int planId) =>
      comments.where((c) => c.planId == planId).toList();

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Adds a comment. In Supabase mode the row is inserted server-side; if the
  /// write fails the comment is queued on the device and
  /// [SaveStatus.savedOnDevice] is returned so the UI never claims it was
  /// shared when it was not.
  Future<SaveStatus> addComment(PlanComment comment) async {
    if (_useBackend) {
      final row = await _sendComment(comment);
      if (row != null) {
        comments.add(row);
        return SaveStatus.sent;
      }
      comments.add(comment.copyWith(pending: true));
      await _persistPendingComments();
      return SaveStatus.savedOnDevice;
    }
    comments.add(comment);
    await _persistComments();
    return SaveStatus.sent;
  }

  Future<void> deleteComment(int id) async {
    final removed = comments.where((c) => c.id == id).toList();
    comments.removeWhere((c) => c.id == id);
    final wasPending = removed.any((c) => c.pending);

    if (_useBackend) {
      if (!wasPending) {
        try {
          await BackendConfig.client.from('comments').delete().eq('id', id);
        } catch (_) {
          // Removed locally either way; a failed delete is not data loss.
        }
      }
      await _persistPendingComments();
      return;
    }
    await _persistComments();
  }

  /// Records a Contact Us inquiry (name/email/inquiry/created_at).
  Future<SaveStatus> addInquiry(Map<String, dynamic> inquiry) async {
    if (_useBackend) {
      if (await _sendInquiry(inquiry)) {
        inquiries.add({...inquiry});
        return SaveStatus.sent;
      }
      inquiries.add({...inquiry, 'pending': true});
      await _persistPendingInquiries();
      return SaveStatus.savedOnDevice;
    }
    inquiries.add({...inquiry});
    await _persistInquiries();
    return SaveStatus.sent;
  }

  /// Records a partnership request for a plan (username/plan/created_at).
  Future<SaveStatus> addPartnerRequest(Map<String, dynamic> request) async {
    if (_useBackend) {
      final row = await _sendPartnerRequest(request);
      if (row != null) {
        partnerRequests.add(row);
        return SaveStatus.sent;
      }
      partnerRequests.add({...request, 'pending': true});
      await _persistPendingPartnerRequests();
      return SaveStatus.savedOnDevice;
    }
    partnerRequests.add({...request});
    await _persistPartnerRequests();
    return SaveStatus.sent;
  }

  // ---------------------------------------------------------------------------
  // Server writes (null/false means "could not reach the server")
  // ---------------------------------------------------------------------------

  Future<PlanComment?> _sendComment(PlanComment comment) async {
    try {
      final row = await BackendConfig.client
          .from('comments')
          .insert({
            'plan_id': comment.planId,
            'username': comment.username,
            'comment_text': comment.text,
          })
          .select()
          .single();
      return PlanComment.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  /// Inquiries are insert-only for ordinary users (RLS hides the inbox), so
  /// the insert must not ask for the row back: `return=representation` needs a
  /// select policy the user does not have.
  Future<bool> _sendInquiry(Map<String, dynamic> inquiry) async {
    try {
      await BackendConfig.client.from('inquiries').insert({
        'name': inquiry['name'],
        'email': inquiry['email'],
        'inquiry': inquiry['inquiry'],
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _sendPartnerRequest(
    Map<String, dynamic> request,
  ) async {
    try {
      final row = await BackendConfig.client
          .from('partner_requests')
          .insert({
            'plan_id': request['plan_id'],
            'plan_name': request['plan_name'],
            'username': request['username'],
            if (request['message'] != null) 'message': request['message'],
          })
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Local persistence
  // ---------------------------------------------------------------------------

  Future<void> _persistComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsComments,
      jsonEncode(comments.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _persistInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsInquiries, jsonEncode(inquiries));
  }

  Future<void> _persistPartnerRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPartnerRequests, jsonEncode(partnerRequests));
  }

  Future<void> _persistPendingComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsPendingComments,
      jsonEncode(
        comments.where((c) => c.pending).map((c) => c.toJson()).toList(),
      ),
    );
  }

  Future<void> _persistPendingInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsPendingInquiries,
      jsonEncode(inquiries.where(_isPending).toList()),
    );
  }

  Future<void> _persistPendingPartnerRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsPendingPartnerRequests,
      jsonEncode(partnerRequests.where(_isPending).toList()),
    );
  }

  int nextCommentId() => comments.isEmpty
      ? 1
      : comments.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
}
