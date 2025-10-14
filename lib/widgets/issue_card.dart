import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/issue_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../utils/image_optimizer.dart';

class IssueCard extends StatefulWidget {
  final IssueModel issue;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onComment;
  final bool showUpvoteButton;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.onUpvote,
    this.onComment,
    this.showUpvoteButton = true,
  });

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize like state
    _initializeLikeState();
  }

  void _initializeLikeState() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user != null) {
      _isLiked = widget.issue.isLikedBy(user.id);
    }
  }

  @override
  void didUpdateWidget(IssueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update like state when issue data changes
    if (oldWidget.issue.id != widget.issue.id ||
        oldWidget.issue.likedBy.length != widget.issue.likedBy.length) {
      _initializeLikeState();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  void _handleLike() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) {
      AppHelpers.showErrorSnackBar(context, 'Please login to like issues');
      return;
    }

    // Update UI immediately
    setState(() {
      _isLiked = !_isLiked;
    });

    // Play quick animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Handle database operation in background
    _handleLikeInBackground(user.id);
  }

  Future<void> _handleLikeInBackground(String userId) async {
    try {
      if (_isLiked) {
        await _firestoreService.upvoteIssue(widget.issue.id, userId);
      } else {
        await _firestoreService.removeUpvote(widget.issue.id, userId);
      }

      // Upvote handled locally, no need to notify parent
    } catch (e) {
      // Revert UI state on error
      setState(() {
        _isLiked = !_isLiked;
      });
      AppHelpers.showErrorSnackBar(context, 'Failed to like issue');
    }
  }

  void _handleSolveIssue(BuildContext context) {
    // Navigate to the solve issue screen
    Navigator.pushNamed(
      context,
      '/solve-issue',
      arguments: widget.issue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF667eea).withOpacity(0.1),
          highlightColor: const Color(0xFF667eea).withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // User Avatar
                      Hero(
                        tag: 'user_avatar_${widget.issue.id}',
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: widget.issue.userProfileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: ImageOptimizer.getOptimizedCloudinaryUrl(
                                      widget.issue.userProfileImageUrl!,
                                      optimization: CloudinaryOptimization.thumbnail,
                                    ),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF667eea),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFF667eea),
                                      child: Center(
                                        child: Text(
                                          widget.issue.userName.isNotEmpty
                                              ? widget.issue.userName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF667eea),
                                    child: Center(
                                      child: Text(
                                        widget.issue.userName.isNotEmpty
                                            ? widget.issue.userName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.issue.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppHelpers.formatTimeAgo(widget.issue.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      _buildStatusChip(),
                    ],
                  ),
                ),
                // Issue Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.issue.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1A202C),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),

                // Issue Type Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.getIssueTypeColor(widget.issue.issueType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.getIssueTypeColor(widget.issue.issueType).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppHelpers.getIssueTypeEmoji(widget.issue.issueType),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.issue.issueType,
                          style: TextStyle(
                            color: AppTheme.getIssueTypeColor(widget.issue.issueType),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.issue.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Image Section
                if (widget.issue.imageUrl != null) ...[
                  Hero(
                    tag: 'issue_image_${widget.issue.id}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: ImageOptimizer.getOptimizedCloudinaryUrl(
                            widget.issue.imageUrl!,
                            optimization: CloudinaryOptimization.preview,
                          ),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Like Button
                      if (widget.showUpvoteButton) ...[
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: InkWell(
                                onTap: _handleLike,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isLiked ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isLiked ? Colors.red.withOpacity(0.3) : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: _isLiked ? Colors.red : Colors.grey[600],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.issue.upvotes}',
                                        style: TextStyle(
                                          color: _isLiked ? Colors.red : Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Comment Button
                      InkWell(
                        onTap: widget.onComment,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: const Color(0xFF667eea),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Comment',
                                style: TextStyle(
                                  color: const Color(0xFF667eea),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Solve Issue Button
                      if (widget.issue.status != 'Resolved')
                        InkWell(
                          onTap: () => _handleSolveIssue(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.build_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Solve',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Map Button (if location exists)
                      if (widget.issue.location.isNotEmpty &&
                          widget.issue.location['lat'] != null &&
                          widget.issue.location['lng'] != null)
                        InkWell(
                          onTap: () {
                            final lat = widget.issue.location['lat']!;
                            final lng = widget.issue.location['lng']!;
                            AppHelpers.openInMap(context, lat, lng, widget.issue.title);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.blue[700],
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Authority Response Badge
                if (widget.issue.authorityNotes != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Authority Response Available',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.orange[700],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusColor = AppTheme.getStatusColor(widget.issue.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getStatusEmoji(widget.issue.status),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            widget.issue.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class IssueListTile extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final bool showUpvoteButton;
  final bool isUpvoted;

  const IssueListTile({
    super.key,
    required this.issue,
    this.onTap,
    this.onUpvote,
    this.showUpvoteButton = true,
    this.isUpvoted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.getStatusColor(issue.status).withOpacity(0.1),
        child: Text(
          AppHelpers.getStatusEmoji(issue.status),
          style: TextStyle(
            color: AppTheme.getStatusColor(issue.status),
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        issue.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                AppHelpers.getIssueTypeEmoji(issue.issueType),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                issue.issueType,
                style: TextStyle(
                  color: AppTheme.darkGrey,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                AppHelpers.formatTimeAgo(issue.createdAt),
                style: TextStyle(
                  color: AppTheme.darkGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: showUpvoteButton
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onUpvote,
                  icon: Icon(
                    isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isUpvoted ? AppTheme.primaryBlue : AppTheme.darkGrey,
                  ),
                ),
                Text('${issue.upvotes}'),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}
