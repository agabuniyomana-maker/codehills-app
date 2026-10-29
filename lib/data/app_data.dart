import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/backend_config.dart';

/// Application data store.
///
/// Two modes chosen by [BackendConfig.isConfigured]:
/// * Supabase mode — comments, inquiries and partner requests live in
///   Postgres and are shared across all devices.
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

  final List<BusinessPlan> plans = [];
  final List<ResourceCategory> resources = [];
  final List<PlanComment> comments = [];
  final List<Map<String, dynamic>> inquiries = [];
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
      comments.addAll(rows.map((e) => PlanComment.fromJson(e)));
    } catch (_) {
      // Offline or table not migrated yet — start empty, writes still queue
      // into local storage via the local fallback paths.
    }
    try {
      final rows =
          await BackendConfig.client.from('inquiries').select().order('id');
      inquiries.addAll(rows.cast<Map<String, dynamic>>());
    } catch (_) {
      // Inbox is admin-only via RLS; non-admins simply see nothing.
    }
    try {
      final rows = await BackendConfig.client
          .from('partner_requests')
          .select()
          .order('id');
      partnerRequests.addAll(rows.cast<Map<String, dynamic>>());
    } catch (_) {
      // Same as above — RLS hides other users' requests.
    }
  }

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

  /// Adds a comment. In Supabase mode the row is inserted server-side and
  /// the stored row (with its real id + timestamp) replaces the local one.
  Future<void> addComment(PlanComment comment) async {
    if (_useBackend) {
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
        comments.add(PlanComment.fromJson(row));
        return;
      } catch (_) {
        // Fall through: keep the comment locally so nothing is lost offline.
      }
    }
    comments.add(comment);
    await _persistComments();
  }

  Future<void> deleteComment(int id) async {
    comments.removeWhere((c) => c.id == id);
    if (_useBackend) {
      try {
        await BackendConfig.client.from('comments').delete().eq('id', id);
      } catch (_) {
        // Removed locally either way; server row retries on next load.
      }
      return;
    }
    await _persistComments();
  }

  /// Records a Contact Us inquiry (name/email/inquiry/created_at).
  Future<void> addInquiry(Map<String, dynamic> inquiry) async {
    if (_useBackend) {
      try {
        final row = await BackendConfig.client
            .from('inquiries')
            .insert({
              'name': inquiry['name'],
              'email': inquiry['email'],
              'inquiry': inquiry['inquiry'],
            })
            .select()
            .single();
        inquiries.add(row);
        return;
      } catch (_) {
        // Fall through to local so the submission is not lost.
      }
    }
    inquiries.add(inquiry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsInquiries, jsonEncode(inquiries));
  }

  /// Records a partnership request for a plan (username/plan/created_at).
  Future<void> addPartnerRequest(Map<String, dynamic> request) async {
    if (_useBackend) {
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
        partnerRequests.add(row);
        return;
      } catch (_) {
        // Fall through to local so the request is not lost.
      }
    }
    partnerRequests.add(request);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsPartnerRequests,
      jsonEncode(partnerRequests),
    );
  }

  Future<void> _persistComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsComments,
      jsonEncode(comments.map((c) => c.toJson()).toList()),
    );
  }

  int nextCommentId() => comments.isEmpty
      ? 1
      : comments.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
}
