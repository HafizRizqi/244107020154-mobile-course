final dioProvider = Provider<Dio>((ref) => createDio());
final postRepositoryProvider = Provider<PostRepository>(
 (ref) => PostRepository(ref.watch(dioProvider)));
class PostListNotifier extends AsyncNotifier<List<Post>> {
 @override
 Future<List<Post>> build() async {
 // Exception dari repository otomatis menjadi AsyncError
 final repository = ref.watch(postRepositoryProvider);
 return repository.fetchPosts();
 }
 Future<void> refresh() async {
 state = const AsyncLoading();
 try {
 final repository = ref.read(postRepositoryProvider);
 state = AsyncData(await repository.fetchPosts());
 } catch (e, st) {
 state = AsyncError(e, st);
 }
 }
}
final postListProvider =
 AsyncNotifierProvider<PostListNotifier, List<Post>>(
 PostListNotifier.new,
 retry: (retryCount, error) => null);