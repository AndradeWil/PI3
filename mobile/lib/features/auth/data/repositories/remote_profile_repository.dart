import '../../../../core/network/api_client.dart';
import '../../domain/entities/therapist_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class RemoteProfileRepository implements ProfileRepository {
  const RemoteProfileRepository(this.client);

  final ApiClient client;

  @override
  Future<TherapistProfile> getProfile() async {
    final response = await client.dio.get<Map<String, dynamic>>('/me/');
    final data = response.data!;
    return TherapistProfile(
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      crefito: data['crefito'] as String? ?? '',
    );
  }
}
