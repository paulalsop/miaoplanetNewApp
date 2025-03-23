import 'package:flutter/foundation.dart';
import 'package:hiddify/core/database/database_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/config_option/data/config_option_data_providers.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_source.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/environment.dart';

part 'profile_data_providers.g.dart';

@Riverpod(keepAlive: true)
Future<ProfileRepository> profileRepository(ProfileRepositoryRef ref) async {
  try {
    // 尝试获取环境提供者
    final env = ref.read(environmentProvider);
    debugPrint("ProfileRepository: 使用环境 ${env.name}");
    
    final repo = ProfileRepositoryImpl(
      profileDataSource: ref.watch(profileDataSourceProvider),
      profilePathResolver: ref.watch(profilePathResolverProvider),
      singbox: ref.watch(singboxServiceProvider),
      configOptionRepository: ref.watch(configOptionRepositoryProvider),
      httpClient: ref.watch(httpClientProvider),
    );
    await repo.init().getOrElse((l) => throw l).run();
    return repo;
  } catch (e, stackTrace) {
    // 如果环境提供者未初始化，记录错误并重新抛出
    debugPrint("ProfileRepository初始化错误: $e");
    debugPrint("错误堆栈: $stackTrace");
    
    // 重新抛出异常
    rethrow;
  }
}

@Riverpod(keepAlive: true)
ProfileDataSource profileDataSource(ProfileDataSourceRef ref) {
  return ProfileDao(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
ProfilePathResolver profilePathResolver(ProfilePathResolverRef ref) {
  return ProfilePathResolver(
    ref.watch(appDirectoriesProvider).requireValue.workingDir,
  );
}
