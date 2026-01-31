// =============================================================================
// YemenChat - Contact Controller
// =============================================================================
// State management for contacts, favorites, and blocked users.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Controller for managing contacts state
class ContactController extends ChangeNotifier {
  // Services
  final FirestoreService _firestoreService = FirestoreService();

  // State
  List<UserModel> _contacts = [];
  List<UserModel> _favorites = [];
  Set<String> _blockedIds = {};
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Current user ID
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _blockedSubscription;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// All contacts (filtered by search if applicable)
  List<UserModel> get contacts {
    // Filter out blocked users
    var filtered = _contacts.where((u) => !_blockedIds.contains(u.id)).toList();

    if (_searchQuery.isEmpty) return filtered;

    final query = _searchQuery.toLowerCase();
    return filtered.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  /// Favorite contacts
  List<UserModel> get favorites => _favorites;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Check if a user is in favorites
  bool isFavorite(String userId) => _favoriteIds.contains(userId);

  /// Check if a user is blocked
  bool isBlocked(String userId) => _blockedIds.contains(userId);

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize controller with current user ID
  void initialize(String userId) {
    // Prevent duplicate initialization
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _loadContacts();
    _listenToFavorites();
    _listenToBlocked();
  }

  /// Load all contacts
  Future<void> _loadContacts() async {
    if (_currentUserId == null) return;

    _setLoading(true);

    try {
      _contacts = await _firestoreService.getAllUsers(_currentUserId!);
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load contacts: $e';
      _setLoading(false);
    }
  }

  /// Refresh contacts
  Future<void> refreshContacts() async {
    await _loadContacts();
    await _loadFavorites();
  }

  /// Listen to favorites changes
  void _listenToFavorites() {
    if (_currentUserId == null) return;

    _favoritesSubscription?.cancel();
    _favoritesSubscription = _firestoreService
        .streamFavoriteIds(_currentUserId!)
        .listen((ids) {
          _favoriteIds = ids.toSet();
          _loadFavorites();
          notifyListeners();
        });
  }

  /// Load favorite users
  Future<void> _loadFavorites() async {
    if (_currentUserId == null) return;

    try {
      _favorites = await _firestoreService.getFavoriteUsers(_currentUserId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load favorites: $e';
    }
  }

  /// Listen to blocked users changes
  void _listenToBlocked() {
    if (_currentUserId == null) return;

    _blockedSubscription?.cancel();
    _blockedSubscription = _firestoreService
        .streamBlockedIds(_currentUserId!)
        .listen((ids) {
          _blockedIds = ids.toSet();
          notifyListeners();
        });
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  /// Search contacts
  void searchContacts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ===========================================================================
  // FAVORITES
  // ===========================================================================

  /// Add user to favorites
  Future<bool> addToFavorites(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestoreService.addToFavorites(_currentUserId!, userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add to favorites: $e';
      return false;
    }
  }

  /// Remove user from favorites
  Future<bool> removeFromFavorites(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestoreService.removeFromFavorites(_currentUserId!, userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove from favorites: $e';
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String userId) async {
    if (isFavorite(userId)) {
      return removeFromFavorites(userId);
    } else {
      return addToFavorites(userId);
    }
  }

  // ===========================================================================
  // BLOCKED USERS
  // ===========================================================================

  /// Block a user
  Future<bool> blockUser(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestoreService.blockUser(_currentUserId!, userId);
      // Also remove from favorites if blocked
      if (isFavorite(userId)) {
        await removeFromFavorites(userId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to block user: $e';
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestoreService.unblockUser(_currentUserId!, userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to unblock user: $e';
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<UserModel>> getBlockedUsers() async {
    final users = <UserModel>[];
    for (final id in _blockedIds) {
      final user = await _firestoreService.getUserById(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get a specific user by ID
  Future<UserModel?> getUserById(String userId) async {
    // Check local cache first
    final local = _contacts.where((u) => u.id == userId).firstOrNull;
    if (local != null) return local;

    // Fetch from Firestore
    return _firestoreService.getUserById(userId);
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _blockedSubscription?.cancel();
    super.dispose();
  }
}
