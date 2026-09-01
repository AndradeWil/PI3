import '../entities/therapist_profile.dart';

abstract interface class ProfileRepository {
  Future<TherapistProfile> getProfile();
}
