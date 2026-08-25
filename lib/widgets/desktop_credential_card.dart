import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/credential.dart';
import '../services/encryption_service.dart';

class DesktopCredentialCard extends StatefulWidget {
  final Credential credential;
  final VoidCallback onTap;

  const DesktopCredentialCard({
    super.key,
    required this.credential,
    required this.onTap,
  });

  @override
  State<DesktopCredentialCard> createState() => _DesktopCredentialCardState();
}

class _DesktopCredentialCardState extends State<DesktopCredentialCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: _isHovered ? 4 : 1,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // App Icon/Initial
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.credential.profileName.isNotEmpty 
                          ? widget.credential.profileName[0].toUpperCase()
                          : (widget.credential.appName.isNotEmpty ? widget.credential.appName[0].toUpperCase() : '?'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Profile Name and Username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.credential.profileName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.credential.isFavorite) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.credential.username,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Category Badge
                if (widget.credential.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.credential.category!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(widget.credential.category!),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.credential.category!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(widget.credential.category!),
                      ),
                    ),
                  ),
                
                const SizedBox(width: 16),
                
                // Quick Actions (shown on hover)
                if (_isHovered)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Copy Username',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.credential.username));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Username copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.key, size: 20),
                        tooltip: 'Copy Password',
                        onPressed: () {
                          final decryptedPassword = EncryptionService.instance.tryDecrypt(
                            widget.credential.encryptedPassword,
                          );
                          if (decryptedPassword == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to decrypt password on this device'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            return;
                          }
                          Clipboard.setData(ClipboardData(text: decryptedPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return Colors.blue;
      case 'banking':
        return Colors.green;
      case 'email':
        return Colors.orange;
      case 'work':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
