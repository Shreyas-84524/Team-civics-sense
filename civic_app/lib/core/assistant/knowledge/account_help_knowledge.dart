import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix citizen account, authentication, and privacy.
final List<KnowledgeEntry> accountHelpKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'account_citizen_signin',
    title: 'Citizen Sign-In & Phone OTP Authentication',
    topic: 'account',
    audience: 'citizen',
    tags: [
      'login',
      'sign in',
      'otp',
      'phone number',
      'account create',
      'register',
    ],
    canonicalContent:
        'Citizens sign in to CivicFix securely using their 10-digit mobile number and a 6-digit One-Time Password (OTP) sent via SMS. No complex passwords are required.',
    relatedTopics: [
      'account_privacy_security',
      'citizen_profile',
    ],
    sourceReference: 'Brain.md - Authentication Architecture',
  ),
  const KnowledgeEntry(
    id: 'citizen_profile',
    title: 'Managing Citizen Profile & Notification Settings',
    topic: 'account',
    audience: 'citizen',
    tags: [
      'profile',
      'edit profile',
      'notifications',
      'settings',
      'language preference',
    ],
    canonicalContent:
        'In the Profile tab, citizens can update their display name, preferred app language (English, Marathi, Hindi), view their earned Civic Points and badges, and configure push notifications for grievance updates.',
    relatedTopics: [
      'citizen_rewards_points',
      'account_citizen_signin',
    ],
    sourceReference: 'Brain.md - Citizen Profile Specification',
  ),
  const KnowledgeEntry(
    id: 'account_privacy_security',
    title: 'Citizen Privacy & Data Protection',
    topic: 'account',
    audience: 'all',
    tags: [
      'privacy',
      'is my data safe',
      'phone number privacy',
      'anonymous',
      'data protection',
    ],
    canonicalContent:
        'CivicFix prioritizes citizen privacy. Your personal mobile number and private account details are never displayed on public map markers or community feeds. Only authorized municipal engineers handling your specific ticket have access to official contact records for verification.',
    relatedTopics: [
      'account_citizen_signin',
      'citizen_community_upvoting',
    ],
    sourceReference: 'Brain.md - Security & Privacy Guidelines',
  ),
];
