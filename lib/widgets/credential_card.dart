import 'package:flutter/material.dart';
import '../models/credential.dart';

class CredentialCard extends StatelessWidget {
  final Credential credential;
  final VoidCallback onTap;

  const CredentialCard({
    super.key,
    required this.credential,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            credential.profileName[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          credential.profileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(credential.username),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (credential.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
