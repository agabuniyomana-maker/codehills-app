import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../data/app_data.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// Business-plan detail — port of PlanDetailPanel.java:
/// cover, facts, PDF download, comments, partner request.
class PlanDetailScreen extends StatefulWidget {
  final BusinessPlan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    try {
      final bundle = DefaultAssetBundle.of(context);
      final docs = await getApplicationDocumentsDirectory();
      final target = File('${docs.path}/${widget.plan.pdfFileName}');
      final data = await bundle.load(widget.plan.pdfAssetPath);
      await target.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      if (!mounted) return;
      _showMessage('Business plan saved to:\n${target.path}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not save the PDF: $e');
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    final user = AuthService.instance.session?.username;
    if (text.isEmpty || user == null) return;
    final status = await AppData.instance.addComment(
      PlanComment(
        id: AppData.instance.nextCommentId(),
        planId: widget.plan.planId,
        username: user,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    _commentController.clear();
    if (!mounted) return;
    setState(() {});
    if (status == SaveStatus.savedOnDevice) {
      _showMessage(
        'Comment saved on this device. It will be shared when you are back '
        'online.',
      );
    }
  }

  void _partnerRequest() {
    final user = AuthService.instance.session?.username ?? 'guest';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const PortalHeading('Partner Request', size: 18),
        content: Text(
          'Send a partnership request for "${widget.plan.planName}"?\n\n'
          'It will be shared with the Code Hills team.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final status = await AppData.instance.addPartnerRequest({
                'plan_id': widget.plan.planId,
                'plan_name': widget.plan.planName,
                'username': user,
                'created_at': DateTime.now().toIso8601String(),
              });
              if (!mounted) return;
              _showMessage(
                status == SaveStatus.sent
                    ? 'Partnership request sent for '
                        '"${widget.plan.planName}".'
                    : 'Request saved on this device and will be sent when '
                        'you are back online.',
              );
            },
            child: const Text('SEND REQUEST'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final comments = AppData.instance.commentsFor(plan.planId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        foregroundColor: AppColors.cream,
        title: Text(
          plan.planName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: PortalCard(
        radius: 0,
        border: Colors.transparent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      plan.coverAssetPath,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 240,
                        color: AppColors.gold,
                        child: const Icon(
                          Icons.park,
                          size: 64,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: PortalHeading(plan.planName, size: 24),
                      ),
                      _typeBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PortalHeading(
                    plan.resourceName,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 18),
                  PortalCard(
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          _fact(Icons.location_on_outlined, 'CITY', plan.city),
                          _fact(
                            Icons.payments_outlined,
                            'PRICE RANGE',
                            plan.priceRange,
                          ),
                          _fact(
                            Icons.confirmation_number_outlined,
                            'PLAN ID',
                            '#${plan.planId}',
                          ),
                          _fact(
                            Icons.download_outlined,
                            'DOWNLOADS',
                            '${plan.downloadCount}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PortalButton(
                    label: 'DOWNLOAD BUSINESS PLAN (PDF)',
                    onPressed: _downloadPdf,
                  ),
                  const SizedBox(height: 12),
                  PortalButton(
                    label: 'REQUEST PARTNERSHIP',
                    onPressed: _partnerRequest,
                    filled: false,
                  ),
                  const SizedBox(height: 26),
                  const Divider(color: AppColors.gold),
                  const PortalHeading('Comments', size: 18),
                  const SizedBox(height: 12),
                  _commentComposer(),
                  const SizedBox(height: 12),
                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: PortalHeading(
                        'No comments yet — be the first',
                        size: 13,
                        color: AppColors.mutedBrown,
                      ),
                    )
                  else
                    for (final c in comments) _commentTile(c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _commentComposer() {
    final user = AuthService.instance.session?.username ?? '';
    return PortalCard(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ImigongoAvatar(
              seed: AuthService.instance.session?.accountId ?? user,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _postComment,
              icon: const Icon(Icons.send, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentTile(PlanComment c) {
    final mine = c.username == AuthService.instance.session?.username;
    final isAdmin = AuthService.instance.session?.isAdmin == true;
    return PortalCard(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImigongoAvatar(seed: c.username),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(c.text, style: const TextStyle(fontSize: 14)),
                  if (c.pending)
                    const Text(
                      'Saved on this device — not shared yet',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.mutedBrown,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(c.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedBrown,
                    ),
                  ),
                ],
              ),
            ),
            if (mine || isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.mutedBrown,
                onPressed: () async {
                  await AppData.instance.deleteComment(c.id);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.plan.isPremium ? AppColors.darkBrown : AppColors.yellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.plan.isPremium ? 'PREMIUM' : 'FREE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color:
                widget.plan.isPremium ? AppColors.yellow : AppColors.darkBrown,
          ),
        ),
      );

  Widget _fact(IconData icon, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mutedBrown,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      );

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
